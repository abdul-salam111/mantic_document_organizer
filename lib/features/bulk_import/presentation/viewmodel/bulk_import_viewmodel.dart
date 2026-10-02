import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../../../categories/domain/entities/category_item.dart';
import '../../../categories/domain/usecases/category_usecases.dart';
import '../../../documents/domain/entities/document_item.dart';
import '../../../documents/domain/entities/document_suggestion.dart';
import '../../../documents/domain/usecases/document_usecases.dart';
import '../../../documents/domain/usecases/document_processing_usecases.dart';
import '../../domain/entities/bulk_import_candidate.dart';
import '../../domain/repositories/discovery_watermark_repository.dart';
import '../../domain/repositories/gallery_discovery_repository.dart';
import '../../domain/usecases/bulk_import_usecases.dart';
import '../../domain/usecases/gallery_discovery_usecases.dart';

class BulkImportResult {
  final int imported;
  final Map<String, String> failures;
  const BulkImportResult(this.imported, this.failures);
}

class BulkImportViewModel extends ChangeNotifier {
  BulkImportViewModel({
    required BulkImportUseCases imports,
    required CategoryUseCases categories,
    required DocumentUseCases documents,
    required DocumentProcessingUseCases processing,
    required GalleryDiscoveryUseCases discovery,
    required DiscoveryWatermarkRepository watermark,
    required Future<bool> Function() checkConnectivity,
  }) : _imports = imports,
       _categories = categories,
       _documents = documents,
       _processing = processing,
       _discovery = discovery,
       _watermark = watermark,
       _checkConnectivity = checkConnectivity {
    _categories.addListener(_notify);
  }

  static const maxCandidates = 25;
  // Bounds how many assets a single scan examines (metadata + the OCR +
  // AI-analysis pass below), so one tap has a predictable cost. Each
  // examined asset with any readable text now costs a real network call
  // (see discover()), unlike the free local check this replaced -- this
  // budget hasn't been re-tuned for that yet.
  static const maxExaminedPerScan = 150;

  final BulkImportUseCases _imports;
  final CategoryUseCases _categories;
  final DocumentUseCases _documents;
  final DocumentProcessingUseCases _processing;
  final GalleryDiscoveryUseCases _discovery;
  final DiscoveryWatermarkRepository _watermark;
  final Future<bool> Function() _checkConnectivity;
  final List<BulkImportCandidate> _candidates = [];
  final Map<String, int> _revisions = {};
  Future<void> _queue = Future.value();
  Future<void>? _scanningDone;
  Future<void>? _commitDone;
  Future<void>? _cleanup;
  String? _activeId;
  bool _disposed = false;
  bool _closed = false;
  bool _isScanning = false;
  bool _isImporting = false;
  bool permissionDenied = false;
  bool offline = false;
  bool scanHasMore = false;
  String? notice;
  int scanExamined = 0;
  int scanFound = 0;
  int importCompleted = 0;
  int importTotal = 0;

  List<BulkImportCandidate> get candidates => List.unmodifiable(_candidates);
  List<CategoryItem> get categories =>
      List.unmodifiable(_categories.categories);
  bool get isScanning => _isScanning;
  bool get isImporting => _isImporting;
  bool get _editable => !_closed && !_disposed && !_isImporting;
  int get selectedCount => _candidates.where((c) => c.isSelected).length;
  int get processingTotal => _candidates.where((c) => c.isSelected).length;
  int get processedCount => _candidates
      .where(
        (c) =>
            c.isSelected &&
            (c.state == CandidateProcessingState.ready ||
                c.state == CandidateProcessingState.failed),
      )
      .length;
  bool get isProcessing => _candidates.any(
    (c) =>
        c.isSelected &&
        (c.state == CandidateProcessingState.queued ||
            c.state == CandidateProcessingState.processing),
  );
  bool get canImport =>
      _editable &&
      !_isScanning &&
      selectedCount > 0 &&
      _candidates
          .where((c) => c.isSelected)
          .every((c) => c.title.trim().isNotEmpty);

  void _notify() {
    if (!_disposed && !_closed) notifyListeners();
  }

  // Counts only: never log document content, paths, titles, or OCR errors.
  void _event(String event, int count) =>
      developer.log('$event count=$count', name: 'bulk_import');

  /// Finds likely-document photos automatically: requires a network
  /// connection, requests gallery permission, enumerates recent assets, and
  /// sends each one's extracted text to the AI service, which decides
  /// inclusion and returns category/tags/title in the same call -- see
  /// "Why AI replaced a local classifier" in the feature doc. Returns false
  /// when offline, on permission denial, or when nothing new was found.
  /// Items beyond available room are left unprocessed (not watermarked) so
  /// a later scan finds them again, reported via [scanHasMore].
  Future<void> openPermissionSettings() => _discovery.openSettings();

  Future<bool> discover() async {
    if (!_editable || _isScanning) return false;
    final done = Completer<void>();
    _scanningDone = done.future;
    _isScanning = true;
    notice = null;
    permissionDenied = false;
    offline = false;
    scanHasMore = false;
    scanExamined = 0;
    scanFound = 0;
    _notify();
    try {
      // No point prompting for photo-library permission just to fail
      // immediately after -- this feature cannot work at all offline, since
      // the AI call is now the inclusion decision, not an optional extra.
      if (!await _checkConnectivity()) {
        offline = true;
        notice = 'Connect to the internet to find your documents automatically.';
        return false;
      }
      if (_closed || _disposed) return false;
      final permission = await _discovery.requestPermission();
      if (_closed || _disposed) return false;
      if (permission == DiscoveryPermission.denied) {
        permissionDenied = true;
        return false;
      }
      final room = maxCandidates - _candidates.length;
      if (room <= 0) {
        notice = 'You can import up to $maxCandidates files at a time.';
        return false;
      }
      final since = await _watermark.read();
      final found = await _discovery.findCandidates(
        since: since,
        maxExamined: maxExaminedPerScan,
      );
      if (_closed || _disposed) return false;
      final availableCategories = [for (final c in categories) c.name];
      DateTime? processedThrough;
      for (final asset in found) {
        if (scanFound >= room) {
          scanHasMore = true;
          break;
        }
        scanExamined++;
        processedThrough = asset.takenAt;
        _notify();
        final path = await asset.resolvePath();
        if (_closed || _disposed) return scanFound > 0;
        if (path == null) continue;
        final staged = await _imports.stage([
          (path: path, name: p.basename(path)),
        ], limit: room);
        if (_closed || _disposed) return scanFound > 0;
        if (staged.candidates.isEmpty) continue;
        final candidate = staged.candidates.first;
        final text = await _extractTextForScoring(candidate.attachment.path);
        if (_closed || _disposed) {
          await _bestEffort(() => _imports.removeStaged(candidate));
          return scanFound > 0;
        }
        if (text == null || text.trim().isEmpty) {
          // No readable text at all -- free, local, definitely not a
          // document; skip the network call entirely.
          await _bestEffort(() => _imports.removeStaged(candidate));
          continue;
        }
        AiDocumentSuggestion? suggestion;
        try {
          suggestion = await _processing.analyze(
            ocrText: text,
            availableCategories: availableCategories,
          );
        } catch (_) {
          suggestion = null;
        }
        if (_closed || _disposed) {
          await _bestEffort(() => _imports.removeStaged(candidate));
          return scanFound > 0;
        }
        if (suggestion != null && !suggestion.isDocument) {
          await _bestEffort(() => _imports.removeStaged(candidate));
          continue;
        }
        scanFound++;
        final withText = candidate.copyWith(ocrText: text);
        if (suggestion == null) {
          // A transient AI/network failure must never silently drop a real
          // document -- include it, retryable, rather than lose it.
          _candidates.add(
            withText.copyWith(
              state: CandidateProcessingState.failed,
              error: 'Could not analyze this file. Retry, or import it as-is.',
            ),
          );
        } else {
          _candidates.add(_applySuggestion(withText, suggestion));
        }
        _notify();
      }
      if (processedThrough != null) await _watermark.write(processedThrough);
      notice = scanFound > 0 && scanHasMore
          ? 'Found $scanFound documents. More were found than fit at once; scan again to find the rest.'
          : scanFound == 0
          ? 'No new documents found in your photo library.'
          : null;
      _event('discovered', scanFound);
      return scanFound > 0;
    } catch (_) {
      notice =
          'Could not scan your photo library. Check access and try again.';
      _event('discovery_failed', 1);
      return false;
    } finally {
      _isScanning = false;
      done.complete();
      _notify();
    }
  }

  Future<String?> _extractTextForScoring(String path) async {
    if (!isImagePath(path) && !isPdfPath(path)) return null;
    try {
      return await _processing.extractText(path);
    } catch (_) {
      return null;
    }
  }

  /// Applies an AI suggestion's title/category/tags/description/expiry onto
  /// a candidate, respecting any field the user has already edited by hand.
  /// Shared by [discover]'s inline first pass and [_process]'s retry path,
  /// so both apply a successful suggestion identically.
  BulkImportCandidate _applySuggestion(
    BulkImportCandidate latest,
    AiDocumentSuggestion suggestion,
  ) {
    final category = categories
        .where(
          (c) =>
              c.name.trim().toLowerCase() ==
              suggestion.categoryName?.trim().toLowerCase(),
        )
        .firstOrNull;
    return latest.copyWith(
      title:
          !latest.hasUserEditedTitle &&
              suggestion.title?.trim().isNotEmpty == true
          ? suggestion.title!.trim()
          : latest.title,
      categoryId: latest.hasUserEditedCategory
          ? latest.categoryId
          : category?.id ?? uncategorizedCategoryId,
      tags: latest.hasUserEditedTags
          ? latest.tags
          : _validTags(suggestion.tags, 3),
      description: latest.hasUserEditedDescription
          ? latest.description
          : suggestion.description,
      expiryDate: latest.hasUserEditedExpiry
          ? latest.expiryDate
          : suggestion.isExpirable
          ? suggestion.expiryDate
          : null,
      clearExpiry:
          !latest.hasUserEditedExpiry &&
          (!suggestion.isExpirable || suggestion.expiryDate == null),
      state: CandidateProcessingState.ready,
      clearError: true,
    );
  }

  BulkImportCandidate? _find(String id) =>
      _candidates.where((c) => c.id == id).firstOrNull;

  void _replace(
    String id,
    BulkImportCandidate Function(BulkImportCandidate) transform,
  ) {
    if (!_editable) return;
    final index = _candidates.indexWhere((c) => c.id == id);
    if (index < 0) return;
    _candidates[index] = transform(_candidates[index]);
    _notify();
  }

  void updateTitle(String id, String value) => _replace(
    id,
    (c) => c.copyWith(
      title: value,
      hasUserEditedTitle: true,
      clearImportError: true,
    ),
  );
  void updateCategory(String id, String value) => _replace(
    id,
    (c) => c.copyWith(categoryId: value, hasUserEditedCategory: true),
  );
  void updateDescription(String id, String value) => _replace(
    id,
    (c) => c.copyWith(description: value, hasUserEditedDescription: true),
  );
  void updateExpiry(String id, DateTime? value) => _replace(
    id,
    (c) => c.copyWith(
      expiryDate: value,
      clearExpiry: value == null,
      hasUserEditedExpiry: true,
    ),
  );
  void updateTags(String id, String value) => _replace(
    id,
    (c) => c.copyWith(
      tags: _validTags(value.split(','), 10),
      hasUserEditedTags: true,
    ),
  );

  void applyCategoryToSelected(String categoryId) {
    if (!_editable) return;
    for (final c in candidates.where((c) => c.isSelected)) {
      updateCategory(c.id, categoryId);
    }
  }

  void toggle(String id) {
    final current = _find(id);
    if (!_editable || current == null) return;
    final selected = !current.isSelected;
    _revisions[id] = (_revisions[id] ?? 0) + 1;
    final interrupted =
        current.state == CandidateProcessingState.processing ||
        current.state == CandidateProcessingState.queued;
    _replace(
      id,
      (c) => c.copyWith(
        isSelected: selected,
        state: interrupted ? CandidateProcessingState.queued : c.state,
      ),
    );
    if (selected && interrupted) _enqueue(id);
  }

  void selectAll(bool selected) {
    for (final c in candidates) {
      if (c.isSelected != selected) toggle(c.id);
    }
  }

  Future<void> remove(String id) async {
    if (!_editable) return;
    final current = _find(id);
    if (current == null) return;
    _revisions[id] = (_revisions[id] ?? 0) + 1;
    _candidates.removeWhere((c) => c.id == id);
    _notify();
    // Native OCR cannot be interrupted. Keep its input until it releases it.
    if (_activeId == id) await _queue;
    await _bestEffort(() => _imports.removeStaged(current));
  }

  void retry(String id) {
    final current = _find(id);
    if (!_editable ||
        current == null ||
        !current.isSelected ||
        current.state != CandidateProcessingState.failed) {
      return;
    }
    _replace(
      id,
      (c) =>
          c.copyWith(state: CandidateProcessingState.queued, clearError: true),
    );
    _enqueue(id);
  }

  void _enqueue(String id) {
    final revision = (_revisions[id] ?? 0) + 1;
    _revisions[id] = revision;
    _queue = _queue.then((_) => _process(id, revision));
  }

  bool _accepts(String id, int revision) =>
      _editable && _revisions[id] == revision && _find(id)?.isSelected == true;

  Future<void> _process(String id, int revision) async {
    if (!_accepts(id, revision)) return;
    _activeId = id;
    _replace(
      id,
      (c) => c.copyWith(
        state: CandidateProcessingState.processing,
        clearError: true,
      ),
    );
    try {
      final current = _find(id)!;
      if (!isImagePath(current.attachment.path) &&
          !isPdfPath(current.attachment.path)) {
        _replace(id, (c) => c.copyWith(state: CandidateProcessingState.ready));
        return;
      }
      // Discovery already ran OCR once before the AI call; reuse it instead
      // of extracting the same file's text a second time. This only
      // re-extracts if somehow empty, which discover() already guards
      // against before a candidate ever reaches this state.
      final text = current.ocrText.isNotEmpty
          ? current.ocrText
          : await _processing.extractText(current.attachment.path);
      if (!_accepts(id, revision)) return;
      _replace(id, (c) => c.copyWith(ocrText: text));
      if (text.trim().isEmpty) throw StateError('No readable text');
      final suggestion = await _processing.analyze(
        ocrText: text,
        availableCategories: [for (final c in categories) c.name],
      );
      if (!_accepts(id, revision)) return;
      if (suggestion == null || !suggestion.isDocument) {
        throw StateError('Analysis unavailable');
      }
      _replace(id, (latest) => _applySuggestion(latest, suggestion));
    } catch (_) {
      if (_accepts(id, revision)) {
        _replace(
          id,
          (c) => c.copyWith(
            state: CandidateProcessingState.failed,
            error: 'Could not analyze this file. You can still import it.',
          ),
        );
        _event('suggestions_failed', 1);
      }
    } finally {
      _activeId = null;
      _notify();
    }
  }

  List<String> _validTags(List<String> raw, int limit) => raw
      .map((tag) => tag.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-'))
      .where(
        (tag) => tag.length <= 20 && RegExp(r'^[a-z0-9_-]+$').hasMatch(tag),
      )
      .toSet()
      .take(limit)
      .toList();

  Future<BulkImportResult> commit() async {
    if (!canImport) return const BulkImportResult(0, {});
    final done = Completer<void>();
    _commitDone = done.future;
    _isImporting = true;
    // Freeze exactly what the user reviewed; late suggestions cannot alter it.
    final selected = candidates.where((c) => c.isSelected).toList();
    for (final c in candidates) {
      _revisions[c.id] = (_revisions[c.id] ?? 0) + 1;
    }
    importCompleted = 0;
    importTotal = selected.length;
    _notify();
    var imported = 0;
    final failures = <String, String>{};
    try {
      for (final candidate in selected) {
        String? path;
        final id = 'bulk_${candidate.id}';
        try {
          path = await _imports.promote(candidate);
          final category = categories
              .where((c) => c.id == candidate.categoryId)
              .firstOrNull;
          await _documents.addDocument(
            DocumentItem(
              id: id,
              title: candidate.title.trim(),
              category: category?.name ?? 'Uncategorized',
              categoryId: category?.id ?? uncategorizedCategoryId,
              iconKey: category?.iconKey ?? 'solidFolder',
              filePaths: [path],
              tags: candidate.tags,
              ocrText: candidate.ocrText,
              description: candidate.description.trim(),
              isExpirable: candidate.expiryDate != null,
              expiryDate: candidate.expiryDate,
              createdAt: DateTime.now(),
            ),
          );
          imported++;
          _candidates.removeWhere((c) => c.id == candidate.id);
          unawaited(_removeAfterProcessing(candidate));
        } catch (_) {
          // A repository may persist before a downstream listener fails.
          // Never delete a file already referenced by a saved document.
          if (_documents.documents.any((d) => d.id == id)) {
            imported++;
            _candidates.removeWhere((c) => c.id == candidate.id);
            unawaited(_removeAfterProcessing(candidate));
          } else {
            if (path != null) {
              await _bestEffort(() => _imports.removePromoted(path!));
            }
            const message =
                'Could not save this document. Its file is kept for retry.';
            failures[candidate.id] = message;
            final index = _candidates.indexWhere((c) => c.id == candidate.id);
            if (index >= 0) {
              _candidates[index] = _candidates[index].copyWith(
                importError: message,
              );
            }
          }
        }
        importCompleted++;
        _notify();
      }
      _event('imported', imported);
      _event('import_failed', failures.length);
      return BulkImportResult(imported, Map.unmodifiable(failures));
    } finally {
      // Interrupted suggestions are explicitly retryable, never left spinning.
      for (var i = 0; i < _candidates.length; i++) {
        final c = _candidates[i];
        if (c.state == CandidateProcessingState.processing ||
            c.state == CandidateProcessingState.queued) {
          _candidates[i] = c.copyWith(
            state: CandidateProcessingState.failed,
            error: 'Suggestions stopped for import. Retry to continue.',
          );
        }
      }
      _isImporting = false;
      done.complete();
      _notify();
    }
  }

  Future<void> _removeAfterProcessing(BulkImportCandidate c) async {
    if (_activeId == c.id) await _queue;
    await _bestEffort(() => _imports.removeStaged(c));
  }

  Future<void> _bestEffort(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      _event('cleanup_deferred', 1);
    }
  }

  Future<void> cancel() {
    if (_cleanup != null) return _cleanup!;
    _closed = true;
    _event('session_closed', _candidates.length);
    _cleanup = _finishCleanup();
    return _cleanup!;
  }

  Future<void> _finishCleanup() async {
    await _scanningDone;
    await _commitDone;
    await _queue;
    await _bestEffort(_imports.discard);
    _candidates.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    _categories.removeListener(_notify);
    unawaited(cancel());
    super.dispose();
  }
}
