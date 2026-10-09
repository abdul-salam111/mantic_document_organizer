import 'package:flutter/foundation.dart';
import '../../domain/entities/builtin_categories.dart';
import '../../domain/entities/category_item.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_datasource.dart';

class CategoryRepositoryImpl extends ChangeNotifier
    implements ICategoryRepository {
  Future<void> _pending = Future.value();
  Future<void> _write(Future<void> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return result;
  }

  final CategoryLocalDataSource _db;

  CategoryRepositoryImpl(this._db);

  final List<CategoryItem> _categories = [];

  @override
  List<CategoryItem> get categories => List.unmodifiable(_categories);
  @override
  Future<void> init() async {
    await _db.seedBuiltInCategoriesIfEmpty(builtInCategories);
    _categories
      ..clear()
      ..addAll(await _db.fetchCategories());
    notifyListeners();
  }

  @override
  CategoryItem? byId(String id) {
    for (final category in _categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  @override
  bool exists(String name, {String? excludingId}) {
    final normalized = name.trim().toLowerCase();
    return _categories.any(
      (c) => c.name.toLowerCase() == normalized && c.id != excludingId,
    );
  }

  @override
  Future<void> addCategory(CategoryItem category) => _write(() async {
    await _db.upsertCategory(category);
    _categories.add(category);
    notifyListeners();
  });

  @override
  Future<void> updateCategory(String id, CategoryItem updated) =>
      _write(() async {
        final index = _categories.indexWhere((c) => c.id == id);
        if (index == -1) return;
        await _db.upsertCategory(updated);
        _categories[index] = updated;
        notifyListeners();
      });

  @override
  Future<void> removeCategory(String id) => _write(() async {
    await _db.deleteCategory(id);
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  });
  @override
  Future<void> removeCategories(Iterable<String> ids) => _write(() async {
    final idSet = ids.toSet();
    await _db.deleteCategories(idSet);
    _categories.removeWhere((c) => idSet.contains(c.id));
    notifyListeners();
  });
}
