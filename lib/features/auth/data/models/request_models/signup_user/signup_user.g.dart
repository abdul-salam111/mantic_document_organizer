// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signup_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SignupUser _$SignupUserFromJson(Map<String, dynamic> json) => _SignupUser(
  name: json['display_name'] as String?,
  email: json['email'] as String?,
  password: json['password'] as String?,
);

Map<String, dynamic> _$SignupUserToJson(_SignupUser instance) =>
    <String, dynamic>{
      'display_name': instance.name,
      'email': instance.email,
      'password': instance.password,
    };
