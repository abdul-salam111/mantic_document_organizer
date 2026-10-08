// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'join_link_response_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JoinLinkResponseModel {

@JsonKey(name: 'id') String get id;@JsonKey(name: 'space_id') String get spaceId;@JsonKey(name: 'role') String get role;// Only non-empty right after creation -- see JoinLinkEntity's doc.
@JsonKey(name: 'token') String? get token;@JsonKey(name: 'expires_at') DateTime? get expiresAt;@JsonKey(name: 'created_at') DateTime get createdAt;
/// Create a copy of JoinLinkResponseModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JoinLinkResponseModelCopyWith<JoinLinkResponseModel> get copyWith => _$JoinLinkResponseModelCopyWithImpl<JoinLinkResponseModel>(this as JoinLinkResponseModel, _$identity);

  /// Serializes this JoinLinkResponseModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JoinLinkResponseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.spaceId, spaceId) || other.spaceId == spaceId)&&(identical(other.role, role) || other.role == role)&&(identical(other.token, token) || other.token == token)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,spaceId,role,token,expiresAt,createdAt);

@override
String toString() {
  return 'JoinLinkResponseModel(id: $id, spaceId: $spaceId, role: $role, token: $token, expiresAt: $expiresAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $JoinLinkResponseModelCopyWith<$Res>  {
  factory $JoinLinkResponseModelCopyWith(JoinLinkResponseModel value, $Res Function(JoinLinkResponseModel) _then) = _$JoinLinkResponseModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'space_id') String spaceId,@JsonKey(name: 'role') String role,@JsonKey(name: 'token') String? token,@JsonKey(name: 'expires_at') DateTime? expiresAt,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class _$JoinLinkResponseModelCopyWithImpl<$Res>
    implements $JoinLinkResponseModelCopyWith<$Res> {
  _$JoinLinkResponseModelCopyWithImpl(this._self, this._then);

  final JoinLinkResponseModel _self;
  final $Res Function(JoinLinkResponseModel) _then;

/// Create a copy of JoinLinkResponseModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? spaceId = null,Object? role = null,Object? token = freezed,Object? expiresAt = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,spaceId: null == spaceId ? _self.spaceId : spaceId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,token: freezed == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [JoinLinkResponseModel].
extension JoinLinkResponseModelPatterns on JoinLinkResponseModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JoinLinkResponseModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JoinLinkResponseModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JoinLinkResponseModel value)  $default,){
final _that = this;
switch (_that) {
case _JoinLinkResponseModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JoinLinkResponseModel value)?  $default,){
final _that = this;
switch (_that) {
case _JoinLinkResponseModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'space_id')  String spaceId, @JsonKey(name: 'role')  String role, @JsonKey(name: 'token')  String? token, @JsonKey(name: 'expires_at')  DateTime? expiresAt, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JoinLinkResponseModel() when $default != null:
return $default(_that.id,_that.spaceId,_that.role,_that.token,_that.expiresAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'space_id')  String spaceId, @JsonKey(name: 'role')  String role, @JsonKey(name: 'token')  String? token, @JsonKey(name: 'expires_at')  DateTime? expiresAt, @JsonKey(name: 'created_at')  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _JoinLinkResponseModel():
return $default(_that.id,_that.spaceId,_that.role,_that.token,_that.expiresAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'space_id')  String spaceId, @JsonKey(name: 'role')  String role, @JsonKey(name: 'token')  String? token, @JsonKey(name: 'expires_at')  DateTime? expiresAt, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _JoinLinkResponseModel() when $default != null:
return $default(_that.id,_that.spaceId,_that.role,_that.token,_that.expiresAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JoinLinkResponseModel implements JoinLinkResponseModel {
  const _JoinLinkResponseModel({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'space_id') required this.spaceId, @JsonKey(name: 'role') required this.role, @JsonKey(name: 'token') this.token, @JsonKey(name: 'expires_at') this.expiresAt, @JsonKey(name: 'created_at') required this.createdAt});
  factory _JoinLinkResponseModel.fromJson(Map<String, dynamic> json) => _$JoinLinkResponseModelFromJson(json);

@override@JsonKey(name: 'id') final  String id;
@override@JsonKey(name: 'space_id') final  String spaceId;
@override@JsonKey(name: 'role') final  String role;
// Only non-empty right after creation -- see JoinLinkEntity's doc.
@override@JsonKey(name: 'token') final  String? token;
@override@JsonKey(name: 'expires_at') final  DateTime? expiresAt;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;

/// Create a copy of JoinLinkResponseModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JoinLinkResponseModelCopyWith<_JoinLinkResponseModel> get copyWith => __$JoinLinkResponseModelCopyWithImpl<_JoinLinkResponseModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JoinLinkResponseModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JoinLinkResponseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.spaceId, spaceId) || other.spaceId == spaceId)&&(identical(other.role, role) || other.role == role)&&(identical(other.token, token) || other.token == token)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,spaceId,role,token,expiresAt,createdAt);

@override
String toString() {
  return 'JoinLinkResponseModel(id: $id, spaceId: $spaceId, role: $role, token: $token, expiresAt: $expiresAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$JoinLinkResponseModelCopyWith<$Res> implements $JoinLinkResponseModelCopyWith<$Res> {
  factory _$JoinLinkResponseModelCopyWith(_JoinLinkResponseModel value, $Res Function(_JoinLinkResponseModel) _then) = __$JoinLinkResponseModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'space_id') String spaceId,@JsonKey(name: 'role') String role,@JsonKey(name: 'token') String? token,@JsonKey(name: 'expires_at') DateTime? expiresAt,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class __$JoinLinkResponseModelCopyWithImpl<$Res>
    implements _$JoinLinkResponseModelCopyWith<$Res> {
  __$JoinLinkResponseModelCopyWithImpl(this._self, this._then);

  final _JoinLinkResponseModel _self;
  final $Res Function(_JoinLinkResponseModel) _then;

/// Create a copy of JoinLinkResponseModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? spaceId = null,Object? role = null,Object? token = freezed,Object? expiresAt = freezed,Object? createdAt = null,}) {
  return _then(_JoinLinkResponseModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,spaceId: null == spaceId ? _self.spaceId : spaceId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,token: freezed == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
