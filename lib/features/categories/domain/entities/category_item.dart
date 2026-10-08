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

  /// A Viewer can see this category's documents but never add/edit/delete
  /// them, move documents into it, or rename/delete the category itself --
  /// enforced server-side; this is only for client-side UI gating (hiding
  /// actions, excluding this category from a destination picker). Compares
  /// the raw string rather than importing the sharing feature's `SpaceRole`
  /// enum, keeping this entity decoupled from sharing entirely (see the
  /// doc comment above on [myRole]).
  bool get isViewerOnly => myRole == 'viewer';

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
