import 'space_role.dart';

/// A shared space -- one per shared category (see
/// docs/space_sharing_ux_plan.txt). Domain-layer shape, decoupled from the
/// backend's `SpaceResponse` JSON (mapped at the repository boundary).
class SpaceEntity {
  final String id;
  final String name;
  final String ownerId;
  final SpaceRole? myRole;

  const SpaceEntity({
    required this.id,
    required this.name,
    required this.ownerId,
    this.myRole,
  });
}
