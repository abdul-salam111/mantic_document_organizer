import 'package:content_resolver/content_resolver.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

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

  /// No default category selection — opening this screen with no category
  /// already in context (the navbar's "+" button) starts on Uncategorized,
  /// matching [submit]'s existing `category == null` fallback. Opening it
  /// from a category's own "+" button still preselects that category via
  /// [preselectCategory], called separately by the view.
  AddDocumentViewModel({
    required CategoryLocalStore categoryStore,
    required DocumentLocalStore documentStore,
  }) : _categoryStore = categoryStore,
       _documentStore = documentStore;

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

  final TextEditingController titleController = TextEditingController();
  final TextEditingController tagController = TextEditingController();
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
      final dir = await getTemporaryDirectory();
      for (var i = 0; i < result.images.length; i++) {
        final path = await _localizeScan(result.images[i], dir.path, i);
        _attachments.add(
          AttachmentItem(path: path, type: AttachmentType.image),
        );
      }
      notifyListeners();
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
  /// returns a plain path with no scheme, which needs no conversion.
  Future<String> _localizeScan(
    String uriOrPath,
    String tempDirPath,
    int i,
  ) async {
    final uri = Uri.tryParse(uriOrPath);
    if (uri == null || uri.scheme.isEmpty) return uriOrPath;
    if (uri.scheme == 'file') return uri.toFilePath();
    if (uri.scheme != 'content') return uriOrPath;
    final localPath =
        '$tempDirPath/scan_${DateTime.now().microsecondsSinceEpoch}_$i.jpg';
    await ContentResolver.resolveContentToFile(uriOrPath, localPath);
    return localPath;
  }

  /// Multi-select — matches the reference design's gallery picker, which
  /// lets several photos be attached in one go.
  Future<void> pickFromGallery() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    _attachments.addAll(
      picked.map(
        (f) => AttachmentItem(path: f.path, type: AttachmentType.image),
      ),
    );
    notifyListeners();
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
    for (final file in result.files) {
      final path = file.path;
      if (path == null) continue;
      if (_isImage(file)) {
        skippedImage = true;
        continue;
      }
      _attachments.add(AttachmentItem(path: path, type: AttachmentType.file));
    }
    notifyListeners();
    return skippedImage;
  }

  void removeAttachment(AttachmentItem attachment) {
    _attachments.remove(attachment);
    notifyListeners();
  }

  void submit() {
    final category = _selectedCategory;
    _documentStore.addDocument(
      DocumentItem(
        id: generateLocalId(),
        title: titleController.text.trim(),
        category: category?.name ?? 'Uncategorized',
        categoryId: category?.id ?? uncategorizedCategoryId,
        icon: category?.icon ?? FontAwesomeIcons.folder,
        tags: _tags,
        filePaths: [for (final a in _attachments) a.path],
        createdAt: DateTime.now(),
        isExpirable: _isExpirable,
        expiryDate: _expiryDate,
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    tagController.dispose();
    super.dispose();
  }
}
