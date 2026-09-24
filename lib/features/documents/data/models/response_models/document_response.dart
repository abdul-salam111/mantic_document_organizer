import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_response.freezed.dart';
part 'document_response.g.dart';

@freezed
abstract class DocumentResponse with _$DocumentResponse {
  const factory DocumentResponse({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'name') String? name,
    @JsonKey(name: 'description') String? description,
  }) = _DocumentResponse;

  factory DocumentResponse.fromJson(Map<String, dynamic> json) =>
      _$DocumentResponseFromJson(json);
}
