import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_params.freezed.dart';
part 'search_params.g.dart';

@freezed
abstract class SearchParams with _$SearchParams {
  const factory SearchParams({@JsonKey(name: 'query') required String query}) =
      _SearchParams;

  factory SearchParams.fromJson(Map<String, dynamic> json) =>
      _$SearchParamsFromJson(json);
}
