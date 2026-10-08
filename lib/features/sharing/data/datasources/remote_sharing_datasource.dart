import '../../../../core/constants/constants_exports.dart';
import '../../../../core/shared/shared_exports.dart';
import '../models/response_models/invitation_response_model.dart';
import '../models/response_models/join_link_response_model.dart';
import '../models/response_models/member_response_model.dart';
import '../models/response_models/space_join_response_model.dart';
import '../models/response_models/space_response_model.dart';

abstract interface class IRemoteSharingDataSource {
  Future<SpaceResponseModel> createSpace({
    required String token,
    required String name,
  });

  /// Returns the new category's remote id -- callers only need this to
  /// seed the existing document-sync engine's category mapping, not a
  /// full category shape.
  Future<String> createSpaceCategory({
    required String token,
    required String spaceId,
    required String name,
    String? iconKey,
    String? color,
  });

  Future<List<MemberResponseModel>> listMembers({
    required String token,
    required String spaceId,
  });

  Future<void> updateMemberRole({
    required String token,
    required String spaceId,
    required String userId,
    required String role,
  });

  Future<void> removeMember({
    required String token,
    required String spaceId,
    required String userId,
  });

  Future<InvitationResponseModel> inviteMember({
    required String token,
    required String spaceId,
    required String email,
    required String role,
  });

  Future<List<InvitationResponseModel>> listInvitations({
    required String token,
    required String spaceId,
  });

  Future<void> revokeInvitation({
    required String token,
    required String spaceId,
    required String invitationId,
  });

  Future<SpaceJoinResponseModel> acceptInvitation({
    required String token,
    required String invitationToken,
  });

  Future<JoinLinkResponseModel> createJoinLink({
    required String token,
    required String spaceId,
    required String role,
    int? expiresInDays,
  });

  Future<List<JoinLinkResponseModel>> listJoinLinks({
    required String token,
    required String spaceId,
  });

  Future<void> revokeJoinLink({
    required String token,
    required String spaceId,
    required String joinLinkId,
  });

  Future<SpaceJoinResponseModel> acceptJoinLink({
    required String token,
    required String joinLinkToken,
  });
}

class RemoteSharingDataSourceImpl extends BaseRemoteDatasource
    implements IRemoteSharingDataSource {
  RemoteSharingDataSourceImpl({required super.dioHelper});

  @override
  Future<SpaceResponseModel> createSpace({
    required String token,
    required String name,
  }) => post(
    url: ApiEndPoints.spaces,
    authToken: token,
    body: {'name': name},
    parser: (json) => SpaceResponseModel.fromJson(Map<String, dynamic>.from(json as Map)),
  );

  @override
  Future<String> createSpaceCategory({
    required String token,
    required String spaceId,
    required String name,
    String? iconKey,
    String? color,
  }) => post(
    url: '${ApiEndPoints.spaces}/$spaceId/categories',
    authToken: token,
    body: {'name': name, 'icon_key': iconKey, 'color': color},
    parser: (json) => (json as Map)['id'] as String,
  );

  @override
  Future<List<MemberResponseModel>> listMembers({
    required String token,
    required String spaceId,
  }) => getList(
    url: '${ApiEndPoints.spaces}/$spaceId/members',
    authToken: token,
    parser: (json) => MemberResponseModel.fromJson(Map<String, dynamic>.from(json as Map)),
  );

  @override
  Future<void> updateMemberRole({
    required String token,
    required String spaceId,
    required String userId,
    required String role,
  }) => patch(
    url: '${ApiEndPoints.spaces}/$spaceId/members/$userId',
    authToken: token,
    body: {'role': role},
    parser: (_) {},
  );

  @override
  Future<void> removeMember({
    required String token,
    required String spaceId,
    required String userId,
  }) => delete(
    url: '${ApiEndPoints.spaces}/$spaceId/members/$userId',
    authToken: token,
    parser: (_) {},
  );

  @override
  Future<InvitationResponseModel> inviteMember({
    required String token,
    required String spaceId,
    required String email,
    required String role,
  }) => post(
    url: '${ApiEndPoints.spaces}/$spaceId/invitations',
    authToken: token,
    body: {'email': email, 'role': role},
    parser: (json) => InvitationResponseModel.fromJson(Map<String, dynamic>.from(json as Map)),
  );

  @override
  Future<List<InvitationResponseModel>> listInvitations({
    required String token,
    required String spaceId,
  }) => getList(
    url: '${ApiEndPoints.spaces}/$spaceId/invitations',
    authToken: token,
    parser: (json) => InvitationResponseModel.fromJson(Map<String, dynamic>.from(json as Map)),
  );

  @override
  Future<void> revokeInvitation({
    required String token,
    required String spaceId,
    required String invitationId,
  }) => delete(
    url: '${ApiEndPoints.spaces}/$spaceId/invitations/$invitationId',
    authToken: token,
    parser: (_) {},
  );

  @override
  Future<SpaceJoinResponseModel> acceptInvitation({
    required String token,
    required String invitationToken,
  }) => post(
    url: ApiEndPoints.acceptInvitation,
    authToken: token,
    body: {'token': invitationToken},
    parser: (json) => SpaceJoinResponseModel.fromJson(Map<String, dynamic>.from(json as Map)),
  );

  @override
  Future<JoinLinkResponseModel> createJoinLink({
    required String token,
    required String spaceId,
    required String role,
    int? expiresInDays,
  }) => post(
    url: '${ApiEndPoints.spaces}/$spaceId/join-links',
    authToken: token,
    body: {'role': role, 'expires_in_days': expiresInDays},
    parser: (json) => JoinLinkResponseModel.fromJson(Map<String, dynamic>.from(json as Map)),
  );

  @override
  Future<List<JoinLinkResponseModel>> listJoinLinks({
    required String token,
    required String spaceId,
  }) => getList(
    url: '${ApiEndPoints.spaces}/$spaceId/join-links',
    authToken: token,
    parser: (json) => JoinLinkResponseModel.fromJson(Map<String, dynamic>.from(json as Map)),
  );

  @override
  Future<void> revokeJoinLink({
    required String token,
    required String spaceId,
    required String joinLinkId,
  }) => delete(
    url: '${ApiEndPoints.spaces}/$spaceId/join-links/$joinLinkId',
    authToken: token,
    parser: (_) {},
  );

  @override
  Future<SpaceJoinResponseModel> acceptJoinLink({
    required String token,
    required String joinLinkToken,
  }) => post(
    url: ApiEndPoints.acceptJoinLink,
    authToken: token,
    body: {'token': joinLinkToken},
    parser: (json) => SpaceJoinResponseModel.fromJson(Map<String, dynamic>.from(json as Map)),
  );
}
