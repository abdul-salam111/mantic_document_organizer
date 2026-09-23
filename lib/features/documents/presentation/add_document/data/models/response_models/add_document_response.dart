import 'package:freezed_annotation/freezed_annotation.dart';

part 'add_document_response.freezed.dart';
part 'add_document_response.g.dart';

@freezed
abstract class AddDocumentResponse with _$AddDocumentResponse {
  const factory AddDocumentResponse({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'name') String? name,
    @JsonKey(name: 'description') String? description,
  }) = _AddDocumentResponse;

  factory AddDocumentResponse.fromJson(Map<String, dynamic> json) =>
      _$AddDocumentResponseFromJson(json);
}
