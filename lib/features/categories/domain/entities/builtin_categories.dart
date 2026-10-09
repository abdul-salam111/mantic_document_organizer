import 'category_item.dart';

/// The 13 categories shipped with the app, identical for every install --
/// never uploaded as a backend `categories` row (see
/// docs/adr/0002-global-builtin-categories.md in the backend repo). The
/// backend ships the exact same list, keyed by the same ids, in
/// app/modules/spaces/builtin_categories.py -- keep both in lock-step.
const List<CategoryItem> builtInCategories = [
  CategoryItem(
    id: 'bank',
    name: 'Bank',
    iconKey: 'buildingColumns',
    colorValue: 0xFF4CAF50,
  ),
  CategoryItem(
    id: 'business_card',
    name: 'Business Card',
    iconKey: 'solidAddressCard',
    colorValue: 0xFF3B82F6,
  ),
  CategoryItem(
    id: 'contracts',
    name: 'Contracts',
    iconKey: 'fileContract',
    colorValue: 0xFF3927AD,
  ),
  CategoryItem(
    id: 'driving_license',
    name: 'Driving License',
    iconKey: 'idCardClip',
    colorValue: 0xFF197DCA,
  ),
  CategoryItem(
    id: 'education',
    name: 'Education',
    iconKey: 'graduationCap',
    colorValue: 0xFFC5B5E8,
  ),
  CategoryItem(
    id: 'electricity_gas',
    name: 'Electricity/Gas',
    iconKey: 'boltLightning',
    colorValue: 0xFFFFC542,
  ),
  CategoryItem(
    id: 'id_card',
    name: 'ID Card',
    iconKey: 'solidIdCard',
    colorValue: 0xFF197DCA,
  ),
  CategoryItem(
    id: 'insurance',
    name: 'Insurance',
    iconKey: 'shieldHalved',
    colorValue: 0xFF5B47C9,
  ),
  CategoryItem(
    id: 'invoices',
    name: 'Invoices',
    iconKey: 'fileInvoice',
    colorValue: 0xFFFFC542,
  ),
  CategoryItem(
    id: 'medical',
    name: 'Medical',
    iconKey: 'stethoscope',
    colorValue: 0xFFAB2017,
  ),
  CategoryItem(
    id: 'passports',
    name: 'Passports',
    iconKey: 'passport',
    colorValue: 0xFF197DCA,
  ),
  CategoryItem(
    id: 'products',
    name: 'Products',
    iconKey: 'boxesStacked',
    colorValue: 0xFF5B47C9,
  ),
  CategoryItem(
    id: 'tax_documents',
    name: 'Tax Documents',
    iconKey: 'fileInvoiceDollar',
    colorValue: 0xFF4CAF50,
  ),
  CategoryItem(
    id: 'tickets',
    name: 'Tickets',
    iconKey: 'ticket',
    colorValue: 0xFF3B82F6,
  ),
];

final Map<String, CategoryItem> _builtInCategoriesById = {
  for (final category in builtInCategories) category.id: category,
};

bool isBuiltInCategoryId(String id) => _builtInCategoriesById.containsKey(id);

/// The shipped default for a built-in id, or null if [id] isn't one.
CategoryItem? builtInCategoryDefault(String id) => _builtInCategoriesById[id];

/// True once a built-in has been renamed/recolored/re-iconed away from its
/// shipped default -- the trigger for promoting it into a real, synced
/// category the next time this device syncs. See Phase 2 of
/// docs/adr/0002-global-builtin-categories.md in the backend repo. A local
/// comparison against the fixed default, not stored state: it stays
/// correct for as long as [category] exists, with nothing to go stale.
bool builtInCategoryDivergesFromDefault(CategoryItem category) {
  final default_ = _builtInCategoriesById[category.id];
  if (default_ == null) return false;
  return category.name != default_.name ||
      category.iconKey != default_.iconKey ||
      category.colorValue != default_.colorValue;
}
