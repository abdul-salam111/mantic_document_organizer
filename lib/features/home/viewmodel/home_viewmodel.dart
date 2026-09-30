import 'package:mantic_doc_org/features/categories/domain/entities/category_item.dart';
import 'package:mantic_doc_org/features/categories/domain/usecases/category_usecases.dart';
import 'package:mantic_doc_org/features/documents/domain/entities/document_item.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_usecases.dart';
import 'package:flutter/material.dart';

class HomeViewModel extends ChangeNotifier {
  final CategoryUseCases _categoryUseCases;
  final DocumentUseCases _documentUseCases;

  HomeViewModel({
    required CategoryUseCases categoryUseCases,
    required DocumentUseCases documentUseCases,
  }) : _categoryUseCases = categoryUseCases,
       _documentUseCases = documentUseCases {
    _categoryUseCases.addListener(notifyListeners);
    _documentUseCases.addListener(notifyListeners);
  }

  bool isGridView = true;

  void setGridView(bool gridView) {
    if (isGridView == gridView) return;
    isGridView = gridView;
    notifyListeners();
  }

  /// Sorted alphabetically regardless of source order below, so the
  /// display order stays correct as categories are added/renamed.
  List<CategoryItem> get categories =>
      List<CategoryItem>.of(_categoryUseCases.categories)
        ..sort((a, b) => a.name.compareTo(b.name));

  /// Live document count for a category (or [uncategorizedCategoryId]) —
  /// see [CategoryItem]'s doc comment for why this isn't a stored field.
  int documentCountFor(String categoryId) =>
      _documentUseCases.countForCategory(categoryId);

  /// Newest first, capped to a reasonable preview length for the
  /// horizontal strip — real documents only, no placeholder/dummy entries,
  /// so this is empty until something's actually been added.
  static const int _recentFilesLimit = 10;

  List<DocumentItem> get recentFiles =>
      _documentUseCases.documents.take(_recentFilesLimit).toList();

  Future<void> toggleFavorite(DocumentItem document) =>
      _documentUseCases.toggleFavorite(document);

  @override
  void dispose() {
    _categoryUseCases.removeListener(notifyListeners);
    _documentUseCases.removeListener(notifyListeners);
    super.dispose();
  }
}
