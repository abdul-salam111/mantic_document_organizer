// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MemberResponseModel _$MemberResponseModelFromJson(Map<String, dynamic> json) =>
    _MemberResponseModel(
      userId: json['user_id'] as String,
      role: json['role'] as String,
      displayName: json['display_name'] as String,
      email: json['email'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );

Map<String, dynamic> _$MemberResponseModelToJson(
  _MemberResponseModel instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'role': instance.role,
  'display_name': instance.displayName,
  'email': instance.email,
  'joined_at': instance.joinedAt.toIso8601String(),
};
