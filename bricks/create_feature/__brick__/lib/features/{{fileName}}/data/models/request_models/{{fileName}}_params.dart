import 'package:freezed_annotation/freezed_annotation.dart';

part '{{fileName}}_params.freezed.dart';
part '{{fileName}}_params.g.dart';

@freezed
abstract class {{className}}Params with _${{className}}Params {
  const factory {{className}}Params({
    @JsonKey(name: 'param1') required String param1,
    @JsonKey(name: 'param2') required String param2,
  }) = _{{className}}Params;

  factory {{className}}Params.fromJson(Map<String, dynamic> json) =>
      _${{className}}ParamsFromJson(json);
}
