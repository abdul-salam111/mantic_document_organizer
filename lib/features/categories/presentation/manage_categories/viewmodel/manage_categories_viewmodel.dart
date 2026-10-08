import 'package:mantic_doc_org/features/categories/domain/entities/category_item.dart';
import 'package:mantic_doc_org/features/categories/domain/usecases/category_usecases.dart';
import 'package:mantic_doc_org/features/documents/domain/usecases/document_usecases.dart';
import 'package:flutter/material.dart';

import '../../../../sharing/domain/usecases/member_count_cache.dart';

class ManageCategoriesViewModel extends ChangeNotifier {
  final CategoryUseCases _categoryUseCases;
  final DocumentUseCases _documentUseCases;
  final MemberCountCache _memberCountCache;

  ManageCategoriesViewModel({
    required CategoryUseCases categoryUseCases,
    required DocumentUseCases documentUseCases,
    required MemberCountCache memberCountCache,
  }) : _categoryUseCases = categoryUseCases,
       _documentUseCases = documentUseCases,
       _memberCountCache = memberCountCache {
    _categoryUseCases.addListener(notifyListeners);
    _documentUseCases.addListener(notifyListeners);
    _memberCountCache.addListener(notifyListeners);
  }

  /// Null while the count hasn't arrived yet -- callers show a plain badge
  /// with no number until then rather than blocking the row on it. See
  /// MemberCountCache for why this is a shared cache rather than per-row
  /// state (Home's category tiles show the same badge for the same spaces).
  int? memberCountFor(CategoryItem category) {
    final spaceId = category.spaceId;
    return spaceId == null ? null : _memberCountCache.countFor(spaceId);
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
    _memberCountCache.removeListener(notifyListeners);
    super.dispose();
  }
}
