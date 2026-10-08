import '../../../../core/shared/shared_exports.dart';
import '../entities/join_link_entity.dart';
import '../entities/member_entity.dart';
import '../entities/pending_invitation_entity.dart';
import '../entities/space_entity.dart';
import '../entities/space_role.dart';

abstract interface class ISharingRepository {
  Future<Result<SpaceEntity>> createSpace({
    required String token,
    required String name,
  });

  Future<Result<String>> createSpaceCategory({
    required String token,
    required String spaceId,
    required String name,
    String? iconKey,
    String? color,
  });

  Future<Result<List<MemberEntity>>> listMembers({
    required String token,
    required String spaceId,
  });

  Future<Result<void>> updateMemberRole({
    required String token,
    required String spaceId,
    required String userId,
    required SpaceRole role,
  });

  Future<Result<void>> removeMember({
    required String token,
    required String spaceId,
    required String userId,
  });

  Future<Result<PendingInvitationEntity>> inviteMember({
    required String token,
    required String spaceId,
    required String email,
    required SpaceRole role,
  });

  Future<Result<List<PendingInvitationEntity>>> listInvitations({
    required String token,
    required String spaceId,
  });

  Future<Result<void>> revokeInvitation({
    required String token,
    required String spaceId,
    required String invitationId,
  });

  Future<Result<({SpaceEntity space, SpaceRole role})>> acceptInvitation({
    required String token,
    required String invitationToken,
  });

  Future<Result<JoinLinkEntity>> createJoinLink({
    required String token,
    required String spaceId,
    required SpaceRole role,
    int? expiresInDays,
  });

  Future<Result<List<JoinLinkEntity>>> listJoinLinks({
    required String token,
    required String spaceId,
  });

  Future<Result<void>> revokeJoinLink({
    required String token,
    required String spaceId,
    required String joinLinkId,
  });

  Future<Result<({SpaceEntity space, SpaceRole role})>> acceptJoinLink({
    required String token,
    required String joinLinkToken,
  });
}
