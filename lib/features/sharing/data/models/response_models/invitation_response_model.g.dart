// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InvitationResponseModel _$InvitationResponseModelFromJson(
  Map<String, dynamic> json,
) => _InvitationResponseModel(
  id: json['id'] as String,
  spaceId: json['space_id'] as String,
  invitedEmail: json['invited_email'] as String,
  role: json['role'] as String,
  expiresAt: DateTime.parse(json['expires_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$InvitationResponseModelToJson(
  _InvitationResponseModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'space_id': instance.spaceId,
  'invited_email': instance.invitedEmail,
  'role': instance.role,
  'expires_at': instance.expiresAt.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
};
