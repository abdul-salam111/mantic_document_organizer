import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../../home/home_exports.dart';

enum AttachmentType { image, file }

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

  AddDocumentViewModel({
    required CategoryLocalStore categoryStore,
    required DocumentLocalStore documentStore,
  }) : _categoryStore = categoryStore,
       _documentStore = documentStore {
    final sorted = List<CategoryItem>.of(_categoryStore.categories)
      ..sort((a, b) => a.name.compareTo(b.name));
    if (sorted.isNotEmpty) _selectedCategory = sorted.first;
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

  final List<String> _tags = [];
  List<String> get tags => List.unmodifiable(_tags);

  void addTag() {
    final tag = tagController.text.trim();
    if (tag.isEmpty || _tags.contains(tag)) return;
    _tags.add(tag);
    tagController.clear();
    notifyListeners();
  }

  void removeTag(String tag) {
    _tags.remove(tag);
    notifyListeners();
  }

  bool _isFavorite = false;
  bool get isFavorite => _isFavorite;

  void toggleFavorite() {
    _isFavorite = !_isFavorite;
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

  Future<void> pickFromCamera() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null) return;
    _attachments.add(
      AttachmentItem(path: picked.path, type: AttachmentType.image),
    );
    notifyListeners();
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

  /// Documents only (PDF, Word, etc.) — png/jpg/etc. belong to the Camera
  /// and Gallery buttons instead, so any image picked here is dropped.
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

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;
    for (final file in result.files) {
      final path = file.path;
      if (path == null) continue;
      if (_imageExtensions.contains(file.extension?.toLowerCase())) continue;
      _attachments.add(AttachmentItem(path: path, type: AttachmentType.file));
    }
    notifyListeners();
  }

  void removeAttachment(AttachmentItem attachment) {
    _attachments.remove(attachment);
    notifyListeners();
  }

  void submit() {
    final category = _selectedCategory;
    _documentStore.addDocument(
      DocumentItem(
        title: titleController.text.trim(),
        category: category?.name ?? 'Uncategorized',
        icon: category?.icon ?? FontAwesomeIcons.folder,
        tags: _tags,
        isFavorite: _isFavorite,
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
