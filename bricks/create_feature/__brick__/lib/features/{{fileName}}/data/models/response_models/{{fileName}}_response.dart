import 'package:freezed_annotation/freezed_annotation.dart';

part '{{fileName}}_response.freezed.dart';
part '{{fileName}}_response.g.dart';

@freezed
abstract class {{className}}Response with _${{className}}Response {
  const factory {{className}}Response({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'name') String? name,
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'success') bool? success,
  }) = _{{className}}Response;

  factory {{className}}Response.fromJson(Map<String, dynamic> json) =>
      _${{className}}ResponseFromJson(json);
}
