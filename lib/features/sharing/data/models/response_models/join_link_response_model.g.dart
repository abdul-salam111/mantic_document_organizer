// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_link_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JoinLinkResponseModel _$JoinLinkResponseModelFromJson(
  Map<String, dynamic> json,
) => _JoinLinkResponseModel(
  id: json['id'] as String,
  spaceId: json['space_id'] as String,
  role: json['role'] as String,
  token: json['token'] as String?,
  expiresAt: json['expires_at'] == null
      ? null
      : DateTime.parse(json['expires_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$JoinLinkResponseModelToJson(
  _JoinLinkResponseModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'space_id': instance.spaceId,
  'role': instance.role,
  'token': instance.token,
  'expires_at': instance.expiresAt?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
};
