import 'package:freezed_annotation/freezed_annotation.dart';

part 'member_response_model.freezed.dart';
part 'member_response_model.g.dart';

@freezed
abstract class MemberResponseModel with _$MemberResponseModel {
  const factory MemberResponseModel({
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'role') required String role,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'email') required String email,
    @JsonKey(name: 'joined_at') required DateTime joinedAt,
  }) = _MemberResponseModel;

  factory MemberResponseModel.fromJson(Map<String, dynamic> json) =>
      _$MemberResponseModelFromJson(json);
}
