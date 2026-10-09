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
import '../../../../../core/utils/document_pdf_exporter.dart';
import '../../../../../core/utils/shared_space_sync.dart';

enum TagError { limitReached, tooLong, duplicate }

/// Where a freshly-added page's file should come from, chosen up front
/// (the navbar's "+" button prompts for this before even opening the
/// form) so [AddDocumentView] can trigger the matching picker
/// automatically instead of requiring an extra in-page tap.
enum AttachmentSource { camera, gallery, file }

class AddDocumentViewModel extends ChangeNotifier {
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
    required CategoryUseCases categoryUseCases,
    required DocumentUseCases documentUseCases,
    required DocumentProcessingUseCases processing,
    required DocumentSyncBackgroundService syncBackgroundService,
  }) : _categoryUseCases = categoryUseCases,
       _documentUseCases = documentUseCases,
       _processing = processing,
       _syncBackgroundService = syncBackgroundService;

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

  /// Prefills every field from an existing document. Called once by the
  /// view right after creation, mirroring [preselectCategory].
  void startEditing(DocumentItem document) {
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
    _attachments
      ..clear()
      ..addAll([
        for (final path in document.filePaths)
          AttachmentItem(
            path: path,
            type: isImagePath(path)
                ? AttachmentType.image
                : AttachmentType.file,
          ),
      ]);
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
  /// through [_ocrChain]), then — for a new document, with connectivity
  /// and an API key — sends the combined text to [AiDocumentService] and
  /// pre-fills whichever of title/category/description/expiry the user
  /// hasn't already touched. Deliberately not awaited by the pick methods
  /// that call it — attachments appear immediately, OCR/AI happen in the
  /// background, and neither one blocks Save (see [isProcessingOcr]/
  /// [isAnalyzing] for the inline status line the view shows meanwhile).
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

    if (_disposed || isEditing) return;
    final text = ocrText;
    if (text.trim().isEmpty) return;

    _isAnalyzing = true;
    notifyListeners();
    final suggestion = await _processing.analyze(
      ocrText: text,
      availableCategories: [
        for (final c in _categoryUseCases.categories) c.name,
      ],
    );
    if (_disposed) return;
    _isAnalyzing = false;
    if (suggestion != null) _applySuggestion(suggestion);
    notifyListeners();
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
    _showAttachmentError = false;
    notifyListeners();
    unawaited(_runOcrAndAi(selection.items));
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
    notifyListeners();
  }

  bool _isSaving = false;
  bool get isSaving => _isSaving;
  bool _disposed = false;
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  /// Collapses 2+ image-type attachments into a single PDF before saving,
  /// so a multi-page scan (several photos of one physical document) is
  /// stored as the one record it represents instead of that many separate
  /// image rows. A lone image, or an attachment that's already something
  /// else (an imported PDF/docx), passes through untouched -- there's
  /// nothing to collapse, and real PDF byte streams can't be merged by
  /// this library (same limitation [DocumentPdfExporter] documents).
  Future<void> _mergeImageAttachmentsForStorage() async {
    final imageAttachments = _attachments
        .where((a) => a.type == AttachmentType.image)
        .toList();
    if (imageAttachments.length < 2) return;

    final combinedOcr = [
      for (final a in imageAttachments)
        if (_ocrTextByPath[a.path] case final text?) text,
    ].where((t) => t.trim().isNotEmpty).join('\n\n');

    final mergedPath = await DocumentPdfExporter.mergeForStorage([
      for (final a in imageAttachments) a.path,
    ]);

    for (final a in imageAttachments) {
      _ocrTextByPath.remove(a.path);
      try {
        await File(a.path).delete();
      } catch (_) {
        // Best-effort cleanup -- a missing/locked source file isn't worth
        // failing the save over, it's just now-orphaned temp storage.
      }
    }
    if (combinedOcr.isNotEmpty) _ocrTextByPath[mergedPath] = combinedOcr;

    var inserted = false;
    final merged = <AttachmentItem>[];
    for (final a in _attachments) {
      if (a.type != AttachmentType.image) {
        merged.add(a);
        continue;
      }
      if (!inserted) {
        merged.add(
          AttachmentItem(path: mergedPath, type: AttachmentType.file),
        );
        inserted = true;
      }
    }
    _attachments
      ..clear()
      ..addAll(merged);
  }

  Future<void> submit() async {
    if (_isSaving) return;
    _isSaving = true;
    notifyListeners();
    try {
      await _mergeImageAttachmentsForStorage();
      final category = _selectedCategory;
      final original = _editingDocument;
      final item = DocumentItem(
        id: original?.id ?? generateLocalId(),
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
      } else {
        await _documentUseCases.addDocument(item);
      }
      triggerSharedSpaceSyncIfNeeded(
        syncBackgroundService: _syncBackgroundService,
        spaceId: category?.spaceId,
      );
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    titleController.dispose();
    tagController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
