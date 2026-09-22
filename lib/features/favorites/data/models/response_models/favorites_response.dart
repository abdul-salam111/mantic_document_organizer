import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorites_response.freezed.dart';
part 'favorites_response.g.dart';

@freezed
abstract class FavoritesResponse with _$FavoritesResponse {
  const factory FavoritesResponse({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'name') String? name,
    @JsonKey(name: 'description') String? description,
  }) = _FavoritesResponse;

  factory FavoritesResponse.fromJson(Map<String, dynamic> json) =>
      _$FavoritesResponseFromJson(json);
}
