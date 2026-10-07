import '../../../domain/entities/attachment_item.dart';
import '../../../domain/usecases/document_processing_usecases.dart';
import 'package:mantic_doc_org/features/categories/domain/entities/category_item.dart';
import 'package:mantic_doc_org/features/categories/domain/usecases/category_usecases.dart';
import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_usecases.dart';
import 'package:mantic_doc_org/features/documents/presentation/add_document/viewmodels/add_document_viewmodel.dart'
    show AttachmentSource;
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

  Future<void> shareFile(String path) => _processing.shareFile(path);

  Future<void> shareFiles(List<String> paths) => _processing.shareFiles(paths);
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

  // Long-press-a-page-to-select, keyed by path (not index — indices shift
  // as filePaths changes, paths don't).
  final Set<String> _selectedPaths = {};
  Set<String> get selectedPaths => Set.unmodifiable(_selectedPaths);
  bool get isSelecting => _selectedPaths.isNotEmpty;
  int get selectedCount => _selectedPaths.length;
  bool isSelected(String path) => _selectedPaths.contains(path);

  void toggleFileSelection(String path) {
    if (!_selectedPaths.add(path)) _selectedPaths.remove(path);
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedPaths.isEmpty) return;
    _selectedPaths.clear();
    notifyListeners();
  }

  /// Removes the selected pages from the document. If that would leave it
  /// with none, trashes the whole document instead of leaving a page-less
  /// one behind — same "the last page going away means the document goes
  /// away" rule scanner apps like CamScanner use. Callers can tell which
  /// happened from [selectedCount] vs. the document's filePaths length
  /// *before* calling this (it clears the selection itself).
  Future<void> deleteSelectedFiles() async {
    final current = document;
    if (current == null || _selectedPaths.isEmpty) return;
    final toRemove = Set<String>.of(_selectedPaths);
    _selectedPaths.clear();
    final remaining = current.filePaths
        .where((path) => !toRemove.contains(path))
        .toList();
    if (remaining.isEmpty) {
      await _documentUseCases.trashDocument(current.id);
    } else {
      await _documentUseCases.updateDocument(
        current.copyWith(filePaths: remaining),
      );
    }
    notifyListeners();
  }

  /// Picks new pages from [source] and appends them straight onto this
  /// document — no detour through the full Add Document form. Returns the
  /// raw [AttachmentSelection] so the caller can show the same
  /// scan-failed/skipped-images toasts [AddDocumentView]'s own pickers do;
  /// an empty selection just means the user cancelled the picker.
  Future<AttachmentSelection> addPages(AttachmentSource source) async {
    final selection = switch (source) {
      AttachmentSource.camera => await _processing.pickFromCamera(),
      AttachmentSource.gallery => await _processing.pickFromGallery(),
      AttachmentSource.file => await _processing.pickFile(),
    };
    final current = document;
    if (selection.items.isEmpty || current == null) return selection;

    final newTexts = <String>[];
    for (final item in selection.items) {
      final text = await _processing.extractText(item.path);
      if (text.trim().isNotEmpty) newTexts.add(text);
    }
    final mergedOcrText = [
      current.ocrText,
      ...newTexts,
    ].where((text) => text.trim().isNotEmpty).join('\n\n');

    await _documentUseCases.updateDocument(
      current.copyWith(
        filePaths: [
          ...current.filePaths,
          for (final item in selection.items) item.path,
        ],
        ocrText: mergedOcrText,
      ),
    );
    return selection;
  }

  @override
  void dispose() {
    _documentUseCases.removeListener(notifyListeners);
    super.dispose();
  }
}
