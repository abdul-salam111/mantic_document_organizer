import 'dart:convert';
import '../../../domain/entities/document_draft.dart';
import '../../../domain/usecases/draft_usecases.dart';
import '../../../domain/entities/attachment_item.dart';
import '../../../domain/entities/document_suggestion.dart';
import '../../../domain/usecases/document_processing_usecases.dart';
export '../../../domain/entities/attachment_item.dart';
import 'package:mantic_doc_org/features/categories/domain/entities/category_item.dart';
import 'package:mantic_doc_org/features/categories/domain/usecases/category_usecases.dart';
import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_usecases.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/background/document_sync_background_service.dart';
import '../../../../../core/utils/document_page_rasterizer.dart';
import '../../../../../core/utils/shared_space_sync.dart';

enum TagError { limitReached, tooLong, duplicate }

/// How the user resolved a detected duplicate attachment -- see
/// [AddDocumentViewModel.resolveDuplicate].
enum DuplicateResolution { openExisting, skip, keepBoth }

/// Where a freshly-added page's file should come from, chosen up front
/// (the navbar's "+" button prompts for this before even opening the
/// form) so [AddDocumentView] can trigger the matching picker
/// automatically instead of requiring an extra in-page tap.
enum AttachmentSource { camera, gallery, file }

class AddDocumentViewModel extends ChangeNotifier {
  final DraftUseCases? _drafts;
  final CategoryUseCases _categoryUseCases;
  final DocumentUseCases _documentUseCases;
  final DocumentProcessingUseCases _processing;
  final DocumentSyncBackgroundService _syncBackgroundService;

  /// No default category selection — opening this screen with no category
  /// already in context (the navbar's "+" button) starts on Uncategorized,
  /// matching [submit]'s existing `category == null` fallback. Opening it
  /// from a category's own "+" button still preselects that category via
  /// [preselectCategory], called separately by the view.
  AddDocumentViewModel({
    DraftUseCases? drafts,
    required CategoryUseCases categoryUseCases,
    required DocumentUseCases documentUseCases,
    required DocumentProcessingUseCases processing,
    required DocumentSyncBackgroundService syncBackgroundService,
  }) : _drafts = drafts,
       _categoryUseCases = categoryUseCases,
       _documentUseCases = documentUseCases,
       _processing = processing,
       _syncBackgroundService = syncBackgroundService {
    titleController.addListener(_draftChanged);
    descriptionController.addListener(_draftChanged);
    tagController.addListener(_draftChanged);
  }

  String _captureId = generateLocalId();
  DateTime _captureCreatedAt = DateTime.now();
  final Set<String> _ownedPaths = {};
  bool _restoringDraft = false;
  bool _completed = false;
  bool _draftPaused = false;
  bool _draftFailed = false;
  int _draftWrites = 0;
  String? _lastDraftSignature;
  Future<void> _draftQueue = Future.value();
  List<String> _missingPaths = [];
  bool get hasMissingDraftFiles => _missingPaths.isNotEmpty;
  bool get draftFailed => _draftFailed;
  bool get isSavingDraft => _draftWrites > 0;
  bool get hasDraft => _lastDraftSignature != null && !_completed;
  bool get draftsEnabled => _drafts != null && !isEditing;
  bool get canLeave =>
      !isSaving &&
      !isSavingDraft &&
      !draftFailed &&
      !_restoringDraft &&
      duplicateMatch == null;

  DocumentDraft _snapshot() => DocumentDraft(
    document: DocumentItem(
      id: _captureId,
      title: titleController.text,
      category: _selectedCategory?.name ?? 'Uncategorized',
      categoryId: _selectedCategory?.id ?? uncategorizedCategoryId,
      iconKey: _selectedCategory?.iconKey ?? 'solidFolder',
      createdAt: _captureCreatedAt,
      tags: _tags,
      filePaths: [for (final a in _attachments) a.path],
      isExpirable: _isExpirable,
      expiryDate: _expiryDate,
      description: descriptionController.text,
      ocrText: ocrText,
    ),
    updatedAt: DateTime.now(),
    pendingTag: tagController.text,
    ocrByPath: _ocrTextByPath,
    ownedPaths: _ownedPaths.toList(),
  );

  void _draftChanged() {
    if (_disposed ||
        !draftsEnabled ||
        _restoringDraft ||
        _completed ||
        _draftPaused) {
      return;
    }
    // Category preselection alone must not create an empty draft.
    if (!hasDraft &&
        _attachments.isEmpty &&
        titleController.text.trim().isEmpty &&
        descriptionController.text.trim().isEmpty &&
        tagController.text.trim().isEmpty &&
        _tags.isEmpty) {
      return;
    }
    final draft = _snapshot();
    final signature = jsonEncode([
      draft.document.title,
      draft.document.categoryId,
      draft.document.tags,
      draft.document.filePaths,
      draft.document.isExpirable,
      draft.document.expiryDate?.toIso8601String(),
      draft.document.description,
      draft.pendingTag,
      draft.ocrByPath,
      draft.ownedPaths,
    ]);
    if (signature == _lastDraftSignature && !_draftFailed) return;
    _lastDraftSignature = signature;
    _draftWrites++;
    _draftQueue = _draftQueue.then((_) async {
      try {
        await _drafts!.save(draft);
        _draftFailed = false;
      } catch (_) {
        // Keep the form and expose a retry action instead of a toast per keypress.
        _draftFailed = true;
      } finally {
        _draftWrites--;
        if (!_disposed) super.notifyListeners();
      }
    });
    super.notifyListeners();
  }

  Future<void> flushDraft() async {
    _draftChanged();
    await _draftQueue;
    if (_draftFailed) throw StateError('Draft could not be saved');
  }

  Future<void> resumeDraft(DocumentDraft draft) async {
    _restoringDraft = true;
    _isLoadingAttachments = true;
    _captureId = draft.id;
    _captureCreatedAt = draft.document.createdAt;
    final document = draft.document;
    titleController.text = document.title;
    descriptionController.text = document.description;
    tagController.text = draft.pendingTag;
    final category = _categoryUseCases.byId(document.categoryId);
    _selectedCategory = category?.isViewerOnly == false ? category : null;
    _tags.addAll(document.tags);
    _isExpirable = document.isExpirable;
    _expiryDate = document.expiryDate;
    _ocrTextByPath.addAll(draft.ocrByPath);
    _ownedPaths.addAll(draft.ownedPaths);
    _attachments.addAll([
      for (final path in document.filePaths)
        AttachmentItem(path: path, type: isImagePath(path) ? .image : .file),
    ]);
    notifyListeners();
    try {
      _missingPaths = await _drafts!.missingFiles(draft);
    } finally {
      _restoringDraft = false;
      _isLoadingAttachments = false;
      notifyListeners();
    }
  }

  /// Called from the view when opened with a category already in
  /// context (e.g. the "+" button on a category's document list) — picks
  /// it by id from the live store rather than trusting the passed-in
  /// [CategoryItem] as-is, since it may be stale (edited/deleted since).
  /// No-op if the id no longer matches anything, leaving the
  /// constructor's default selection in place.
  void preselectCategory(CategoryItem category) {
    final matches = _categoryUseCases.categories.where(
      (c) => c.id == category.id,
    );
    if (matches.isEmpty) return;
    _selectedCategory = matches.first;
    notifyListeners();
  }

  /// The document being edited, if this screen was opened via the document
  /// viewer's Edit button instead of the "+" button — [submit] updates it
  /// in place (preserving its id/createdAt/favorite status) instead of
  /// creating a new one.
  DocumentItem? _editingDocument;
  bool get isEditing => _editingDocument != null;

  bool _isLoadingAttachments = false;
  bool get isLoadingAttachments => _isLoadingAttachments;

  /// Prefills every field from an existing document. Called once by the
  /// view right after creation, mirroring [preselectCategory].
  ///
  /// When the document has exactly one PDF attachment, it's split back
  /// into one image attachment per internal page (via
  /// [DocumentPageRasterizer]) rather than kept as that single file --
  /// otherwise it would show as one opaque "page" here with no way to
  /// reorder/delete its individual pages. On save, each split-out page is
  /// persisted as its own separate image attachment (see
  /// [_persistTempAttachments]) rather than re-merged into a PDF -- new
  /// documents never merge scanned photos into a PDF at all (each photo
  /// stays its own stored file); this only matters for editing a legacy
  /// merged PDF, or a real multi-page PDF the user attached via Files. A
  /// document with *more than one* PDF attachment is left untouched --
  /// there'd be no way to tell, once split, which resulting image
  /// attachment came from which original PDF, should the edit need to put
  /// them back.
  Future<void> startEditing(DocumentItem document) async {
    _editingDocument = document;
    titleController.text = document.title;
    _selectedCategory = _categoryUseCases.byId(document.categoryId);
    _tags
      ..clear()
      ..addAll(document.tags);
    _isExpirable = document.isExpirable;
    _expiryDate = document.expiryDate;
    descriptionController.text = document.description;
    _baseOcrText = document.ocrText;

    _isLoadingAttachments = true;
    notifyListeners();

    final splitPdfPages = document.filePaths.where(isPdfPath).length == 1;
    final attachments = <AttachmentItem>[];
    for (final path in document.filePaths) {
      if (isPdfPath(path) && splitPdfPages) {
        final pages = await DocumentPageRasterizer.toImagePaths([path]);
        attachments.addAll([
          for (final page in pages)
            AttachmentItem(path: page, type: AttachmentType.image),
        ]);
      } else {
        attachments.add(
          AttachmentItem(
            path: path,
            type: isImagePath(path)
                ? AttachmentType.image
                : AttachmentType.file,
          ),
        );
      }
    }
    if (_disposed) return;

    _attachments
      ..clear()
      ..addAll(attachments);
    _isLoadingAttachments = false;
    notifyListeners();
  }

  final TextEditingController titleController = TextEditingController();
  final TextEditingController tagController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  /// Excludes a Viewer-role shared category entirely -- it's shown
  /// elsewhere (Home, Manage Categories), just never offered as somewhere
  /// to save a new document.
  List<CategoryItem> get categories =>
      List<CategoryItem>.of(_categoryUseCases.categories)
        ..removeWhere((category) => category.isViewerOnly)
        ..sort((a, b) => a.name.compareTo(b.name));

  CategoryItem? _selectedCategory;
  CategoryItem? get selectedCategory => _selectedCategory;

  void selectCategory(CategoryItem category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  static const maxTagCount = 10;
  static const maxTagLength = 20;

  final List<String> _tags = [];
  List<String> get tags => List.unmodifiable(_tags);

  TagError? _tagError;
  TagError? get tagError => _tagError;

  void clearTagError() {
    if (_tagError == null) return;
    _tagError = null;
    notifyListeners();
  }

  /// Tags are entered freely — whatever the user types is kept as-is (no
  /// forced casing/character set), just trimmed, capped at [maxTagLength]
  /// chars and [maxTagCount] tags per document, and deduplicated
  /// case-insensitively so "Insurance" and "insurance" don't both end up
  /// in the list.
  void addTag() {
    final tag = tagController.text.trim();
    if (tag.isEmpty) return;
    if (_tags.length >= maxTagCount) {
      _tagError = TagError.limitReached;
    } else if (tag.length > maxTagLength) {
      _tagError = TagError.tooLong;
    } else if (_tags.any((t) => t.toLowerCase() == tag.toLowerCase())) {
      _tagError = TagError.duplicate;
    } else {
      _tags.add(tag);
      tagController.clear();
      _tagError = null;
    }
    notifyListeners();
  }

  void removeTag(String tag) {
    _tags.remove(tag);
    notifyListeners();
  }

  bool _isExpirable = false;
  bool get isExpirable => _isExpirable;

  DateTime? _expiryDate;
  DateTime? get expiryDate => _expiryDate;

  /// Turning expirable off clears any previously picked date so a stale
  /// expiry can't linger if it's switched back on later without a
  /// re-pick. Turning it on is driven from the view, which opens the
  /// date/time picker and calls [setExpiryDate] with the result.
  void setExpirable(bool value) {
    if (_isExpirable == value) return;
    _isExpirable = value;
    if (!value) _expiryDate = null;
    notifyListeners();
  }

  void setExpiryDate(DateTime date) {
    _expiryDate = date;
    notifyListeners();
  }

  final List<AttachmentItem> _attachments = [];
  List<AttachmentItem> get attachments => List.unmodifiable(_attachments);

  bool _showAttachmentError = false;
  bool get showAttachmentError => _showAttachmentError;

  /// Saving requires a document to be attached. Keeping this state in the
  /// view model lets the error disappear immediately after a successful pick.
  bool validateAttachments() {
    final isValid = _attachments.isNotEmpty;
    if (_showAttachmentError == !isValid) return isValid;
    _showAttachmentError = !isValid;
    notifyListeners();
    return isValid;
  }

  /// OCR text per attachment path, so removing an attachment correctly
  /// drops its contribution to [ocrText] instead of leaving stale text
  /// behind. Carried over from an existing document when editing via
  /// [_baseOcrText], since re-deriving it from [startEditing]'s rebuilt
  /// [AttachmentItem]s would require re-running OCR on every edit.
  final Map<String, String> _ocrTextByPath = {};
  String _baseOcrText = '';

  /// Every new attachment's OCR call is chained onto this — see
  /// [_runOcrAndAi] — so PDF rendering (which this codebase documents
  /// Android can't do in parallel) never overlaps, even across rapid-fire
  /// Camera → Gallery → Files picks.
  Future<void> _ocrChain = Future.value();

  bool _isProcessingOcr = false;
  bool get isProcessingOcr => _isProcessingOcr;

  bool _isAnalyzing = false;
  bool get isAnalyzing => _isAnalyzing;

  /// Combined OCR text for every attachment still on the document — the
  /// AI service's input and one of Search's match targets.
  String get ocrText {
    final parts = [
      _baseOcrText,
      for (final a in _attachments)
        if (_ocrTextByPath[a.path] case final text?) text,
    ].where((t) => t.trim().isNotEmpty);
    return parts.join('\n\n');
  }

  Future<void> _ocrAttachment(AttachmentItem attachment) async {
    final text = await _processing.extractText(attachment.path);
    if (text.trim().isNotEmpty) _ocrTextByPath[attachment.path] = text;
  }

  /// Runs after every pick call (camera/gallery/file) with just the
  /// attachments added in that round: OCRs them (chained sequentially
  /// through [_ocrChain]), then — with connectivity and an API key —
  /// sends the combined text (every page, old and new) to
  /// [AiDocumentService]. For a new document this pre-fills whichever of
  /// title/category/description/expiry the user hasn't already touched;
  /// when editing an existing document, only the description is
  /// refreshed (see [_applyRegeneratedDescription]) — e.g. scanning an ID
  /// card's back side after the front was already saved should fold both
  /// sides' OCR into one redefined description, without touching a
  /// title/category/tags the user already set. Deliberately not awaited
  /// by the pick methods that call it — attachments appear immediately,
  /// OCR/AI happen in the background, and neither one blocks Save (see
  /// [isProcessingOcr]/[isAnalyzing] for the inline status line the view
  /// shows meanwhile).
  Future<void> _runOcrAndAi(List<AttachmentItem> newAttachments) async {
    _isProcessingOcr = true;
    notifyListeners();

    for (final attachment in newAttachments) {
      _ocrChain = _ocrChain.then((_) => _ocrAttachment(attachment));
    }
    try {
      await _ocrChain;
    } catch (error, stack) {
      _ocrChain = Future.value();
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'document OCR',
        ),
      );
    }

    _isProcessingOcr = false;
    notifyListeners();

    if (_disposed || _completed || _isSaving) return;
    final text = ocrText;
    if (text.trim().isEmpty) return;
    await _analyze(text);
  }

  /// (Re-)runs AI analysis against [text] and applies whatever it
  /// suggests. Shared by [_runOcrAndAi] (which only ever fires right
  /// after a fresh pick) and [reorganizeWithAi] (an on-demand retrigger
  /// for everything else -- resuming a draft with attachments already in
  /// place never goes through a pick at all, so without this there'd be
  /// no way to run AI organization on it a second time).
  Future<void> _analyze(String text) async {
    _isAnalyzing = true;
    notifyListeners();
    final suggestion = await _processing.analyze(
      ocrText: text,
      availableCategories: [
        for (final c in _categoryUseCases.categories) c.name,
      ],
    );
    if (_disposed || _completed || _isSaving) return;
    _isAnalyzing = false;
    if (suggestion != null) {
      isEditing
          ? _applyRegeneratedDescription(suggestion)
          : _applySuggestion(suggestion);
    }
    notifyListeners();
  }

  /// Manually triggers AI organization from the document's current,
  /// already-OCR'd text -- the button next to the attachments grid calls
  /// this. A no-op while OCR/AI is already running, or with nothing to
  /// analyze yet.
  Future<void> reorganizeWithAi() async {
    if (_isProcessingOcr || _isAnalyzing) return;
    final text = ocrText;
    if (text.trim().isEmpty) return;
    await _analyze(text);
  }

  /// Edit mode only: a newly added page can change what the document as a
  /// whole is about (e.g. an ID card's back side), so — unlike
  /// [_applySuggestion]'s pre-fill-only semantics — this unconditionally
  /// replaces the description with one re-derived from every page's
  /// combined OCR text. Title/category/tags/expiry are left untouched,
  /// since those are far more likely to already be deliberately set.
  void _applyRegeneratedDescription(AiDocumentSuggestion suggestion) {
    if (suggestion.description.isNotEmpty) {
      descriptionController.text = suggestion.description;
    }
  }

  /// Only pre-fills fields the user hasn't already touched — never
  /// overwrites a title typed while OCR/AI were still running, a category
  /// already picked, or an expiry already set.
  void _applySuggestion(AiDocumentSuggestion suggestion) {
    final title = suggestion.title;
    if (titleController.text.trim().isEmpty && title != null) {
      titleController.text = title;
    }

    final categoryName = suggestion.categoryName;
    if (_selectedCategory == null && categoryName != null) {
      final match = _categoryUseCases.categories.where(
        (c) => c.name.toLowerCase() == categoryName.toLowerCase(),
      );
      if (match.isNotEmpty) _selectedCategory = match.first;
    }

    if (descriptionController.text.trim().isEmpty &&
        suggestion.description.isNotEmpty) {
      descriptionController.text = suggestion.description;
    }

    if (!_isExpirable &&
        suggestion.isExpirable &&
        suggestion.expiryDate != null) {
      _isExpirable = true;
      _expiryDate = suggestion.expiryDate;
    }

    if (_tags.isEmpty && suggestion.tags.isNotEmpty) {
      _applySuggestedTags(suggestion.tags);
    }
  }

  /// Adds up to [maxTagCount] AI-suggested tags — normalized to lowercase
  /// slugs (unlike manual entry, which is kept free-form) since these come
  /// from the AI prompt that's specifically told to produce that shape, so
  /// they stay consistent with each other. A tag that's empty, too long, or
  /// a duplicate is just skipped — there's no input field here to surface
  /// an error against.
  void _applySuggestedTags(List<String> suggested) {
    for (final raw in suggested) {
      if (_tags.length >= maxTagCount) break;
      final tag = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
      if (tag.isEmpty || tag.length > maxTagLength) continue;
      if (_tags.contains(tag)) continue;
      _tags.add(tag);
    }
  }

  void _acceptAttachments(AttachmentSelection selection) {
    if (_disposed || selection.items.isEmpty) return;
    _attachments.addAll(selection.items);
    if (!isEditing) _ownedPaths.addAll(selection.items.map((a) => a.path));
    _showAttachmentError = false;
    notifyListeners();
    unawaited(_runOcrAndAi(selection.items));
    _queueDuplicateChecks(selection.items);
  }

  /// The attachment currently flagged as a possible duplicate, and the
  /// document it matches -- non-null exactly while the view should show
  /// the resolution prompt. Call [resolveDuplicate] to clear it.
  String? duplicateAttachmentPath;
  DocumentItem? duplicateMatch;

  /// Every newly-added attachment still waiting to be hashed/checked --
  /// shared by every call to [_queueDuplicateChecks] (one camera capture,
  /// one gallery multi-select, etc. can each add to it) and drained by a
  /// single running loop, so two picks made in quick succession can never
  /// end up with two checks racing to set [duplicateMatch] at once.
  final List<AttachmentItem> _pendingDuplicateChecks = [];
  bool _duplicateCheckRunning = false;
  Completer<void>? _duplicateResolved;

  void _queueDuplicateChecks(List<AttachmentItem> newAttachments) {
    _pendingDuplicateChecks.addAll(newAttachments);
    if (_duplicateCheckRunning) return;
    _duplicateCheckRunning = true;
    unawaited(_runDuplicateCheckLoop());
  }

  /// Hashes and checks one pending attachment at a time against every
  /// already-saved document's attachments, waiting for [resolveDuplicate]
  /// before starting the next one -- so a multi-page capture never shows
  /// more than one duplicate prompt stacked on top of another. Entirely
  /// best-effort: a hashing/lookup failure just skips that attachment
  /// rather than blocking the capture.
  Future<void> _runDuplicateCheckLoop() async {
    while (_pendingDuplicateChecks.isNotEmpty) {
      if (_disposed || _completed) break;
      final attachment = _pendingDuplicateChecks.removeAt(0);
      DocumentItem? match;
      try {
        match = await _documentUseCases.findDuplicateOf(
          attachment.path,
          excludeDocumentId: _editingDocument?.id ?? _captureId,
        );
      } catch (_) {
        continue;
      }
      if (_disposed || _completed || match == null) continue;
      // The page may have been removed (or the capture already saved)
      // while the hash/lookup was in flight.
      if (!_attachments.contains(attachment)) continue;
      duplicateAttachmentPath = attachment.path;
      duplicateMatch = match;
      notifyListeners();
      final completer = Completer<void>();
      _duplicateResolved = completer;
      await completer.future;
      if (_disposed) break;
    }
    _duplicateCheckRunning = false;
  }

  /// Applies the user's choice for whatever attachment
  /// [duplicateAttachmentPath] currently points at. "Open existing" and
  /// "Skip" both drop this page from the capture (it's either redundant or
  /// the user is going to look at the original instead); "Keep both"
  /// leaves it in place. Never deletes the existing document either way.
  void resolveDuplicate(DuplicateResolution resolution) {
    final path = duplicateAttachmentPath;
    if (path == null) return;
    if (resolution != DuplicateResolution.keepBoth) {
      final toRemove = _attachments.where((a) => a.path == path);
      if (toRemove.isNotEmpty) removeAttachment(toRemove.first);
    }
    duplicateAttachmentPath = null;
    duplicateMatch = null;
    notifyListeners();
    _duplicateResolved?.complete();
    _duplicateResolved = null;
  }

  Future<bool> pickFromCamera() async {
    final selection = await _processing.pickFromCamera();
    _acceptAttachments(selection);
    return selection.scanFailed;
  }

  Future<bool> pickFromGallery() async {
    final selection = await _processing.pickFromGallery();
    _acceptAttachments(selection);
    return selection.galleryFailed;
  }

  Future<bool> pickFile() async {
    final selection = await _processing.pickFile();
    _acceptAttachments(selection);
    return selection.skippedImages;
  }

  Future<void> addSharedFiles(List<String> sourcePaths) async {
    _acceptAttachments(await _processing.addSharedFiles(sourcePaths));
  }

  void removeAttachment(AttachmentItem attachment) {
    _attachments.remove(attachment);
    _missingPaths.remove(attachment.path);
    _ocrTextByPath.remove(attachment.path);
    notifyListeners();
  }

  bool _isSaving = false;
  bool get isSaving => _isSaving;
  bool _disposed = false;
  @override
  void notifyListeners() {
    if (!_disposed) {
      _draftChanged();
      super.notifyListeners();
    }
  }

  /// Persists any attachment still pointing at one of
  /// [DocumentPageRasterizer]'s scratch pages (temp-dir renders from
  /// [startEditing] splitting a PDF for editing) into the app's permanent
  /// attachment storage before it can be saved into a document's
  /// `filePaths` -- a temp path can be purged by the OS at any time, so it
  /// can't be kept as-is. A no-op for the common case: fresh camera/
  /// gallery/file picks are already permanent paths the moment they're
  /// picked.
  Future<void> _persistTempAttachments() async {
    for (var i = 0; i < _attachments.length; i++) {
      final attachment = _attachments[i];
      if (!await DocumentPageRasterizer.isScratchPage(attachment.path)) {
        continue;
      }

      final persistedPath = await DocumentPageRasterizer.persistScratchPage(
        attachment.path,
      );
      if (_ocrTextByPath.containsKey(attachment.path)) {
        _ocrTextByPath[persistedPath] = _ocrTextByPath.remove(attachment.path)!;
      }
      _attachments[i] = AttachmentItem(
        path: persistedPath,
        type: attachment.type,
      );
      try {
        await File(attachment.path).delete();
      } catch (_) {
        // Best-effort -- the temp file will eventually be cleared by the
        // OS anyway, not worth failing the save over.
      }
    }
  }

  /// Best-effort cleanup for an edit's now-unreferenced files -- most
  /// notably a legacy `merged_*.pdf` once its first edit splits it into
  /// per-page attachments and [_persistTempAttachments] persists those
  /// under new paths. Nothing else in this codebase's update path diffs
  /// old vs. new `filePaths`, so without this every such edit would
  /// silently leak the old merged file on disk. A path still present in
  /// [newPaths] (e.g. an untouched single image or a real attached PDF the
  /// user didn't remove) is left alone.
  Future<void> _deleteDroppedFiles(
    List<String> oldPaths,
    List<String> newPaths,
  ) async {
    final kept = newPaths.toSet();
    for (final path in oldPaths) {
      if (kept.contains(path)) continue;
      try {
        await File(path).delete();
      } catch (_) {
        // Best-effort -- a missing/locked file isn't worth failing over.
      }
    }
  }

  DocumentItem? savedDocument;

  Future<void> submit() async {
    if (_isSaving || duplicateMatch != null) return;
    _isSaving = true;
    notifyListeners();
    try {
      await flushDraft();
      _draftPaused = true;
      if (draftsEnabled) {
        _missingPaths = await _drafts!.missingFiles(_snapshot());
        if (_missingPaths.isNotEmpty) {
          throw StateError('Remove or replace missing draft pages');
        }
      }
      await _persistTempAttachments();
      final category = _selectedCategory;
      final original = _editingDocument;
      final item = DocumentItem(
        id: original?.id ?? _captureId,
        title: titleController.text.trim(),
        category: category?.name ?? 'Uncategorized',
        categoryId: category?.id ?? uncategorizedCategoryId,
        iconKey: category?.iconKey ?? 'solidFolder',
        tags: _tags,
        filePaths: [for (final a in _attachments) a.path],
        createdAt: original?.createdAt ?? DateTime.now(),
        isFavorite: original?.isFavorite ?? false,
        isExpirable: _isExpirable,
        expiryDate: _expiryDate,
        description: descriptionController.text.trim(),
        ocrText: ocrText,
      );
      if (original != null) {
        await _documentUseCases.updateDocument(item);
        await _deleteDroppedFiles(original.filePaths, item.filePaths);
      } else {
        await _documentUseCases.addDocument(item);
      }
      savedDocument = item;
      _completed = true;
      if (draftsEnabled) {
        // Saving the document doesn't remove its draft row by itself --
        // discard it explicitly so it drops out of the Drafts inbox.
        // Failures must not turn a successful save into a second save.
        try {
          await _drafts!.discard(item.id);
        } catch (_) {}
        await _deleteDroppedFiles(_ownedPaths.toList(), item.filePaths);
      }
      triggerSharedSpaceSyncIfNeeded(
        syncBackgroundService: _syncBackgroundService,
        spaceId: category?.spaceId,
      );
    } finally {
      _draftPaused = false;
      _isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _duplicateResolved?.complete();
    titleController.dispose();
    tagController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
