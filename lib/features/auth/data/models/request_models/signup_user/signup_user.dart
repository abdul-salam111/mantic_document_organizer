import 'package:freezed_annotation/freezed_annotation.dart';

part 'signup_user.freezed.dart';
part 'signup_user.g.dart';

@freezed
abstract class SignupUser with _$SignupUser {
  const factory SignupUser({
    @JsonKey(name: "name") String? name,
    @JsonKey(name: "email") String? email,
    @JsonKey(name: "password") String? password,
  }) = _SignupUser;

  factory SignupUser.fromJson(Map<String, dynamic> json) =>
      _$SignupUserFromJson(json);
}
