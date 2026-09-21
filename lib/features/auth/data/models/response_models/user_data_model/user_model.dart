import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    @JsonKey(name: "success") bool? success,
    @JsonKey(name: "data") UserData? data,
    @JsonKey(name: "message") String? message,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

@freezed
abstract class UserData with _$UserData {
  const factory UserData({
    @JsonKey(name: "id") int? id,
    @JsonKey(name: "acms_id") String? acmsId,
    @JsonKey(name: "user_category") String? userCategory,
    @JsonKey(name: "name") String? name,
    @JsonKey(name: "first_name") dynamic firstName,
    @JsonKey(name: "last_name") dynamic lastName,
    @JsonKey(name: "image") dynamic image,
    @JsonKey(name: "email") String? email,
    @JsonKey(name: "verify_email") int? verifyEmail,
    @JsonKey(name: "cnic") dynamic cnic,
    @JsonKey(name: "phone") dynamic phone,
    @JsonKey(name: "address") dynamic address,
    @JsonKey(name: "present_address") String? presentAddress,
    @JsonKey(name: "country_id") dynamic countryId,
    @JsonKey(name: "state_id") dynamic stateId,
    @JsonKey(name: "city_id") dynamic cityId,
    @JsonKey(name: "zip") dynamic zip,
    @JsonKey(name: "status") int? status,
    @JsonKey(name: "app_form") int? appForm,
    @JsonKey(name: "app_form_approved") int? appFormApproved,
    @JsonKey(name: "token") String? token,
  }) = _UserData;

  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);
}
