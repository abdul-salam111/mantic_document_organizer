// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_assistant_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AiAssistantResponse _$AiAssistantResponseFromJson(Map<String, dynamic> json) =>
    _AiAssistantResponse(
      id: json['id'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      success: json['success'] as bool?,
    );

Map<String, dynamic> _$AiAssistantResponseToJson(
  _AiAssistantResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'success': instance.success,
};
