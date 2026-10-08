import '../../../../core/shared/shared_exports.dart';
import '../entities/join_link_entity.dart';
import '../entities/member_entity.dart';
import '../entities/pending_invitation_entity.dart';
import '../entities/space_entity.dart';
import '../entities/space_role.dart';
import '../repositories/sharing_repository.dart';

class CreateSpaceUsecase
    implements Usecase<SpaceEntity, ({String token, String name})> {
  final ISharingRepository repository;
  CreateSpaceUsecase(this.repository);
  @override
  Future<Result<SpaceEntity>> call(({String token, String name}) params) =>
      repository.createSpace(token: params.token, name: params.name);
}

/// Creates a space and its one category together, so a caller doesn't need
/// to sequence two repository calls itself -- see ShareCategoryUsecase in
/// the categories feature, which is the only intended caller of this.
class CreateSpaceCategoryUsecase
    implements
        Usecase<
          String,
          ({
            String token,
            String spaceId,
            String name,
            String? iconKey,
            String? color,
          })
        > {
  final ISharingRepository repository;
  CreateSpaceCategoryUsecase(this.repository);
  @override
  Future<Result<String>> call(
    ({
      String token,
      String spaceId,
      String name,
      String? iconKey,
      String? color,
    })
    params,
  ) => repository.createSpaceCategory(
    token: params.token,
    spaceId: params.spaceId,
    name: params.name,
    iconKey: params.iconKey,
    color: params.color,
  );
}

class ListMembersUsecase
    implements
        Usecase<List<MemberEntity>, ({String token, String spaceId})> {
  final ISharingRepository repository;
  ListMembersUsecase(this.repository);
  @override
  Future<Result<List<MemberEntity>>> call(
    ({String token, String spaceId}) params,
  ) => repository.listMembers(token: params.token, spaceId: params.spaceId);
}

class UpdateMemberRoleUsecase
    implements
        Usecase<
          void,
          ({String token, String spaceId, String userId, SpaceRole role})
        > {
  final ISharingRepository repository;
  UpdateMemberRoleUsecase(this.repository);
  @override
  Future<Result<void>> call(
    ({String token, String spaceId, String userId, SpaceRole role}) params,
  ) => repository.updateMemberRole(
    token: params.token,
    spaceId: params.spaceId,
    userId: params.userId,
    role: params.role,
  );
}

class RemoveMemberUsecase
    implements
        Usecase<void, ({String token, String spaceId, String userId})> {
  final ISharingRepository repository;
  RemoveMemberUsecase(this.repository);
  @override
  Future<Result<void>> call(
    ({String token, String spaceId, String userId}) params,
  ) => repository.removeMember(
    token: params.token,
    spaceId: params.spaceId,
    userId: params.userId,
  );
}

class InviteMemberUsecase
    implements
        Usecase<
          PendingInvitationEntity,
          ({String token, String spaceId, String email, SpaceRole role})
        > {
  final ISharingRepository repository;
  InviteMemberUsecase(this.repository);
  @override
  Future<Result<PendingInvitationEntity>> call(
    ({String token, String spaceId, String email, SpaceRole role}) params,
  ) => repository.inviteMember(
    token: params.token,
    spaceId: params.spaceId,
    email: params.email,
    role: params.role,
  );
}

class ListInvitationsUsecase
    implements
        Usecase<
          List<PendingInvitationEntity>,
          ({String token, String spaceId})
        > {
  final ISharingRepository repository;
  ListInvitationsUsecase(this.repository);
  @override
  Future<Result<List<PendingInvitationEntity>>> call(
    ({String token, String spaceId}) params,
  ) => repository.listInvitations(token: params.token, spaceId: params.spaceId);
}

class RevokeInvitationUsecase
    implements
        Usecase<void, ({String token, String spaceId, String invitationId})> {
  final ISharingRepository repository;
  RevokeInvitationUsecase(this.repository);
  @override
  Future<Result<void>> call(
    ({String token, String spaceId, String invitationId}) params,
  ) => repository.revokeInvitation(
    token: params.token,
    spaceId: params.spaceId,
    invitationId: params.invitationId,
  );
}

class AcceptInvitationUsecase
    implements
        Usecase<
          ({SpaceEntity space, SpaceRole role}),
          ({String token, String invitationToken})
        > {
  final ISharingRepository repository;
  AcceptInvitationUsecase(this.repository);
  @override
  Future<Result<({SpaceEntity space, SpaceRole role})>> call(
    ({String token, String invitationToken}) params,
  ) => repository.acceptInvitation(
    token: params.token,
    invitationToken: params.invitationToken,
  );
}

class CreateJoinLinkUsecase
    implements
        Usecase<
          JoinLinkEntity,
          ({String token, String spaceId, SpaceRole role, int? expiresInDays})
        > {
  final ISharingRepository repository;
  CreateJoinLinkUsecase(this.repository);
  @override
  Future<Result<JoinLinkEntity>> call(
    ({String token, String spaceId, SpaceRole role, int? expiresInDays})
    params,
  ) => repository.createJoinLink(
    token: params.token,
    spaceId: params.spaceId,
    role: params.role,
    expiresInDays: params.expiresInDays,
  );
}

class ListJoinLinksUsecase
    implements
        Usecase<List<JoinLinkEntity>, ({String token, String spaceId})> {
  final ISharingRepository repository;
  ListJoinLinksUsecase(this.repository);
  @override
  Future<Result<List<JoinLinkEntity>>> call(
    ({String token, String spaceId}) params,
  ) => repository.listJoinLinks(token: params.token, spaceId: params.spaceId);
}

class RevokeJoinLinkUsecase
    implements
        Usecase<void, ({String token, String spaceId, String joinLinkId})> {
  final ISharingRepository repository;
  RevokeJoinLinkUsecase(this.repository);
  @override
  Future<Result<void>> call(
    ({String token, String spaceId, String joinLinkId}) params,
  ) => repository.revokeJoinLink(
    token: params.token,
    spaceId: params.spaceId,
    joinLinkId: params.joinLinkId,
  );
}

class AcceptJoinLinkUsecase
    implements
        Usecase<
          ({SpaceEntity space, SpaceRole role}),
          ({String token, String joinLinkToken})
        > {
  final ISharingRepository repository;
  AcceptJoinLinkUsecase(this.repository);
  @override
  Future<Result<({SpaceEntity space, SpaceRole role})>> call(
    ({String token, String joinLinkToken}) params,
  ) => repository.acceptJoinLink(
    token: params.token,
    joinLinkToken: params.joinLinkToken,
  );
}
