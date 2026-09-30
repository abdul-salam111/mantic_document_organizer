import 'package:mantic_doc_org/features/categories/domain/entities/category_item.dart';
import 'package:mantic_doc_org/features/categories/domain/usecases/category_usecases.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_usecases.dart';
import 'package:flutter/material.dart';

class ManageCategoriesViewModel extends ChangeNotifier {
  final CategoryUseCases _categoryUseCases;
  final DocumentUseCases _documentUseCases;

  ManageCategoriesViewModel({
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
    _query = value;
    notifyListeners();
  }

  /// Sorted alphabetically, matching HomeViewModel's category ordering,
  /// then narrowed by [query] (matches anywhere in the name, case-insensitive).
  List<CategoryItem> get categories {
    final sorted = List<CategoryItem>.of(_categoryUseCases.categories)
      ..sort((a, b) => a.name.compareTo(b.name));
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return sorted;
    return sorted.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  Future<void> deleteCategory(CategoryItem category) async {
    await _categoryUseCases.removeCategory(category.id);
  }

  int documentCountFor(String categoryId) =>
      _documentUseCases.countForCategory(categoryId);

  // Long-press-to-select, keyed by id.
  final Set<String> _selectedIds = {};
  bool get isSelecting => _selectedIds.isNotEmpty;
  int get selectedCount => _selectedIds.length;
  bool isSelected(String id) => _selectedIds.contains(id);

  void toggleSelection(String id) {
    if (!_selectedIds.add(id)) _selectedIds.remove(id);
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedIds.isEmpty) return;
    _selectedIds.clear();
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    final ids = Set<String>.of(_selectedIds);
    await _categoryUseCases.removeCategories(ids);
    _selectedIds.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _categoryUseCases.removeListener(notifyListeners);
    _documentUseCases.removeListener(notifyListeners);
    super.dispose();
  }
}
