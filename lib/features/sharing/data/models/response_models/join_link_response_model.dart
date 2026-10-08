import 'package:freezed_annotation/freezed_annotation.dart';

part 'join_link_response_model.freezed.dart';
part 'join_link_response_model.g.dart';

@freezed
abstract class JoinLinkResponseModel with _$JoinLinkResponseModel {
  const factory JoinLinkResponseModel({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'space_id') required String spaceId,
    @JsonKey(name: 'role') required String role,
    // Only non-empty right after creation -- see JoinLinkEntity's doc.
    @JsonKey(name: 'token') String? token,
    @JsonKey(name: 'expires_at') DateTime? expiresAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _JoinLinkResponseModel;

  factory JoinLinkResponseModel.fromJson(Map<String, dynamic> json) =>
      _$JoinLinkResponseModelFromJson(json);
}
