// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'member_response_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MemberResponseModel {

@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'role') String get role;@JsonKey(name: 'display_name') String get displayName;@JsonKey(name: 'email') String get email;@JsonKey(name: 'joined_at') DateTime get joinedAt;
/// Create a copy of MemberResponseModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberResponseModelCopyWith<MemberResponseModel> get copyWith => _$MemberResponseModelCopyWithImpl<MemberResponseModel>(this as MemberResponseModel, _$identity);

  /// Serializes this MemberResponseModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberResponseModel&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.role, role) || other.role == role)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,role,displayName,email,joinedAt);

@override
String toString() {
  return 'MemberResponseModel(userId: $userId, role: $role, displayName: $displayName, email: $email, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class $MemberResponseModelCopyWith<$Res>  {
  factory $MemberResponseModelCopyWith(MemberResponseModel value, $Res Function(MemberResponseModel) _then) = _$MemberResponseModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'role') String role,@JsonKey(name: 'display_name') String displayName,@JsonKey(name: 'email') String email,@JsonKey(name: 'joined_at') DateTime joinedAt
});




}
/// @nodoc
class _$MemberResponseModelCopyWithImpl<$Res>
    implements $MemberResponseModelCopyWith<$Res> {
  _$MemberResponseModelCopyWithImpl(this._self, this._then);

  final MemberResponseModel _self;
  final $Res Function(MemberResponseModel) _then;

/// Create a copy of MemberResponseModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? role = null,Object? displayName = null,Object? email = null,Object? joinedAt = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MemberResponseModel].
extension MemberResponseModelPatterns on MemberResponseModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberResponseModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberResponseModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberResponseModel value)  $default,){
final _that = this;
switch (_that) {
case _MemberResponseModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberResponseModel value)?  $default,){
final _that = this;
switch (_that) {
case _MemberResponseModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'role')  String role, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'email')  String email, @JsonKey(name: 'joined_at')  DateTime joinedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberResponseModel() when $default != null:
return $default(_that.userId,_that.role,_that.displayName,_that.email,_that.joinedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'role')  String role, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'email')  String email, @JsonKey(name: 'joined_at')  DateTime joinedAt)  $default,) {final _that = this;
switch (_that) {
case _MemberResponseModel():
return $default(_that.userId,_that.role,_that.displayName,_that.email,_that.joinedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'role')  String role, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'email')  String email, @JsonKey(name: 'joined_at')  DateTime joinedAt)?  $default,) {final _that = this;
switch (_that) {
case _MemberResponseModel() when $default != null:
return $default(_that.userId,_that.role,_that.displayName,_that.email,_that.joinedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemberResponseModel implements MemberResponseModel {
  const _MemberResponseModel({@JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'role') required this.role, @JsonKey(name: 'display_name') required this.displayName, @JsonKey(name: 'email') required this.email, @JsonKey(name: 'joined_at') required this.joinedAt});
  factory _MemberResponseModel.fromJson(Map<String, dynamic> json) => _$MemberResponseModelFromJson(json);

@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'role') final  String role;
@override@JsonKey(name: 'display_name') final  String displayName;
@override@JsonKey(name: 'email') final  String email;
@override@JsonKey(name: 'joined_at') final  DateTime joinedAt;

/// Create a copy of MemberResponseModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberResponseModelCopyWith<_MemberResponseModel> get copyWith => __$MemberResponseModelCopyWithImpl<_MemberResponseModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberResponseModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberResponseModel&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.role, role) || other.role == role)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,role,displayName,email,joinedAt);

@override
String toString() {
  return 'MemberResponseModel(userId: $userId, role: $role, displayName: $displayName, email: $email, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class _$MemberResponseModelCopyWith<$Res> implements $MemberResponseModelCopyWith<$Res> {
  factory _$MemberResponseModelCopyWith(_MemberResponseModel value, $Res Function(_MemberResponseModel) _then) = __$MemberResponseModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'role') String role,@JsonKey(name: 'display_name') String displayName,@JsonKey(name: 'email') String email,@JsonKey(name: 'joined_at') DateTime joinedAt
});




}
/// @nodoc
class __$MemberResponseModelCopyWithImpl<$Res>
    implements _$MemberResponseModelCopyWith<$Res> {
  __$MemberResponseModelCopyWithImpl(this._self, this._then);

  final _MemberResponseModel _self;
  final $Res Function(_MemberResponseModel) _then;

/// Create a copy of MemberResponseModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? role = null,Object? displayName = null,Object? email = null,Object? joinedAt = null,}) {
  return _then(_MemberResponseModel(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
