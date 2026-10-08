import 'package:freezed_annotation/freezed_annotation.dart';

import 'space_response_model.dart';

part 'space_join_response_model.freezed.dart';
part 'space_join_response_model.g.dart';

/// What an accept-invitation/accept-join-link call returns: the space just
/// joined, and the role actually granted (an Owner accepting their own
/// space's link stays Owner -- see the backend's `_join_space` guard).
@freezed
abstract class SpaceJoinResponseModel with _$SpaceJoinResponseModel {
  const factory SpaceJoinResponseModel({
    @JsonKey(name: 'space') required SpaceResponseModel space,
    @JsonKey(name: 'role') required String role,
  }) = _SpaceJoinResponseModel;

  factory SpaceJoinResponseModel.fromJson(Map<String, dynamic> json) =>
      _$SpaceJoinResponseModelFromJson(json);
}
