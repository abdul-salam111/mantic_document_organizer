import 'dart:async';
import 'dart:io';

import 'package:content_resolver/content_resolver.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../../../core/ai/ai_exports.dart';
import '../../../../../../../core/ocr/ocr_exports.dart';
import '../../../../../../home/home_exports.dart';

enum AttachmentType { image, file }

enum TagError { limitReached, tooLong, invalidCharacters, duplicate }

class AttachmentItem {
  final String path;
  final AttachmentType type;

  const AttachmentItem({required this.path, required this.type});
}

/// No real document data layer exists yet (see CLAUDE.md's "Known
/// mismatches" section) — this feature's REST datasource/repository/
/// usecase files are the original brick-scaffolded plumbing and stay
/// untouched for whenever a real sqflite repository replaces them;
/// [submit] writes straight into the shared [DocumentLocalStore] (also
/// used by HomeViewModel) instead, so a saved document actually shows up
/// in Home's Recent Files strip.
class AddDocumentViewModel extends ChangeNotifier {
  final CategoryLocalStore _categoryStore;
  final DocumentLocalStore _documentStore;
  final OcrService _ocrService;
  final AiDocumentService _aiService;

  /// No default category selection — opening this screen with no category
  /// already in context (the navbar's "+" button) starts on Uncategorized,
  /// matching [submit]'s existing `category == null` fallback. Opening it
  /// from a category's own "+" button still preselects that category via
  /// [preselectCategory], called separately by the view.
  AddDocumentViewModel({
    required CategoryLocalStore categoryStore,
    required DocumentLocalStore documentStore,
    required OcrService ocrService,
    required AiDocumentService aiService,
  }) : _categoryStore = categoryStore,
       _documentStore = documentStore,
       _ocrService = ocrService,
       _aiService = aiService;

  /// Called from the view when opened with a category already in
  /// context (e.g. the "+" button on a category's document list) — picks
  /// it by id from the live store rather than trusting the passed-in
  /// [CategoryItem] as-is, since it may be stale (edited/deleted since).
  /// No-op if the id no longer matches anything, leaving the
  /// constructor's default selection in place.
  void preselectCategory(CategoryItem category) {
    final matches = _categoryStore.categories.where((c) => c.id == category.id);
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
    _selectedCategory = _categoryStore.byId(document.categoryId);
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

  List<CategoryItem> get categories =>
      List<CategoryItem>.of(_categoryStore.categories)
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
  static final _tagPattern = RegExp(r'^[a-z0-9_-]+$');

  final List<String> _tags = [];
  List<String> get tags => List.unmodifiable(_tags);

  TagError? _tagError;
  TagError? get tagError => _tagError;

  void clearTagError() {
    if (_tagError == null) return;
    _tagError = null;
    notifyListeners();
  }

  /// Tags are normalized to lowercase slugs (letters/numbers/-/_ only, no
  /// spaces) so they stay consistent for future filtering/search, capped
  /// at [maxTagLength] chars and [maxTagCount] tags per document.
  void addTag() {
    final tag = tagController.text.trim().toLowerCase();
    if (tag.isEmpty) return;
    if (_tags.length >= maxTagCount) {
      _tagError = TagError.limitReached;
    } else if (tag.length > maxTagLength) {
      _tagError = TagError.tooLong;
    } else if (!_tagPattern.hasMatch(tag)) {
      _tagError = TagError.invalidCharacters;
    } else if (_tags.contains(tag)) {
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
    final text = await _ocrService.extractText(attachment.path);
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
    await _ocrChain;

    _isProcessingOcr = false;
    notifyListeners();

    if (isEditing) return;
    final text = ocrText;
    if (text.trim().isEmpty) return;

    _isAnalyzing = true;
    notifyListeners();
    final suggestion = await _aiService.analyze(
      ocrText: text,
      availableCategories: [for (final c in _categoryStore.categories) c.name],
    );
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
      final match = _categoryStore.categories.where(
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

  /// Adds up to [maxTagCount] AI-suggested tags, running each through the
  /// same normalization/validation manual entry uses (lowercase, allowed
  /// characters, length, no duplicates) — a tag that fails is just skipped,
  /// there's no input field here to surface an error against.
  void _applySuggestedTags(List<String> suggested) {
    for (final raw in suggested) {
      if (_tags.length >= maxTagCount) break;
      final tag = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
      if (tag.isEmpty || tag.length > maxTagLength) continue;
      if (!_tagPattern.hasMatch(tag) || _tags.contains(tag)) continue;
      _tags.add(tag);
    }
  }

  /// Every attachment source (scanner, gallery, file browser) hands back a
  /// path that's only guaranteed to live in a cache/temp location the OS is
  /// free to reclaim at any time — none of them write into this app's own
  /// permanent storage on their own. [_persistAttachment] copies into
  /// `<app documents>/documents/` so a saved document's files actually
  /// survive (see ICON_TYPE_AND_ATTACHMENT_STORAGE_NOTES.txt for the full
  /// reasoning). Computed once per pick call and passed down rather than
  /// re-resolved per file.
  Future<Directory> _attachmentsDirectory() async {
    final appDocuments = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDocuments.path}/documents');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> _persistAttachment(
    String sourcePath,
    Directory dir,
    int index,
  ) async {
    final dotIndex = sourcePath.lastIndexOf('.');
    final extension = dotIndex == -1 ? '' : sourcePath.substring(dotIndex);
    final destinationPath =
        '${dir.path}/doc_${DateTime.now().microsecondsSinceEpoch}_$index$extension';
    await File(sourcePath).copy(destinationPath);
    return destinationPath;
  }

  /// Opens Google ML Kit's document scanner (VisionKit on iOS) — a
  /// fullscreen native flow with its own live edge detection, cropping,
  /// filtering and multi-page capture, so none of that needs building here.
  /// Returns true if the scan genuinely failed (not just cancelled), so the
  /// caller can surface a toast.
  Future<bool> pickFromCamera() async {
    try {
      final result = await FlutterDocScanner().getScannedDocumentAsImages(
        page: 10,
      );
      if (result == null || result.images.isEmpty) return false;
      final dir = await _attachmentsDirectory();
      final newAttachments = <AttachmentItem>[];
      for (var i = 0; i < result.images.length; i++) {
        final path = await _localizeScan(result.images[i], dir, i);
        final attachment = AttachmentItem(
          path: path,
          type: AttachmentType.image,
        );
        _attachments.add(attachment);
        newAttachments.add(attachment);
      }
      notifyListeners();
      unawaited(_runOcrAndAi(newAttachments));
      return false;
    } on DocScanException catch (e) {
      return e.code != DocScanException.codeCancelled;
    }
  }

  /// Each scanned page comes back as either a content:// URI (ML Kit's own
  /// FileProvider-backed cache) or a file:// URI — either way, `File()`
  /// can't be handed the raw URI string directly: a content:// URI isn't a
  /// real filesystem path at all, and a file:// URI's `file://` prefix is
  /// part of the string, not something `File()` strips on its own. iOS
  /// returns a plain path with no scheme, which needs no conversion. Either
  /// way, the result is written straight into [documentsDir] — this is the
  /// one attachment source that already copied its source file, so it
  /// writes its permanent copy directly instead of copying twice.
  Future<String> _localizeScan(
    String uriOrPath,
    Directory documentsDir,
    int i,
  ) async {
    final destinationPath =
        '${documentsDir.path}/scan_${DateTime.now().microsecondsSinceEpoch}_$i.jpg';
    final uri = Uri.tryParse(uriOrPath);
    if (uri != null && uri.scheme == 'content') {
      await ContentResolver.resolveContentToFile(uriOrPath, destinationPath);
      return destinationPath;
    }
    final sourcePath = (uri != null && uri.scheme == 'file')
        ? uri.toFilePath()
        : uriOrPath;
    await File(sourcePath).copy(destinationPath);
    return destinationPath;
  }

  /// Multi-select — matches the reference design's gallery picker, which
  /// lets several photos be attached in one go.
  Future<void> pickFromGallery() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    final dir = await _attachmentsDirectory();
    final newAttachments = <AttachmentItem>[];
    for (var i = 0; i < picked.length; i++) {
      final path = await _persistAttachment(picked[i].path, dir, i);
      final attachment = AttachmentItem(path: path, type: AttachmentType.image);
      _attachments.add(attachment);
      newAttachments.add(attachment);
    }
    notifyListeners();
    unawaited(_runOcrAndAi(newAttachments));
  }

  static const _imageExtensions = {
    'png',
    'jpg',
    'jpeg',
    'gif',
    'bmp',
    'webp',
    'heic',
    'heif',
    'tif',
    'tiff',
  };

  /// Non-image extensions the system file browser is restricted to —
  /// png/jpg/etc. belong to the Camera and Gallery buttons instead, so
  /// the picker itself is scoped to these rather than just filtering
  /// afterward (that left images visibly selectable in the browser,
  /// which just got filtered back out post-pick and confused users).
  /// Not exhaustive, but covers what "a document" realistically means.
  static const _documentExtensions = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
    'rtf',
    'csv',
    'odt',
    'ods',
    'odp',
    'epub',
    'md',
    'json',
    'xml',
    'zip',
    'rar',
    '7z',
  ];

  bool _isImage(PlatformFile file) {
    final extension = file.extension?.toLowerCase();
    if (extension != null) return _imageExtensions.contains(extension);
    // Fallback for platforms/providers that don't populate `extension`.
    final name = file.name.toLowerCase();
    final dot = name.lastIndexOf('.');
    if (dot == -1) return false;
    return _imageExtensions.contains(name.substring(dot + 1));
  }

  /// Returns true if one or more selected files were skipped for being
  /// images — shouldn't normally happen now that the picker itself is
  /// restricted to [_documentExtensions], but some Android file manager
  /// providers ignore that restriction, so this stays as a backstop (the
  /// caller can surface it as a toast).
  Future<bool> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: _documentExtensions,
    );
    if (result == null) return false;
    var skippedImage = false;
    final dir = await _attachmentsDirectory();
    final newAttachments = <AttachmentItem>[];
    for (var i = 0; i < result.files.length; i++) {
      final file = result.files[i];
      final path = file.path;
      if (path == null) continue;
      if (_isImage(file)) {
        skippedImage = true;
        continue;
      }
      final persistedPath = await _persistAttachment(path, dir, i);
      final attachment = AttachmentItem(
        path: persistedPath,
        type: AttachmentType.file,
      );
      _attachments.add(attachment);
      newAttachments.add(attachment);
    }
    notifyListeners();
    unawaited(_runOcrAndAi(newAttachments));
    return skippedImage;
  }

  void removeAttachment(AttachmentItem attachment) {
    _attachments.remove(attachment);
    notifyListeners();
  }

  void submit() {
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
      _documentStore.updateDocument(item);
    } else {
      _documentStore.addDocument(item);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    tagController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
