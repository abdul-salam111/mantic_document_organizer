// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invitation_response_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InvitationResponseModel {

@JsonKey(name: 'id') String get id;@JsonKey(name: 'space_id') String get spaceId;@JsonKey(name: 'invited_email') String get invitedEmail;@JsonKey(name: 'role') String get role;@JsonKey(name: 'expires_at') DateTime get expiresAt;@JsonKey(name: 'created_at') DateTime get createdAt;
/// Create a copy of InvitationResponseModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvitationResponseModelCopyWith<InvitationResponseModel> get copyWith => _$InvitationResponseModelCopyWithImpl<InvitationResponseModel>(this as InvitationResponseModel, _$identity);

  /// Serializes this InvitationResponseModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvitationResponseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.spaceId, spaceId) || other.spaceId == spaceId)&&(identical(other.invitedEmail, invitedEmail) || other.invitedEmail == invitedEmail)&&(identical(other.role, role) || other.role == role)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,spaceId,invitedEmail,role,expiresAt,createdAt);

@override
String toString() {
  return 'InvitationResponseModel(id: $id, spaceId: $spaceId, invitedEmail: $invitedEmail, role: $role, expiresAt: $expiresAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $InvitationResponseModelCopyWith<$Res>  {
  factory $InvitationResponseModelCopyWith(InvitationResponseModel value, $Res Function(InvitationResponseModel) _then) = _$InvitationResponseModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'space_id') String spaceId,@JsonKey(name: 'invited_email') String invitedEmail,@JsonKey(name: 'role') String role,@JsonKey(name: 'expires_at') DateTime expiresAt,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class _$InvitationResponseModelCopyWithImpl<$Res>
    implements $InvitationResponseModelCopyWith<$Res> {
  _$InvitationResponseModelCopyWithImpl(this._self, this._then);

  final InvitationResponseModel _self;
  final $Res Function(InvitationResponseModel) _then;

/// Create a copy of InvitationResponseModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? spaceId = null,Object? invitedEmail = null,Object? role = null,Object? expiresAt = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,spaceId: null == spaceId ? _self.spaceId : spaceId // ignore: cast_nullable_to_non_nullable
as String,invitedEmail: null == invitedEmail ? _self.invitedEmail : invitedEmail // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [InvitationResponseModel].
extension InvitationResponseModelPatterns on InvitationResponseModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvitationResponseModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvitationResponseModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvitationResponseModel value)  $default,){
final _that = this;
switch (_that) {
case _InvitationResponseModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvitationResponseModel value)?  $default,){
final _that = this;
switch (_that) {
case _InvitationResponseModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'space_id')  String spaceId, @JsonKey(name: 'invited_email')  String invitedEmail, @JsonKey(name: 'role')  String role, @JsonKey(name: 'expires_at')  DateTime expiresAt, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvitationResponseModel() when $default != null:
return $default(_that.id,_that.spaceId,_that.invitedEmail,_that.role,_that.expiresAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'space_id')  String spaceId, @JsonKey(name: 'invited_email')  String invitedEmail, @JsonKey(name: 'role')  String role, @JsonKey(name: 'expires_at')  DateTime expiresAt, @JsonKey(name: 'created_at')  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _InvitationResponseModel():
return $default(_that.id,_that.spaceId,_that.invitedEmail,_that.role,_that.expiresAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'space_id')  String spaceId, @JsonKey(name: 'invited_email')  String invitedEmail, @JsonKey(name: 'role')  String role, @JsonKey(name: 'expires_at')  DateTime expiresAt, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _InvitationResponseModel() when $default != null:
return $default(_that.id,_that.spaceId,_that.invitedEmail,_that.role,_that.expiresAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvitationResponseModel implements InvitationResponseModel {
  const _InvitationResponseModel({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'space_id') required this.spaceId, @JsonKey(name: 'invited_email') required this.invitedEmail, @JsonKey(name: 'role') required this.role, @JsonKey(name: 'expires_at') required this.expiresAt, @JsonKey(name: 'created_at') required this.createdAt});
  factory _InvitationResponseModel.fromJson(Map<String, dynamic> json) => _$InvitationResponseModelFromJson(json);

@override@JsonKey(name: 'id') final  String id;
@override@JsonKey(name: 'space_id') final  String spaceId;
@override@JsonKey(name: 'invited_email') final  String invitedEmail;
@override@JsonKey(name: 'role') final  String role;
@override@JsonKey(name: 'expires_at') final  DateTime expiresAt;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;

/// Create a copy of InvitationResponseModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvitationResponseModelCopyWith<_InvitationResponseModel> get copyWith => __$InvitationResponseModelCopyWithImpl<_InvitationResponseModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvitationResponseModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvitationResponseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.spaceId, spaceId) || other.spaceId == spaceId)&&(identical(other.invitedEmail, invitedEmail) || other.invitedEmail == invitedEmail)&&(identical(other.role, role) || other.role == role)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,spaceId,invitedEmail,role,expiresAt,createdAt);

@override
String toString() {
  return 'InvitationResponseModel(id: $id, spaceId: $spaceId, invitedEmail: $invitedEmail, role: $role, expiresAt: $expiresAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$InvitationResponseModelCopyWith<$Res> implements $InvitationResponseModelCopyWith<$Res> {
  factory _$InvitationResponseModelCopyWith(_InvitationResponseModel value, $Res Function(_InvitationResponseModel) _then) = __$InvitationResponseModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'space_id') String spaceId,@JsonKey(name: 'invited_email') String invitedEmail,@JsonKey(name: 'role') String role,@JsonKey(name: 'expires_at') DateTime expiresAt,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class __$InvitationResponseModelCopyWithImpl<$Res>
    implements _$InvitationResponseModelCopyWith<$Res> {
  __$InvitationResponseModelCopyWithImpl(this._self, this._then);

  final _InvitationResponseModel _self;
  final $Res Function(_InvitationResponseModel) _then;

/// Create a copy of InvitationResponseModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? spaceId = null,Object? invitedEmail = null,Object? role = null,Object? expiresAt = null,Object? createdAt = null,}) {
  return _then(_InvitationResponseModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,spaceId: null == spaceId ? _self.spaceId : spaceId // ignore: cast_nullable_to_non_nullable
as String,invitedEmail: null == invitedEmail ? _self.invitedEmail : invitedEmail // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
