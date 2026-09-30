import '../entities/category_item.dart';
import '../repositories/category_repository.dart';

class CategoryUseCases {
  final ICategoryRepository _repository;
  CategoryUseCases(this._repository);
  void addListener(void Function() listener) =>
      _repository.addListener(listener);
  void removeListener(void Function() listener) =>
      _repository.removeListener(listener);
  List<CategoryItem> get categories => _repository.categories;
  Future<void> init() => _repository.init();
  CategoryItem? byId(String id) => _repository.byId(id);
  bool exists(String name, {String? excludingId}) =>
      _repository.exists(name, excludingId: excludingId);
  Future<void> addCategory(CategoryItem category) =>
      _repository.addCategory(category);
  Future<void> updateCategory(String id, CategoryItem updated) =>
      _repository.updateCategory(id, updated);
  Future<void> removeCategory(String id) => _repository.removeCategory(id);
  Future<void> removeCategories(Iterable<String> ids) =>
      _repository.removeCategories(ids);
}
