import 'package:mantic_doc_org/features/categories/domain/entities/category_item.dart';
import 'package:mantic_doc_org/features/categories/domain/usecases/category_usecases.dart';
import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_usecases.dart';
import 'package:flutter/foundation.dart';

class SearchViewModel extends ChangeNotifier {
  final CategoryUseCases _categoryUseCases;
  final DocumentUseCases _documentUseCases;

  SearchViewModel({
    required CategoryUseCases categoryUseCases,
    required DocumentUseCases documentUseCases,
  }) : _categoryUseCases = categoryUseCases,
       _documentUseCases = documentUseCases {
    _categoryUseCases.addListener(notifyListeners);
    _documentUseCases.addListener(notifyListeners);
  }

  String _query = '';
  String get query => _query;

  void updateQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  bool isGridView = false;

  void setGridView(bool value) {
    if (isGridView == value) return;
    isGridView = value;
    notifyListeners();
  }

  DocumentSort _sort = DocumentSort.newest;
  DocumentSort get sort => _sort;

  void setSort(DocumentSort value) {
    if (_sort == value) return;
    _sort = value;
    notifyListeners();
  }

  static const String allCategoryTab = 'All';

  /// [allCategoryTab] first, then every category (alphabetically) — the
  /// same set Home's grid shows, not just categories that happen to have
  /// a document yet, so every category stays browsable from here too.
  List<String> get categoryTabs {
    final names = _categoryUseCases.categories.map((c) => c.name).toList()
      ..sort();
    return [allCategoryTab, ...names];
  }

  /// Documents in [category] (or every document, for [allCategoryTab]),
  /// further narrowed by the current search [query] if one's been typed.
  ///
  /// [category] is a display name (a tab label) — resolved back to its
  /// live [CategoryItem.id] here, on every call, rather than matching
  /// documents by name directly, so a rename doesn't drop documents out of
  /// their tab (the tab label and this resolution both read the same live
  /// [CategoryUseCases] in the same rebuild, so they never disagree).
  List<DocumentItem> documentsFor(String category) {
    final categoryId = category == allCategoryTab
        ? null
        : _categoryIdForName(category);
    final q = _query.trim().toLowerCase();
    final filtered = _documentUseCases.documents.where((d) {
      final matchesCategory =
          category == allCategoryTab || d.categoryId == categoryId;
      final matchesQuery =
          q.isEmpty ||
          d.title.toLowerCase().contains(q) ||
          d.category.toLowerCase().contains(q) ||
          d.tags.any((tag) => tag.contains(q)) ||
          d.description.toLowerCase().contains(q) ||
          d.ocrText.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();
    return filtered.sortedBy(_sort);
  }

  String? _categoryIdForName(String name) {
    for (final category in _categoryUseCases.categories) {
      if (category.name == name) return category.id;
    }
    return null;
  }

  Future<void> toggleFavorite(DocumentItem document) =>
      _documentUseCases.toggleFavorite(document);

  @override
  void dispose() {
    _categoryUseCases.removeListener(notifyListeners);
    _documentUseCases.removeListener(notifyListeners);
    super.dispose();
  }
}
