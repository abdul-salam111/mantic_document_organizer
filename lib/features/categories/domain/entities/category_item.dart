class CategoryItem {
  final String id;
  final String name;
  final String iconKey;
  final int? colorValue;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.iconKey,
    this.colorValue,
  });
}
