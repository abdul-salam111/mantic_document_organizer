import 'package:flutter/material.dart';

import '../../home/home_exports.dart';

/// Presentation-only for now (see CLAUDE.md's "Known mismatches" section)
/// — just a thin listener over the shared [CategoryLocalStore] so this
/// screen's list stays in sync with categories added/edited elsewhere.
class ManageCategoriesViewModel extends ChangeNotifier {
  final CategoryLocalStore _categoryStore;

  ManageCategoriesViewModel({required CategoryLocalStore categoryStore})
    : _categoryStore = categoryStore {
    _categoryStore.addListener(notifyListeners);
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
    _categoryStore.removeCategory(category.name);
  }

  // Long-press-to-select, keyed by name (categories have no separate id).
  final Set<String> _selectedNames = {};
  bool get isSelecting => _selectedNames.isNotEmpty;
  int get selectedCount => _selectedNames.length;
  bool isSelected(String name) => _selectedNames.contains(name);

  void toggleSelection(String name) {
    if (!_selectedNames.add(name)) _selectedNames.remove(name);
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedNames.isEmpty) return;
    _selectedNames.clear();
    notifyListeners();
  }

  void deleteSelected() {
    final names = Set<String>.of(_selectedNames);
    // Clear first (no notify) so the store's single notification below
    // reflects both the shorter category list and the cleared selection
    // in one rebuild, instead of a stale-selection frame in between.
    _selectedNames.clear();
    _categoryStore.removeCategories(names);
  }

  @override
  void dispose() {
    _categoryStore.removeListener(notifyListeners);
    super.dispose();
  }
}
