import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_assistant_response.freezed.dart';
part 'ai_assistant_response.g.dart';

@freezed
abstract class AiAssistantResponse with _$AiAssistantResponse {
  const factory AiAssistantResponse({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'name') String? name,
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'success') bool? success,
  }) = _AiAssistantResponse;

  factory AiAssistantResponse.fromJson(Map<String, dynamic> json) =>
      _$AiAssistantResponseFromJson(json);
}
