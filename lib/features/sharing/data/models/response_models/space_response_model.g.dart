// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'space_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SpaceResponseModel _$SpaceResponseModelFromJson(Map<String, dynamic> json) =>
    _SpaceResponseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['owner_id'] as String,
      myRole: json['my_role'] as String?,
    );

Map<String, dynamic> _$SpaceResponseModelToJson(_SpaceResponseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'owner_id': instance.ownerId,
      'my_role': instance.myRole,
    };
