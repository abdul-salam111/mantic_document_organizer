// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserModel {

@JsonKey(name: "success") bool? get success;@JsonKey(name: "data") UserData? get data;@JsonKey(name: "message") String? get message;
/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserModelCopyWith<UserModel> get copyWith => _$UserModelCopyWithImpl<UserModel>(this as UserModel, _$identity);

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserModel&&(identical(other.success, success) || other.success == success)&&(identical(other.data, data) || other.data == data)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,success,data,message);

@override
String toString() {
  return 'UserModel(success: $success, data: $data, message: $message)';
}


}

/// @nodoc
abstract mixin class $UserModelCopyWith<$Res>  {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) _then) = _$UserModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "success") bool? success,@JsonKey(name: "data") UserData? data,@JsonKey(name: "message") String? message
});


$UserDataCopyWith<$Res>? get data;

}
/// @nodoc
class _$UserModelCopyWithImpl<$Res>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._self, this._then);

  final UserModel _self;
  final $Res Function(UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? success = freezed,Object? data = freezed,Object? message = freezed,}) {
  return _then(_self.copyWith(
success: freezed == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as UserData?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserDataCopyWith<$Res>? get data {
    if (_self.data == null) {
    return null;
  }

  return $UserDataCopyWith<$Res>(_self.data!, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// Adds pattern-matching-related methods to [UserModel].
extension UserModelPatterns on UserModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserModel value)  $default,){
final _that = this;
switch (_that) {
case _UserModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "success")  bool? success, @JsonKey(name: "data")  UserData? data, @JsonKey(name: "message")  String? message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.success,_that.data,_that.message);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "success")  bool? success, @JsonKey(name: "data")  UserData? data, @JsonKey(name: "message")  String? message)  $default,) {final _that = this;
switch (_that) {
case _UserModel():
return $default(_that.success,_that.data,_that.message);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "success")  bool? success, @JsonKey(name: "data")  UserData? data, @JsonKey(name: "message")  String? message)?  $default,) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.success,_that.data,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserModel implements UserModel {
  const _UserModel({@JsonKey(name: "success") this.success, @JsonKey(name: "data") this.data, @JsonKey(name: "message") this.message});
  factory _UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

@override@JsonKey(name: "success") final  bool? success;
@override@JsonKey(name: "data") final  UserData? data;
@override@JsonKey(name: "message") final  String? message;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserModelCopyWith<_UserModel> get copyWith => __$UserModelCopyWithImpl<_UserModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserModel&&(identical(other.success, success) || other.success == success)&&(identical(other.data, data) || other.data == data)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,success,data,message);

@override
String toString() {
  return 'UserModel(success: $success, data: $data, message: $message)';
}


}

/// @nodoc
abstract mixin class _$UserModelCopyWith<$Res> implements $UserModelCopyWith<$Res> {
  factory _$UserModelCopyWith(_UserModel value, $Res Function(_UserModel) _then) = __$UserModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "success") bool? success,@JsonKey(name: "data") UserData? data,@JsonKey(name: "message") String? message
});


@override $UserDataCopyWith<$Res>? get data;

}
/// @nodoc
class __$UserModelCopyWithImpl<$Res>
    implements _$UserModelCopyWith<$Res> {
  __$UserModelCopyWithImpl(this._self, this._then);

  final _UserModel _self;
  final $Res Function(_UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? success = freezed,Object? data = freezed,Object? message = freezed,}) {
  return _then(_UserModel(
success: freezed == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as UserData?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserDataCopyWith<$Res>? get data {
    if (_self.data == null) {
    return null;
  }

  return $UserDataCopyWith<$Res>(_self.data!, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// @nodoc
mixin _$UserData {

@JsonKey(name: "id") int? get id;@JsonKey(name: "acms_id") String? get acmsId;@JsonKey(name: "user_category") String? get userCategory;@JsonKey(name: "name") String? get name;@JsonKey(name: "first_name") dynamic get firstName;@JsonKey(name: "last_name") dynamic get lastName;@JsonKey(name: "image") dynamic get image;@JsonKey(name: "email") String? get email;@JsonKey(name: "verify_email") int? get verifyEmail;@JsonKey(name: "cnic") dynamic get cnic;@JsonKey(name: "phone") dynamic get phone;@JsonKey(name: "address") dynamic get address;@JsonKey(name: "present_address") String? get presentAddress;@JsonKey(name: "country_id") dynamic get countryId;@JsonKey(name: "state_id") dynamic get stateId;@JsonKey(name: "city_id") dynamic get cityId;@JsonKey(name: "zip") dynamic get zip;@JsonKey(name: "status") int? get status;@JsonKey(name: "app_form") int? get appForm;@JsonKey(name: "app_form_approved") int? get appFormApproved;@JsonKey(name: "token") String? get token;
/// Create a copy of UserData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserDataCopyWith<UserData> get copyWith => _$UserDataCopyWithImpl<UserData>(this as UserData, _$identity);

  /// Serializes this UserData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserData&&(identical(other.id, id) || other.id == id)&&(identical(other.acmsId, acmsId) || other.acmsId == acmsId)&&(identical(other.userCategory, userCategory) || other.userCategory == userCategory)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.firstName, firstName)&&const DeepCollectionEquality().equals(other.lastName, lastName)&&const DeepCollectionEquality().equals(other.image, image)&&(identical(other.email, email) || other.email == email)&&(identical(other.verifyEmail, verifyEmail) || other.verifyEmail == verifyEmail)&&const DeepCollectionEquality().equals(other.cnic, cnic)&&const DeepCollectionEquality().equals(other.phone, phone)&&const DeepCollectionEquality().equals(other.address, address)&&(identical(other.presentAddress, presentAddress) || other.presentAddress == presentAddress)&&const DeepCollectionEquality().equals(other.countryId, countryId)&&const DeepCollectionEquality().equals(other.stateId, stateId)&&const DeepCollectionEquality().equals(other.cityId, cityId)&&const DeepCollectionEquality().equals(other.zip, zip)&&(identical(other.status, status) || other.status == status)&&(identical(other.appForm, appForm) || other.appForm == appForm)&&(identical(other.appFormApproved, appFormApproved) || other.appFormApproved == appFormApproved)&&(identical(other.token, token) || other.token == token));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,acmsId,userCategory,name,const DeepCollectionEquality().hash(firstName),const DeepCollectionEquality().hash(lastName),const DeepCollectionEquality().hash(image),email,verifyEmail,const DeepCollectionEquality().hash(cnic),const DeepCollectionEquality().hash(phone),const DeepCollectionEquality().hash(address),presentAddress,const DeepCollectionEquality().hash(countryId),const DeepCollectionEquality().hash(stateId),const DeepCollectionEquality().hash(cityId),const DeepCollectionEquality().hash(zip),status,appForm,appFormApproved,token]);

@override
String toString() {
  return 'UserData(id: $id, acmsId: $acmsId, userCategory: $userCategory, name: $name, firstName: $firstName, lastName: $lastName, image: $image, email: $email, verifyEmail: $verifyEmail, cnic: $cnic, phone: $phone, address: $address, presentAddress: $presentAddress, countryId: $countryId, stateId: $stateId, cityId: $cityId, zip: $zip, status: $status, appForm: $appForm, appFormApproved: $appFormApproved, token: $token)';
}


}

/// @nodoc
abstract mixin class $UserDataCopyWith<$Res>  {
  factory $UserDataCopyWith(UserData value, $Res Function(UserData) _then) = _$UserDataCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "id") int? id,@JsonKey(name: "acms_id") String? acmsId,@JsonKey(name: "user_category") String? userCategory,@JsonKey(name: "name") String? name,@JsonKey(name: "first_name") dynamic firstName,@JsonKey(name: "last_name") dynamic lastName,@JsonKey(name: "image") dynamic image,@JsonKey(name: "email") String? email,@JsonKey(name: "verify_email") int? verifyEmail,@JsonKey(name: "cnic") dynamic cnic,@JsonKey(name: "phone") dynamic phone,@JsonKey(name: "address") dynamic address,@JsonKey(name: "present_address") String? presentAddress,@JsonKey(name: "country_id") dynamic countryId,@JsonKey(name: "state_id") dynamic stateId,@JsonKey(name: "city_id") dynamic cityId,@JsonKey(name: "zip") dynamic zip,@JsonKey(name: "status") int? status,@JsonKey(name: "app_form") int? appForm,@JsonKey(name: "app_form_approved") int? appFormApproved,@JsonKey(name: "token") String? token
});




}
/// @nodoc
class _$UserDataCopyWithImpl<$Res>
    implements $UserDataCopyWith<$Res> {
  _$UserDataCopyWithImpl(this._self, this._then);

  final UserData _self;
  final $Res Function(UserData) _then;

/// Create a copy of UserData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? acmsId = freezed,Object? userCategory = freezed,Object? name = freezed,Object? firstName = freezed,Object? lastName = freezed,Object? image = freezed,Object? email = freezed,Object? verifyEmail = freezed,Object? cnic = freezed,Object? phone = freezed,Object? address = freezed,Object? presentAddress = freezed,Object? countryId = freezed,Object? stateId = freezed,Object? cityId = freezed,Object? zip = freezed,Object? status = freezed,Object? appForm = freezed,Object? appFormApproved = freezed,Object? token = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,acmsId: freezed == acmsId ? _self.acmsId : acmsId // ignore: cast_nullable_to_non_nullable
as String?,userCategory: freezed == userCategory ? _self.userCategory : userCategory // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as dynamic,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as dynamic,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as dynamic,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,verifyEmail: freezed == verifyEmail ? _self.verifyEmail : verifyEmail // ignore: cast_nullable_to_non_nullable
as int?,cnic: freezed == cnic ? _self.cnic : cnic // ignore: cast_nullable_to_non_nullable
as dynamic,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as dynamic,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as dynamic,presentAddress: freezed == presentAddress ? _self.presentAddress : presentAddress // ignore: cast_nullable_to_non_nullable
as String?,countryId: freezed == countryId ? _self.countryId : countryId // ignore: cast_nullable_to_non_nullable
as dynamic,stateId: freezed == stateId ? _self.stateId : stateId // ignore: cast_nullable_to_non_nullable
as dynamic,cityId: freezed == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as dynamic,zip: freezed == zip ? _self.zip : zip // ignore: cast_nullable_to_non_nullable
as dynamic,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as int?,appForm: freezed == appForm ? _self.appForm : appForm // ignore: cast_nullable_to_non_nullable
as int?,appFormApproved: freezed == appFormApproved ? _self.appFormApproved : appFormApproved // ignore: cast_nullable_to_non_nullable
as int?,token: freezed == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserData].
extension UserDataPatterns on UserData {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserData() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserData value)  $default,){
final _that = this;
switch (_that) {
case _UserData():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserData value)?  $default,){
final _that = this;
switch (_that) {
case _UserData() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  int? id, @JsonKey(name: "acms_id")  String? acmsId, @JsonKey(name: "user_category")  String? userCategory, @JsonKey(name: "name")  String? name, @JsonKey(name: "first_name")  dynamic firstName, @JsonKey(name: "last_name")  dynamic lastName, @JsonKey(name: "image")  dynamic image, @JsonKey(name: "email")  String? email, @JsonKey(name: "verify_email")  int? verifyEmail, @JsonKey(name: "cnic")  dynamic cnic, @JsonKey(name: "phone")  dynamic phone, @JsonKey(name: "address")  dynamic address, @JsonKey(name: "present_address")  String? presentAddress, @JsonKey(name: "country_id")  dynamic countryId, @JsonKey(name: "state_id")  dynamic stateId, @JsonKey(name: "city_id")  dynamic cityId, @JsonKey(name: "zip")  dynamic zip, @JsonKey(name: "status")  int? status, @JsonKey(name: "app_form")  int? appForm, @JsonKey(name: "app_form_approved")  int? appFormApproved, @JsonKey(name: "token")  String? token)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserData() when $default != null:
return $default(_that.id,_that.acmsId,_that.userCategory,_that.name,_that.firstName,_that.lastName,_that.image,_that.email,_that.verifyEmail,_that.cnic,_that.phone,_that.address,_that.presentAddress,_that.countryId,_that.stateId,_that.cityId,_that.zip,_that.status,_that.appForm,_that.appFormApproved,_that.token);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  int? id, @JsonKey(name: "acms_id")  String? acmsId, @JsonKey(name: "user_category")  String? userCategory, @JsonKey(name: "name")  String? name, @JsonKey(name: "first_name")  dynamic firstName, @JsonKey(name: "last_name")  dynamic lastName, @JsonKey(name: "image")  dynamic image, @JsonKey(name: "email")  String? email, @JsonKey(name: "verify_email")  int? verifyEmail, @JsonKey(name: "cnic")  dynamic cnic, @JsonKey(name: "phone")  dynamic phone, @JsonKey(name: "address")  dynamic address, @JsonKey(name: "present_address")  String? presentAddress, @JsonKey(name: "country_id")  dynamic countryId, @JsonKey(name: "state_id")  dynamic stateId, @JsonKey(name: "city_id")  dynamic cityId, @JsonKey(name: "zip")  dynamic zip, @JsonKey(name: "status")  int? status, @JsonKey(name: "app_form")  int? appForm, @JsonKey(name: "app_form_approved")  int? appFormApproved, @JsonKey(name: "token")  String? token)  $default,) {final _that = this;
switch (_that) {
case _UserData():
return $default(_that.id,_that.acmsId,_that.userCategory,_that.name,_that.firstName,_that.lastName,_that.image,_that.email,_that.verifyEmail,_that.cnic,_that.phone,_that.address,_that.presentAddress,_that.countryId,_that.stateId,_that.cityId,_that.zip,_that.status,_that.appForm,_that.appFormApproved,_that.token);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "id")  int? id, @JsonKey(name: "acms_id")  String? acmsId, @JsonKey(name: "user_category")  String? userCategory, @JsonKey(name: "name")  String? name, @JsonKey(name: "first_name")  dynamic firstName, @JsonKey(name: "last_name")  dynamic lastName, @JsonKey(name: "image")  dynamic image, @JsonKey(name: "email")  String? email, @JsonKey(name: "verify_email")  int? verifyEmail, @JsonKey(name: "cnic")  dynamic cnic, @JsonKey(name: "phone")  dynamic phone, @JsonKey(name: "address")  dynamic address, @JsonKey(name: "present_address")  String? presentAddress, @JsonKey(name: "country_id")  dynamic countryId, @JsonKey(name: "state_id")  dynamic stateId, @JsonKey(name: "city_id")  dynamic cityId, @JsonKey(name: "zip")  dynamic zip, @JsonKey(name: "status")  int? status, @JsonKey(name: "app_form")  int? appForm, @JsonKey(name: "app_form_approved")  int? appFormApproved, @JsonKey(name: "token")  String? token)?  $default,) {final _that = this;
switch (_that) {
case _UserData() when $default != null:
return $default(_that.id,_that.acmsId,_that.userCategory,_that.name,_that.firstName,_that.lastName,_that.image,_that.email,_that.verifyEmail,_that.cnic,_that.phone,_that.address,_that.presentAddress,_that.countryId,_that.stateId,_that.cityId,_that.zip,_that.status,_that.appForm,_that.appFormApproved,_that.token);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserData implements UserData {
  const _UserData({@JsonKey(name: "id") this.id, @JsonKey(name: "acms_id") this.acmsId, @JsonKey(name: "user_category") this.userCategory, @JsonKey(name: "name") this.name, @JsonKey(name: "first_name") this.firstName, @JsonKey(name: "last_name") this.lastName, @JsonKey(name: "image") this.image, @JsonKey(name: "email") this.email, @JsonKey(name: "verify_email") this.verifyEmail, @JsonKey(name: "cnic") this.cnic, @JsonKey(name: "phone") this.phone, @JsonKey(name: "address") this.address, @JsonKey(name: "present_address") this.presentAddress, @JsonKey(name: "country_id") this.countryId, @JsonKey(name: "state_id") this.stateId, @JsonKey(name: "city_id") this.cityId, @JsonKey(name: "zip") this.zip, @JsonKey(name: "status") this.status, @JsonKey(name: "app_form") this.appForm, @JsonKey(name: "app_form_approved") this.appFormApproved, @JsonKey(name: "token") this.token});
  factory _UserData.fromJson(Map<String, dynamic> json) => _$UserDataFromJson(json);

@override@JsonKey(name: "id") final  int? id;
@override@JsonKey(name: "acms_id") final  String? acmsId;
@override@JsonKey(name: "user_category") final  String? userCategory;
@override@JsonKey(name: "name") final  String? name;
@override@JsonKey(name: "first_name") final  dynamic firstName;
@override@JsonKey(name: "last_name") final  dynamic lastName;
@override@JsonKey(name: "image") final  dynamic image;
@override@JsonKey(name: "email") final  String? email;
@override@JsonKey(name: "verify_email") final  int? verifyEmail;
@override@JsonKey(name: "cnic") final  dynamic cnic;
@override@JsonKey(name: "phone") final  dynamic phone;
@override@JsonKey(name: "address") final  dynamic address;
@override@JsonKey(name: "present_address") final  String? presentAddress;
@override@JsonKey(name: "country_id") final  dynamic countryId;
@override@JsonKey(name: "state_id") final  dynamic stateId;
@override@JsonKey(name: "city_id") final  dynamic cityId;
@override@JsonKey(name: "zip") final  dynamic zip;
@override@JsonKey(name: "status") final  int? status;
@override@JsonKey(name: "app_form") final  int? appForm;
@override@JsonKey(name: "app_form_approved") final  int? appFormApproved;
@override@JsonKey(name: "token") final  String? token;

/// Create a copy of UserData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserDataCopyWith<_UserData> get copyWith => __$UserDataCopyWithImpl<_UserData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserData&&(identical(other.id, id) || other.id == id)&&(identical(other.acmsId, acmsId) || other.acmsId == acmsId)&&(identical(other.userCategory, userCategory) || other.userCategory == userCategory)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.firstName, firstName)&&const DeepCollectionEquality().equals(other.lastName, lastName)&&const DeepCollectionEquality().equals(other.image, image)&&(identical(other.email, email) || other.email == email)&&(identical(other.verifyEmail, verifyEmail) || other.verifyEmail == verifyEmail)&&const DeepCollectionEquality().equals(other.cnic, cnic)&&const DeepCollectionEquality().equals(other.phone, phone)&&const DeepCollectionEquality().equals(other.address, address)&&(identical(other.presentAddress, presentAddress) || other.presentAddress == presentAddress)&&const DeepCollectionEquality().equals(other.countryId, countryId)&&const DeepCollectionEquality().equals(other.stateId, stateId)&&const DeepCollectionEquality().equals(other.cityId, cityId)&&const DeepCollectionEquality().equals(other.zip, zip)&&(identical(other.status, status) || other.status == status)&&(identical(other.appForm, appForm) || other.appForm == appForm)&&(identical(other.appFormApproved, appFormApproved) || other.appFormApproved == appFormApproved)&&(identical(other.token, token) || other.token == token));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,acmsId,userCategory,name,const DeepCollectionEquality().hash(firstName),const DeepCollectionEquality().hash(lastName),const DeepCollectionEquality().hash(image),email,verifyEmail,const DeepCollectionEquality().hash(cnic),const DeepCollectionEquality().hash(phone),const DeepCollectionEquality().hash(address),presentAddress,const DeepCollectionEquality().hash(countryId),const DeepCollectionEquality().hash(stateId),const DeepCollectionEquality().hash(cityId),const DeepCollectionEquality().hash(zip),status,appForm,appFormApproved,token]);

@override
String toString() {
  return 'UserData(id: $id, acmsId: $acmsId, userCategory: $userCategory, name: $name, firstName: $firstName, lastName: $lastName, image: $image, email: $email, verifyEmail: $verifyEmail, cnic: $cnic, phone: $phone, address: $address, presentAddress: $presentAddress, countryId: $countryId, stateId: $stateId, cityId: $cityId, zip: $zip, status: $status, appForm: $appForm, appFormApproved: $appFormApproved, token: $token)';
}


}

/// @nodoc
abstract mixin class _$UserDataCopyWith<$Res> implements $UserDataCopyWith<$Res> {
  factory _$UserDataCopyWith(_UserData value, $Res Function(_UserData) _then) = __$UserDataCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "id") int? id,@JsonKey(name: "acms_id") String? acmsId,@JsonKey(name: "user_category") String? userCategory,@JsonKey(name: "name") String? name,@JsonKey(name: "first_name") dynamic firstName,@JsonKey(name: "last_name") dynamic lastName,@JsonKey(name: "image") dynamic image,@JsonKey(name: "email") String? email,@JsonKey(name: "verify_email") int? verifyEmail,@JsonKey(name: "cnic") dynamic cnic,@JsonKey(name: "phone") dynamic phone,@JsonKey(name: "address") dynamic address,@JsonKey(name: "present_address") String? presentAddress,@JsonKey(name: "country_id") dynamic countryId,@JsonKey(name: "state_id") dynamic stateId,@JsonKey(name: "city_id") dynamic cityId,@JsonKey(name: "zip") dynamic zip,@JsonKey(name: "status") int? status,@JsonKey(name: "app_form") int? appForm,@JsonKey(name: "app_form_approved") int? appFormApproved,@JsonKey(name: "token") String? token
});




}
/// @nodoc
class __$UserDataCopyWithImpl<$Res>
    implements _$UserDataCopyWith<$Res> {
  __$UserDataCopyWithImpl(this._self, this._then);

  final _UserData _self;
  final $Res Function(_UserData) _then;

/// Create a copy of UserData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? acmsId = freezed,Object? userCategory = freezed,Object? name = freezed,Object? firstName = freezed,Object? lastName = freezed,Object? image = freezed,Object? email = freezed,Object? verifyEmail = freezed,Object? cnic = freezed,Object? phone = freezed,Object? address = freezed,Object? presentAddress = freezed,Object? countryId = freezed,Object? stateId = freezed,Object? cityId = freezed,Object? zip = freezed,Object? status = freezed,Object? appForm = freezed,Object? appFormApproved = freezed,Object? token = freezed,}) {
  return _then(_UserData(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,acmsId: freezed == acmsId ? _self.acmsId : acmsId // ignore: cast_nullable_to_non_nullable
as String?,userCategory: freezed == userCategory ? _self.userCategory : userCategory // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as dynamic,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as dynamic,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as dynamic,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,verifyEmail: freezed == verifyEmail ? _self.verifyEmail : verifyEmail // ignore: cast_nullable_to_non_nullable
as int?,cnic: freezed == cnic ? _self.cnic : cnic // ignore: cast_nullable_to_non_nullable
as dynamic,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as dynamic,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as dynamic,presentAddress: freezed == presentAddress ? _self.presentAddress : presentAddress // ignore: cast_nullable_to_non_nullable
as String?,countryId: freezed == countryId ? _self.countryId : countryId // ignore: cast_nullable_to_non_nullable
as dynamic,stateId: freezed == stateId ? _self.stateId : stateId // ignore: cast_nullable_to_non_nullable
as dynamic,cityId: freezed == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as dynamic,zip: freezed == zip ? _self.zip : zip // ignore: cast_nullable_to_non_nullable
as dynamic,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as int?,appForm: freezed == appForm ? _self.appForm : appForm // ignore: cast_nullable_to_non_nullable
as int?,appFormApproved: freezed == appFormApproved ? _self.appFormApproved : appFormApproved // ignore: cast_nullable_to_non_nullable
as int?,token: freezed == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
