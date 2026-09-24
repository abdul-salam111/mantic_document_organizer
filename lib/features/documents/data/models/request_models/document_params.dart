import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_params.freezed.dart';
part 'document_params.g.dart';

@freezed
abstract class DocumentParams with _$DocumentParams {
  const factory DocumentParams({
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'description') String? description,
  }) = _DocumentParams;

  factory DocumentParams.fromJson(Map<String, dynamic> json) =>
      _$DocumentParamsFromJson(json);
}
