// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserModel _$UserModelFromJson(Map<String, dynamic> json) => _UserModel(
  success: json['success'] as bool?,
  data: json['data'] == null
      ? null
      : UserData.fromJson(json['data'] as Map<String, dynamic>),
  message: json['message'] as String?,
);

Map<String, dynamic> _$UserModelToJson(_UserModel instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'message': instance.message,
    };

_UserData _$UserDataFromJson(Map<String, dynamic> json) => _UserData(
  id: (json['id'] as num?)?.toInt(),
  acmsId: json['acms_id'] as String?,
  userCategory: json['user_category'] as String?,
  name: json['name'] as String?,
  firstName: json['first_name'],
  lastName: json['last_name'],
  image: json['image'],
  email: json['email'] as String?,
  verifyEmail: (json['verify_email'] as num?)?.toInt(),
  cnic: json['cnic'],
  phone: json['phone'],
  address: json['address'],
  presentAddress: json['present_address'] as String?,
  countryId: json['country_id'],
  stateId: json['state_id'],
  cityId: json['city_id'],
  zip: json['zip'],
  status: (json['status'] as num?)?.toInt(),
  appForm: (json['app_form'] as num?)?.toInt(),
  appFormApproved: (json['app_form_approved'] as num?)?.toInt(),
  token: json['token'] as String?,
);

Map<String, dynamic> _$UserDataToJson(_UserData instance) => <String, dynamic>{
  'id': instance.id,
  'acms_id': instance.acmsId,
  'user_category': instance.userCategory,
  'name': instance.name,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'image': instance.image,
  'email': instance.email,
  'verify_email': instance.verifyEmail,
  'cnic': instance.cnic,
  'phone': instance.phone,
  'address': instance.address,
  'present_address': instance.presentAddress,
  'country_id': instance.countryId,
  'state_id': instance.stateId,
  'city_id': instance.cityId,
  'zip': instance.zip,
  'status': instance.status,
  'app_form': instance.appForm,
  'app_form_approved': instance.appFormApproved,
  'token': instance.token,
};
