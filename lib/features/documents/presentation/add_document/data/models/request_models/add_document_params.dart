import 'package:freezed_annotation/freezed_annotation.dart';

part 'add_document_params.freezed.dart';
part 'add_document_params.g.dart';

@freezed
abstract class AddDocumentParams with _$AddDocumentParams {
  const factory AddDocumentParams({
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'description') String? description,
  }) = _AddDocumentParams;

  factory AddDocumentParams.fromJson(Map<String, dynamic> json) =>
      _$AddDocumentParamsFromJson(json);
}
