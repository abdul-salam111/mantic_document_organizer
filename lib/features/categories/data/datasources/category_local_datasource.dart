import '../../../../core/database/app_database.dart';
import '../../domain/entities/category_item.dart';

abstract interface class CategoryLocalDataSource {
  Future<List<CategoryItem>> fetchCategories();
  Future<void> seedBuiltInCategoriesIfEmpty(List<CategoryItem> items);
  Future<void> upsertCategory(CategoryItem item);
  Future<void> deleteCategory(String id);
  Future<void> deleteCategories(Iterable<String> ids);
}

class SqliteCategoryDataSource implements CategoryLocalDataSource {
  final AppDatabase _database;
  SqliteCategoryDataSource(this._database);
  @override
  Future<List<CategoryItem>> fetchCategories() => _database.fetchCategories();
  @override
  Future<void> seedBuiltInCategoriesIfEmpty(List<CategoryItem> items) =>
      _database.seedBuiltInCategoriesIfEmpty(items);
  @override
  Future<void> upsertCategory(CategoryItem item) =>
      _database.upsertCategory(item);
  @override
  Future<void> deleteCategory(String id) => _database.deleteCategory(id);
  @override
  Future<void> deleteCategories(Iterable<String> ids) =>
      _database.deleteCategories(ids);
}
