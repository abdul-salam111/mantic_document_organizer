import '../../../domain/usecases/document_processing_usecases.dart';
import 'package:mantic_doc_org/features/categories/domain/entities/category_item.dart';
import 'package:mantic_doc_org/features/categories/domain/usecases/category_usecases.dart';
import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_usecases.dart';
import 'package:flutter/foundation.dart';

class DocumentViewerViewModel extends ChangeNotifier {
  final DocumentProcessingUseCases _processing;
  final DocumentUseCases _documentUseCases;
  final CategoryUseCases _categoryUseCases;

  DocumentViewerViewModel({
    required DocumentProcessingUseCases processing,
    required DocumentUseCases documentUseCases,
    required CategoryUseCases categoryUseCases,
  }) : _processing = processing,
       _documentUseCases = documentUseCases,
       _categoryUseCases = categoryUseCases {
    _documentUseCases.addListener(notifyListeners);
  }

  Future<void> share(DocumentItem document) => _processing.share(document);
  Future<void> exportPdf(DocumentItem document) =>
      _processing.exportPdf(document);

  Future<void> shareFile(String path) => _processing.shareFile(path);

  Future<void> shareFiles(List<String> paths) => _processing.shareFiles(paths);
  Future<void> shareDirect(List<String> paths, String packageName) =>
      _processing.shareDirect(paths, packageName);
  Future<void> shareSelectedAsPdf(List<String> paths, String title) =>
      _processing.shareAsPdf(paths, title);
  Future<void> shareSelectedAsImages(List<String> paths) =>
      _processing.shareAsImages(paths);
  Future<void> exportSelectedPagesAsPdf(List<String> paths, String title) =>
      _processing.exportPagesAsPdf(paths, title);
  Future<void> saveSelectedToGallery(List<String> paths) =>
      _processing.saveToGallery(paths);

  late final String _documentId;

  /// Called once from the view's `ChangeNotifierProvider.create`, before
  /// the first frame — mirrors CategoryDocumentsViewModel.init.
  void init(DocumentItem document) {
    _documentId = document.id;
  }

  /// Null once the document has been deleted (by this screen or
  /// elsewhere) — the view falls back to popping itself when this happens.
  DocumentItem? get document {
    for (final d in _documentUseCases.documents) {
      if (d.id == _documentId) return d;
    }
    return null;
  }

  List<CategoryItem> get categories =>
      List<CategoryItem>.of(_categoryUseCases.categories)
        ..sort((a, b) => a.name.compareTo(b.name));

  int _pageIndex = 0;
  int get pageIndex => _pageIndex;

  void setPageIndex(int value) {
    if (_pageIndex == value) return;
    _pageIndex = value;
    notifyListeners();
  }

  Future<void> toggleFavorite() async {
    final current = document;
    if (current == null) return;
    await _documentUseCases.toggleFavorite(current);
  }

  Future<void> rename(String newTitle) async {
    final current = document;
    final trimmed = newTitle.trim();
    if (current == null || trimmed.isEmpty) return;
    await _documentUseCases.updateDocument(current.copyWith(title: trimmed));
  }

  Future<void> moveToCategory(CategoryItem category) async {
    final current = document;
    if (current == null) return;
    await _documentUseCases.updateDocument(
      current.copyWith(
        category: category.name,
        categoryId: category.id,
        iconKey: category.iconKey,
      ),
    );
  }

  /// Soft delete — moves the document to Trash, recoverable within
  /// [DocumentUseCases.trashRetentionPeriod]. See [DocumentUseCases.
  /// trashDocument].
  Future<void> delete() async {
    final current = document;
    if (current == null) return;
    await _documentUseCases.trashDocument(current.id);
  }

  @override
  void dispose() {
    _documentUseCases.removeListener(notifyListeners);
    super.dispose();
  }
}
