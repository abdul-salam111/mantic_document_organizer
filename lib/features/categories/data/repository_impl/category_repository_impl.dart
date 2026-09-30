import 'package:flutter/foundation.dart';
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

  static const List<CategoryItem> _builtInCategories = [
    CategoryItem(id: 'bank', name: 'Bank', iconKey: 'buildingColumns'),
    CategoryItem(
      id: 'business_card',
      name: 'Business Card',
      // solidAddressCard, not addressCard — the picker catalog only
      // carries solid-style icons (see icon_catalog.dart), and addressCard
      // is only available there as its solid variant.
      iconKey: 'solidAddressCard',
    ),
    CategoryItem(id: 'contracts', name: 'Contracts', iconKey: 'fileContract'),
    CategoryItem(
      id: 'driving_license',
      name: 'Driving License',
      iconKey: 'idCardClip',
    ),
    CategoryItem(id: 'education', name: 'Education', iconKey: 'graduationCap'),
    CategoryItem(
      id: 'electricity_gas',
      name: 'Electricity/Gas',
      iconKey: 'boltLightning',
    ),
    CategoryItem(
      id: 'id_card',
      name: 'ID Card',
      // solidIdCard, not idCard — see the business_card entry above.
      iconKey: 'solidIdCard',
    ),
    CategoryItem(id: 'insurance', name: 'Insurance', iconKey: 'shieldHalved'),
    CategoryItem(id: 'invoices', name: 'Invoices', iconKey: 'fileInvoice'),
    CategoryItem(id: 'medical', name: 'Medical', iconKey: 'stethoscope'),
    CategoryItem(id: 'passports', name: 'Passports', iconKey: 'passport'),
    CategoryItem(id: 'products', name: 'Products', iconKey: 'boxesStacked'),
    CategoryItem(
      id: 'tax_documents',
      name: 'Tax Documents',
      iconKey: 'fileInvoiceDollar',
    ),
    CategoryItem(id: 'tickets', name: 'Tickets', iconKey: 'ticket'),
  ];

  final List<CategoryItem> _categories = [];

  @override
  List<CategoryItem> get categories => List.unmodifiable(_categories);
  @override
  Future<void> init() async {
    await _db.seedBuiltInCategoriesIfEmpty(_builtInCategories);
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
