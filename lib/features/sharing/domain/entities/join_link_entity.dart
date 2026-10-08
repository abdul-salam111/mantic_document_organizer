import 'space_role.dart';

/// The open, reusable "anyone with this link/QR can join" mechanism (see
/// docs/space_sharing_ux_plan.txt). [token] is the raw, shareable token --
/// only ever present right after creation (the backend stores only its
/// hash, so a listing can't show it again).
class JoinLinkEntity {
  final String id;
  final String spaceId;
  final SpaceRole role;
  final String? token;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const JoinLinkEntity({
    required this.id,
    required this.spaceId,
    required this.role,
    this.token,
    this.expiresAt,
    required this.createdAt,
  });
}
