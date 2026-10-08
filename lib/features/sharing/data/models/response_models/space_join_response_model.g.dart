// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'space_join_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SpaceJoinResponseModel _$SpaceJoinResponseModelFromJson(
  Map<String, dynamic> json,
) => _SpaceJoinResponseModel(
  space: SpaceResponseModel.fromJson(json['space'] as Map<String, dynamic>),
  role: json['role'] as String,
);

Map<String, dynamic> _$SpaceJoinResponseModelToJson(
  _SpaceJoinResponseModel instance,
) => <String, dynamic>{'space': instance.space, 'role': instance.role};
