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
import '../../domain/repositories/discovery_examined_assets_repository.dart';
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
    required DiscoveryExaminedAssetsRepository examinedAssets,
    required Future<bool> Function() checkConnectivity,
    GalleryDiscoveryUseCases? fileSystemDiscovery,
    DiscoveryWatermarkRepository? fileSystemWatermark,
    DiscoveryExaminedAssetsRepository? fileSystemExaminedAssets,
  }) : _imports = imports,
       _categories = categories,
       _documents = documents,
       _processing = processing,
       _discovery = discovery,
       _watermark = watermark,
       _examinedAssets = examinedAssets,
       _checkConnectivity = checkConnectivity,
       _fileSystemDiscovery = fileSystemDiscovery,
       _fileSystemWatermark = fileSystemWatermark,
       _fileSystemExaminedAssets = fileSystemExaminedAssets {
    _categories.addListener(_notify);
  }

  // Deliberately uncapped: both `discover()` ("Find more documents" in
  // Profile) and `discoverAll()` (the first-launch automatic scan) process
  // every asset [restrictToRecentWindow] admits in a single pass instead of
  // splitting it across repeated, capped "scan again" batches. This is only
  // a defensive ceiling against runaway iteration on a pathologically large
  // library, never a real per-scan budget -- a scan this large can take a
  // while and costs one AI call per readable-text asset found.
  static const unboundedExamineLimit = 1 << 30;

  final BulkImportUseCases _imports;
  final CategoryUseCases _categories;
  final DocumentUseCases _documents;
  final DocumentProcessingUseCases _processing;
  final GalleryDiscoveryUseCases _discovery;
  final DiscoveryWatermarkRepository _watermark;
  final DiscoveryExaminedAssetsRepository _examinedAssets;
  final Future<bool> Function() _checkConnectivity;
  // Android-only filesystem discovery (Downloads/Documents); null on iOS or
  // whenever that source isn't wired up — see bulkImportDependencies().
  final GalleryDiscoveryUseCases? _fileSystemDiscovery;
  final DiscoveryWatermarkRepository? _fileSystemWatermark;
  final DiscoveryExaminedAssetsRepository? _fileSystemExaminedAssets;
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

  /// Opens the OS permission settings screen for the gallery discovery
  /// source, for [permissionDenied]'s "Open Settings" action.
  Future<void> openPermissionSettings() => _discovery.openSettings();

  /// Finds likely-document photos automatically: requires a network
  /// connection, requests gallery permission, enumerates every unexamined
  /// asset [restrictToRecentWindow] admits, and sends each one's extracted
  /// text to the AI service, which decides inclusion and returns
  /// category/tags/title in the same call -- see "Why AI replaced a local
  /// classifier" in the feature doc. Returns false when offline, on
  /// permission denial, or when nothing new was found.

  /// Passive check (never prompts) across every configured source -- true
  /// if at least one is already granted. AutoImportService's unattended
  /// startup-recovery path uses this to decide whether there's anything
  /// worth attempting at all: on a fresh install that hasn't been through
  /// the consent sheet yet, nothing is granted, and this must return false
  /// so that path doesn't spend its one-shot attempt before the user ever
  /// gets a real, permission-prompting chance via [discoverAll].
  Future<bool> hasAnyDiscoveryPermission() async {
    if (await _discovery.hasPermission()) return true;
    final fs = _fileSystemDiscovery;
    return fs != null && await fs.hasPermission();
  }

  Future<bool> discover() async {
    if (!_editable || _isScanning) return false;
    final done = Completer<void>();
    _scanningDone = done.future;
    _isScanning = true;
    notice = null;
    permissionDenied = false;
    offline = false;
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
      final denied = await _scanSource(
        discovery: _discovery,
        watermark: _watermark,
        examinedAssets: _examinedAssets,
        allowPrompt: true,
        restrictToRecentWindow: true,
      );
      if (denied) {
        permissionDenied = true;
        return false;
      }
      notice = scanFound == 0
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

  /// Like [discover], but also scans the filesystem discovery source when
  /// one is configured (Android only -- see `bulkImportDependencies()`).
  /// Used only by AutoImportService's one-time automatic scan; the manual
  /// "Find more documents" entry point keeps calling [discover].
  ///
  /// Returns false only if every configured source denied permission --
  /// one source being unavailable/denied while another succeeds is not
  /// treated as failure, unlike [discover] (which has exactly one source).
  ///
  /// [allowPermissionPrompts] false (AutoImportService's unattended
  /// startup-recovery path) means each source is only scanned if its
  /// permission is *already* granted -- a source that would otherwise show
  /// a system permission dialog or (for `MANAGE_EXTERNAL_STORAGE`) silently
  /// launch the device Settings app is simply skipped instead, since the
  /// user hasn't taken any action this session to expect that. true (every
  /// other caller, always reached via an explicit user action) behaves
  /// exactly like [discover] always has.
  Future<bool> discoverAll({
    bool allowPermissionPrompts = true,
    // true (the one-time automatic scan): a source with no watermark yet
    // falls back to the discovery datasource's own ~12-month window (see
    // GalleryDiscoveryDataSource.defaultScanWindow). false (the manual
    // "Find more documents" entry point): that fallback is bypassed so a
    // never-scanned source covers the user's entire history instead.
    bool restrictToRecentWindow = true,
  }) async {
    if (!_editable || _isScanning) return false;
    final done = Completer<void>();
    _scanningDone = done.future;
    _isScanning = true;
    notice = null;
    permissionDenied = false;
    offline = false;
    scanExamined = 0;
    scanFound = 0;
    _notify();
    try {
      if (!await _checkConnectivity()) {
        offline = true;
        notice = 'Connect to the internet to find your documents automatically.';
        return false;
      }
      if (_closed || _disposed) return false;
      var anyGranted = false;
      final galleryDenied = await _scanSource(
        discovery: _discovery,
        watermark: _watermark,
        examinedAssets: _examinedAssets,
        allowPrompt: allowPermissionPrompts,
        restrictToRecentWindow: restrictToRecentWindow,
      );
      if (!galleryDenied) anyGranted = true;
      final fsDiscovery = _fileSystemDiscovery;
      final fsWatermark = _fileSystemWatermark;
      final fsExaminedAssets = _fileSystemExaminedAssets;
      if (fsDiscovery != null &&
          fsWatermark != null &&
          fsExaminedAssets != null &&
          !(_closed || _disposed)) {
        final fsDenied = await _scanSource(
          discovery: fsDiscovery,
          watermark: fsWatermark,
          examinedAssets: fsExaminedAssets,
          allowPrompt: allowPermissionPrompts,
          restrictToRecentWindow: restrictToRecentWindow,
        );
        if (!fsDenied) anyGranted = true;
      }
      permissionDenied = !anyGranted;
      if (permissionDenied) return false;
      notice = scanFound == 0 ? 'No new documents found.' : null;
      _event('discovered', scanFound);
      return scanFound > 0;
    } catch (_) {
      notice = 'Could not scan for documents. Check access and try again.';
      _event('discovery_failed', 1);
      return false;
    } finally {
      _isScanning = false;
      done.complete();
      _notify();
    }
  }

  /// Scans one discovery source (stage -> OCR -> AI analyze -> candidate) --
  /// extracted from the single-source loop [discover] used to be, so
  /// [discoverAll] can run it once per configured source while sharing the
  /// same [_candidates]/[scanFound]/[scanExamined] accumulation. Deliberately
  /// uncapped: every unexamined asset [restrictToRecentWindow] admits is
  /// processed in this one pass, not split across repeated "scan again"
  /// batches. Returns true if this source's permission was denied (nothing
  /// was scanned); callers decide what that means for the overall result.
  Future<bool> _scanSource({
    required GalleryDiscoveryUseCases discovery,
    required DiscoveryWatermarkRepository watermark,
    required DiscoveryExaminedAssetsRepository examinedAssets,
    required bool allowPrompt,
    required bool restrictToRecentWindow,
  }) async {
    if (_closed || _disposed) return false;
    // allowPrompt=false (unattended startup-recovery path) never calls
    // requestPermission() -- for MANAGE_EXTERNAL_STORAGE in particular,
    // that would silently launch the device Settings app with no user
    // action this session to justify it. A passive check stands in instead.
    // `limited` (iOS partial photo access) counts as granted, same as a
    // lone [discover] call always has.
    final granted = allowPrompt
        ? (await discovery.requestPermission()) != DiscoveryPermission.denied
        : await discovery.hasPermission();
    if (_closed || _disposed) return false;
    if (!granted) return true;
    // A never-scanned source (no stored watermark) otherwise falls back to
    // the discovery datasource's own ~12-month default window. That default
    // is right for the one-time automatic scan (restrictToRecentWindow:
    // true) -- but "Find more documents" is an explicit, repeatable user
    // request that should be able to reach the user's entire history, so it
    // overrides the missing watermark with the epoch instead of leaving it
    // null for the datasource to narrow down itself.
    final stored = await watermark.read();
    final since = stored ??
        (restrictToRecentWindow ? null : DateTime.fromMillisecondsSinceEpoch(0));
    final found = await discovery.findCandidates(
      since: since,
      maxExamined: unboundedExamineLimit,
    );
    if (_closed || _disposed) return false;
    // The date window above is only a cost bound on how far back to even
    // look -- it is never the actual "have I seen this one" decision,
    // because no single date field on an asset is reliably trustworthy for
    // that (see GalleryDiscoveryDataSource.findCandidates's own doc
    // comment on copied-in files carrying an old, misleading date). This
    // exact, per-id check against discovery_examined_assets is the real
    // dedup: a copied-in old photo whose date happens to still look old is
    // still included here as long as it fell within the window above, and
    // still correctly treated as new since its id was never recorded.
    final unexaminedIds = (await examinedAssets.filterUnexamined([
      for (final asset in found) asset.id,
    ])).toSet();
    if (_closed || _disposed) return false;
    final toExamine = [
      for (final asset in found)
        if (unexaminedIds.contains(asset.id)) asset,
    ];
    final availableCategories = [for (final c in categories) c.name];
    DateTime? processedThrough;
    for (final asset in toExamine) {
      scanExamined++;
      // The watermark must advance to the *newest* examined timestamp, not
      // simply the last one iterated -- [found] is newest-first, so an
      // unconditional overwrite here would leave it pointing at the oldest
      // item instead, and the next scan's `since` filter would then
      // re-admit almost this entire batch again instead of only genuinely
      // new assets.
      if (processedThrough == null || asset.takenAt.isAfter(processedThrough)) {
        processedThrough = asset.takenAt;
      }
      // Recorded immediately, before resolving/staging/OCR/AI run -- so a
      // scan that gets cancelled or cut off partway through never leaves
      // an asset it already decided to look at in limbo, re-examined (and
      // re-billed to the AI) on the very next scan.
      await examinedAssets.markExamined([asset.id]);
      _notify();
      final path = await asset.resolvePath();
      if (_closed || _disposed) return false;
      if (path == null) continue;
      final staged = await _imports.stage([
        (path: path, name: p.basename(path)),
      ], limit: 1);
      if (_closed || _disposed) return false;
      if (staged.candidates.isEmpty) continue;
      final candidate = staged.candidates.first;
      final text = await _extractTextForScoring(candidate.attachment.path);
      if (_closed || _disposed) {
        await _bestEffort(() => _imports.removeStaged(candidate));
        return false;
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
        return false;
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
    if (processedThrough != null) await watermark.write(processedThrough);
    return false;
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
