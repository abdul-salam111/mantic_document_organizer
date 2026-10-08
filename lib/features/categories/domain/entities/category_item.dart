class CategoryItem {
  final String id;
  final String name;
  final String iconKey;
  final int? colorValue;
  // Null for a plain local-only category. Non-null means this category is
  // the one shared category for that backend space (see
  // docs/space_sharing_ux_plan.txt) -- myRole is the signed-in user's role
  // in it ("owner"/"editor"/"viewer"), mirroring the backend's SpaceRole.
  final String? spaceId;
  final String? myRole;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.iconKey,
    this.colorValue,
    this.spaceId,
    this.myRole,
  });

  bool get isShared => spaceId != null;

  CategoryItem copyWith({
    String? id,
    String? name,
    String? iconKey,
    int? colorValue,
    String? spaceId,
    String? myRole,
  }) => CategoryItem(
    id: id ?? this.id,
    name: name ?? this.name,
    iconKey: iconKey ?? this.iconKey,
    colorValue: colorValue ?? this.colorValue,
    spaceId: spaceId ?? this.spaceId,
    myRole: myRole ?? this.myRole,
  );
}
