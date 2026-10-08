import 'space_role.dart';

/// An email-targeted invitation the owner sent that hasn't been accepted,
/// revoked, or expired yet. The raw token never reaches the client here --
/// it only ever exists inside the invitation email itself.
class PendingInvitationEntity {
  final String id;
  final String spaceId;
  final String invitedEmail;
  final SpaceRole role;
  final DateTime expiresAt;
  final DateTime createdAt;

  const PendingInvitationEntity({
    required this.id,
    required this.spaceId,
    required this.invitedEmail,
    required this.role,
    required this.expiresAt,
    required this.createdAt,
  });
}
