/// Mirrors the backend's `SpaceRole` (owner/editor/viewer), server-enforced
/// on every space/category/document/member/invitation endpoint -- hiding a
/// control in the UI for a Viewer is a courtesy, not the actual gate.
enum SpaceRole {
  owner('owner'),
  editor('editor'),
  viewer('viewer');

  final String value;
  const SpaceRole(this.value);

  static SpaceRole fromValue(String value) => switch (value) {
    'owner' => .owner,
    'editor' => .editor,
    'viewer' => .viewer,
    _ => throw ArgumentError('Unknown space role: $value'),
  };

  static SpaceRole? tryFromValue(String? value) =>
      value == null ? null : fromValue(value);
}
