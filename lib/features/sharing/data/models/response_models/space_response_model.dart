import 'package:freezed_annotation/freezed_annotation.dart';

part 'space_response_model.freezed.dart';
part 'space_response_model.g.dart';

@freezed
abstract class SpaceResponseModel with _$SpaceResponseModel {
  const factory SpaceResponseModel({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'owner_id') required String ownerId,
    @JsonKey(name: 'my_role') String? myRole,
  }) = _SpaceResponseModel;

  factory SpaceResponseModel.fromJson(Map<String, dynamic> json) =>
      _$SpaceResponseModelFromJson(json);
}
