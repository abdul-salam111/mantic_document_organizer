import '../../../../core/shared/shared_exports.dart';
import '../../domain/entities/join_link_entity.dart';
import '../../domain/entities/member_entity.dart';
import '../../domain/entities/pending_invitation_entity.dart';
import '../../domain/entities/space_entity.dart';
import '../../domain/entities/space_role.dart';
import '../../domain/repositories/sharing_repository.dart';
import '../datasources/remote_sharing_datasource.dart';
import '../models/response_models/invitation_response_model.dart';
import '../models/response_models/join_link_response_model.dart';
import '../models/response_models/member_response_model.dart';
import '../models/response_models/space_join_response_model.dart';
import '../models/response_models/space_response_model.dart';

class SharingRepositoryImpl extends BaseRepository
    implements ISharingRepository {
  final IRemoteSharingDataSource dataSource;

  SharingRepositoryImpl({required this.dataSource});

  @override
  Future<Result<SpaceEntity>> createSpace({
    required String token,
    required String name,
  }) => execute(
    call: () async =>
        _toSpaceEntity(await dataSource.createSpace(token: token, name: name)),
  );

  @override
  Future<Result<String>> createSpaceCategory({
    required String token,
    required String spaceId,
    required String name,
    String? iconKey,
    String? color,
  }) => execute(
    call: () => dataSource.createSpaceCategory(
      token: token,
      spaceId: spaceId,
      name: name,
      iconKey: iconKey,
      color: color,
    ),
  );

  @override
  Future<Result<List<MemberEntity>>> listMembers({
    required String token,
    required String spaceId,
  }) => execute(
    call: () async {
      final models = await dataSource.listMembers(
        token: token,
        spaceId: spaceId,
      );
      return [for (final model in models) _toMemberEntity(model)];
    },
  );

  @override
  Future<Result<void>> updateMemberRole({
    required String token,
    required String spaceId,
    required String userId,
    required SpaceRole role,
  }) => execute(
    call: () => dataSource.updateMemberRole(
      token: token,
      spaceId: spaceId,
      userId: userId,
      role: role.value,
    ),
  );

  @override
  Future<Result<void>> removeMember({
    required String token,
    required String spaceId,
    required String userId,
  }) => execute(
    call: () =>
        dataSource.removeMember(token: token, spaceId: spaceId, userId: userId),
  );

  @override
  Future<Result<PendingInvitationEntity>> inviteMember({
    required String token,
    required String spaceId,
    required String email,
    required SpaceRole role,
  }) => execute(
    call: () async => _toPendingInvitationEntity(
      await dataSource.inviteMember(
        token: token,
        spaceId: spaceId,
        email: email,
        role: role.value,
      ),
    ),
  );

  @override
  Future<Result<List<PendingInvitationEntity>>> listInvitations({
    required String token,
    required String spaceId,
  }) => execute(
    call: () async {
      final models = await dataSource.listInvitations(
        token: token,
        spaceId: spaceId,
      );
      return [for (final model in models) _toPendingInvitationEntity(model)];
    },
  );

  @override
  Future<Result<void>> revokeInvitation({
    required String token,
    required String spaceId,
    required String invitationId,
  }) => execute(
    call: () => dataSource.revokeInvitation(
      token: token,
      spaceId: spaceId,
      invitationId: invitationId,
    ),
  );

  @override
  Future<Result<({SpaceEntity space, SpaceRole role})>> acceptInvitation({
    required String token,
    required String invitationToken,
  }) => execute(
    call: () async => _toSpaceJoinResult(
      await dataSource.acceptInvitation(
        token: token,
        invitationToken: invitationToken,
      ),
    ),
  );

  @override
  Future<Result<JoinLinkEntity>> createJoinLink({
    required String token,
    required String spaceId,
    required SpaceRole role,
    int? expiresInDays,
  }) => execute(
    call: () async => _toJoinLinkEntity(
      await dataSource.createJoinLink(
        token: token,
        spaceId: spaceId,
        role: role.value,
        expiresInDays: expiresInDays,
      ),
    ),
  );

  @override
  Future<Result<List<JoinLinkEntity>>> listJoinLinks({
    required String token,
    required String spaceId,
  }) => execute(
    call: () async {
      final models = await dataSource.listJoinLinks(
        token: token,
        spaceId: spaceId,
      );
      return [for (final model in models) _toJoinLinkEntity(model)];
    },
  );

  @override
  Future<Result<void>> revokeJoinLink({
    required String token,
    required String spaceId,
    required String joinLinkId,
  }) => execute(
    call: () => dataSource.revokeJoinLink(
      token: token,
      spaceId: spaceId,
      joinLinkId: joinLinkId,
    ),
  );

  @override
  Future<Result<({SpaceEntity space, SpaceRole role})>> acceptJoinLink({
    required String token,
    required String joinLinkToken,
  }) => execute(
    call: () async => _toSpaceJoinResult(
      await dataSource.acceptJoinLink(
        token: token,
        joinLinkToken: joinLinkToken,
      ),
    ),
  );

  /// Maps FastAPI response DTOs at the data/domain boundary.
  SpaceEntity _toSpaceEntity(SpaceResponseModel model) => SpaceEntity(
    id: model.id,
    name: model.name,
    ownerId: model.ownerId,
    myRole: SpaceRole.tryFromValue(model.myRole),
  );

  MemberEntity _toMemberEntity(MemberResponseModel model) => MemberEntity(
    userId: model.userId,
    role: SpaceRole.fromValue(model.role),
    displayName: model.displayName,
    email: model.email,
    joinedAt: model.joinedAt,
  );

  PendingInvitationEntity _toPendingInvitationEntity(
    InvitationResponseModel model,
  ) => PendingInvitationEntity(
    id: model.id,
    spaceId: model.spaceId,
    invitedEmail: model.invitedEmail,
    role: SpaceRole.fromValue(model.role),
    expiresAt: model.expiresAt,
    createdAt: model.createdAt,
  );

  JoinLinkEntity _toJoinLinkEntity(JoinLinkResponseModel model) =>
      JoinLinkEntity(
        id: model.id,
        spaceId: model.spaceId,
        role: SpaceRole.fromValue(model.role),
        token: model.token,
        expiresAt: model.expiresAt,
        createdAt: model.createdAt,
      );

  ({SpaceEntity space, SpaceRole role}) _toSpaceJoinResult(
    SpaceJoinResponseModel model,
  ) => (space: _toSpaceEntity(model.space), role: SpaceRole.fromValue(model.role));
}
