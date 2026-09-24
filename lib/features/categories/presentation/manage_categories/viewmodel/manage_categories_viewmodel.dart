import 'package:flutter/material.dart';

import '../../../../home/home_exports.dart';

/// Presentation-only for now (see CLAUDE.md's "Known mismatches" section)
/// — just a thin listener over the shared [CategoryLocalStore]/
/// [DocumentLocalStore] so this screen's list (and each row's live
/// document count) stays in sync with categories/documents added or
/// edited elsewhere.
class ManageCategoriesViewModel extends ChangeNotifier {
  final CategoryLocalStore _categoryStore;
  final DocumentLocalStore _documentStore;

  ManageCategoriesViewModel({
    required CategoryLocalStore categoryStore,
    required DocumentLocalStore documentStore,
  }) : _categoryStore = categoryStore,
       _documentStore = documentStore {
    _categoryStore.addListener(notifyListeners);
    _documentStore.addListener(notifyListeners);
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
    final sorted = List<CategoryItem>.of(_categoryStore.categories)
      ..sort((a, b) => a.name.compareTo(b.name));
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return sorted;
    return sorted.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  void deleteCategory(CategoryItem category) {
    _categoryStore.removeCategory(category.id);
  }

  int documentCountFor(String categoryId) =>
      _documentStore.countForCategory(categoryId);

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

  void deleteSelected() {
    final ids = Set<String>.of(_selectedIds);
    // Clear first (no notify) so the store's single notification below
    // reflects both the shorter category list and the cleared selection
    // in one rebuild, instead of a stale-selection frame in between.
    _selectedIds.clear();
    _categoryStore.removeCategories(ids);
  }

  @override
  void dispose() {
    _categoryStore.removeListener(notifyListeners);
    _documentStore.removeListener(notifyListeners);
    super.dispose();
  }
}
