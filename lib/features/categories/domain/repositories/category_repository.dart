import '../entities/category_item.dart';

abstract interface class ICategoryRepository {
  void addListener(void Function() listener);
  void removeListener(void Function() listener);
  List<CategoryItem> get categories;
  Future<void> init();
  CategoryItem? byId(String id);
  bool exists(String name, {String? excludingId});
  Future<void> addCategory(CategoryItem category);
  Future<void> updateCategory(String id, CategoryItem updated);
  Future<void> removeCategory(String id);
  Future<void> removeCategories(Iterable<String> ids);
}
