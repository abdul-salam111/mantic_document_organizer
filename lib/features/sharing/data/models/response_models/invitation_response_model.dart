import 'package:freezed_annotation/freezed_annotation.dart';

part 'invitation_response_model.freezed.dart';
part 'invitation_response_model.g.dart';

@freezed
abstract class InvitationResponseModel with _$InvitationResponseModel {
  const factory InvitationResponseModel({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'space_id') required String spaceId,
    @JsonKey(name: 'invited_email') required String invitedEmail,
    @JsonKey(name: 'role') required String role,
    @JsonKey(name: 'expires_at') required DateTime expiresAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _InvitationResponseModel;

  factory InvitationResponseModel.fromJson(Map<String, dynamic> json) =>
      _$InvitationResponseModelFromJson(json);
}
