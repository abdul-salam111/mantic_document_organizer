import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_assistant_params.freezed.dart';
part 'ai_assistant_params.g.dart';

@freezed
abstract class AiAssistantParams with _$AiAssistantParams {
  const factory AiAssistantParams({
    @JsonKey(name: 'param1') required String param1,
    @JsonKey(name: 'param2') required String param2,
  }) = _AiAssistantParams;

  factory AiAssistantParams.fromJson(Map<String, dynamic> json) =>
      _$AiAssistantParamsFromJson(json);
}
