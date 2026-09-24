import 'package:flutter/foundation.dart';

import '../../../../../../home/home_exports.dart';

/// No real document data layer exists yet (see CLAUDE.md's "Known
/// mismatches" section) — this reads straight from the shared
/// [DocumentLocalStore] (also used by HomeViewModel/AddDocumentViewModel)
/// and filters to whichever [CategoryItem] the screen was opened for,
/// matched by [CategoryItem.id]/[DocumentItem.categoryId] so a category
/// rename doesn't orphan its documents.
class CategoryDocumentsViewModel extends ChangeNotifier {
  final DocumentLocalStore _documentStore;

  CategoryDocumentsViewModel({required DocumentLocalStore documentStore})
    : _documentStore = documentStore {
    _documentStore.addListener(notifyListeners);
  }

  late final CategoryItem _category;
  CategoryItem get category => _category;

  /// Called once from the view's `ChangeNotifierProvider.create`, before
  /// the first frame — mirrors AddCategoryViewModel.startEditing.
  void init(CategoryItem category) {
    _category = category;
  }

  String _query = '';
  String get query => _query;

  void updateQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  DocumentSort _sort = DocumentSort.newest;
  DocumentSort get sort => _sort;

  void setSort(DocumentSort value) {
    if (_sort == value) return;
    _sort = value;
    notifyListeners();
  }

  /// All documents in this category, regardless of the current search
  /// query — used for the header count so it doesn't shrink while typing.
  List<DocumentItem> get allDocuments => _documentStore.documents
      .where((d) => d.categoryId == _category.id)
      .toList();

  List<DocumentItem> get documents {
    final q = _query.trim().toLowerCase();
    final filtered = allDocuments.where((d) {
      if (q.isEmpty) return true;
      return d.title.toLowerCase().contains(q) ||
          d.tags.any((tag) => tag.contains(q));
    }).toList();
    return filtered.sortedBy(_sort);
  }

  void toggleFavorite(DocumentItem document) =>
      _documentStore.toggleFavorite(document);

  @override
  void dispose() {
    _documentStore.removeListener(notifyListeners);
    super.dispose();
  }
}
