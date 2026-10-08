// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'space_join_response_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SpaceJoinResponseModel {

@JsonKey(name: 'space') SpaceResponseModel get space;@JsonKey(name: 'role') String get role;
/// Create a copy of SpaceJoinResponseModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpaceJoinResponseModelCopyWith<SpaceJoinResponseModel> get copyWith => _$SpaceJoinResponseModelCopyWithImpl<SpaceJoinResponseModel>(this as SpaceJoinResponseModel, _$identity);

  /// Serializes this SpaceJoinResponseModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpaceJoinResponseModel&&(identical(other.space, space) || other.space == space)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,space,role);

@override
String toString() {
  return 'SpaceJoinResponseModel(space: $space, role: $role)';
}


}

/// @nodoc
abstract mixin class $SpaceJoinResponseModelCopyWith<$Res>  {
  factory $SpaceJoinResponseModelCopyWith(SpaceJoinResponseModel value, $Res Function(SpaceJoinResponseModel) _then) = _$SpaceJoinResponseModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'space') SpaceResponseModel space,@JsonKey(name: 'role') String role
});


$SpaceResponseModelCopyWith<$Res> get space;

}
/// @nodoc
class _$SpaceJoinResponseModelCopyWithImpl<$Res>
    implements $SpaceJoinResponseModelCopyWith<$Res> {
  _$SpaceJoinResponseModelCopyWithImpl(this._self, this._then);

  final SpaceJoinResponseModel _self;
  final $Res Function(SpaceJoinResponseModel) _then;

/// Create a copy of SpaceJoinResponseModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? space = null,Object? role = null,}) {
  return _then(_self.copyWith(
space: null == space ? _self.space : space // ignore: cast_nullable_to_non_nullable
as SpaceResponseModel,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of SpaceJoinResponseModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpaceResponseModelCopyWith<$Res> get space {
  
  return $SpaceResponseModelCopyWith<$Res>(_self.space, (value) {
    return _then(_self.copyWith(space: value));
  });
}
}


/// Adds pattern-matching-related methods to [SpaceJoinResponseModel].
extension SpaceJoinResponseModelPatterns on SpaceJoinResponseModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpaceJoinResponseModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpaceJoinResponseModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpaceJoinResponseModel value)  $default,){
final _that = this;
switch (_that) {
case _SpaceJoinResponseModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpaceJoinResponseModel value)?  $default,){
final _that = this;
switch (_that) {
case _SpaceJoinResponseModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'space')  SpaceResponseModel space, @JsonKey(name: 'role')  String role)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpaceJoinResponseModel() when $default != null:
return $default(_that.space,_that.role);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'space')  SpaceResponseModel space, @JsonKey(name: 'role')  String role)  $default,) {final _that = this;
switch (_that) {
case _SpaceJoinResponseModel():
return $default(_that.space,_that.role);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'space')  SpaceResponseModel space, @JsonKey(name: 'role')  String role)?  $default,) {final _that = this;
switch (_that) {
case _SpaceJoinResponseModel() when $default != null:
return $default(_that.space,_that.role);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SpaceJoinResponseModel implements SpaceJoinResponseModel {
  const _SpaceJoinResponseModel({@JsonKey(name: 'space') required this.space, @JsonKey(name: 'role') required this.role});
  factory _SpaceJoinResponseModel.fromJson(Map<String, dynamic> json) => _$SpaceJoinResponseModelFromJson(json);

@override@JsonKey(name: 'space') final  SpaceResponseModel space;
@override@JsonKey(name: 'role') final  String role;

/// Create a copy of SpaceJoinResponseModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpaceJoinResponseModelCopyWith<_SpaceJoinResponseModel> get copyWith => __$SpaceJoinResponseModelCopyWithImpl<_SpaceJoinResponseModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SpaceJoinResponseModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpaceJoinResponseModel&&(identical(other.space, space) || other.space == space)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,space,role);

@override
String toString() {
  return 'SpaceJoinResponseModel(space: $space, role: $role)';
}


}

/// @nodoc
abstract mixin class _$SpaceJoinResponseModelCopyWith<$Res> implements $SpaceJoinResponseModelCopyWith<$Res> {
  factory _$SpaceJoinResponseModelCopyWith(_SpaceJoinResponseModel value, $Res Function(_SpaceJoinResponseModel) _then) = __$SpaceJoinResponseModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'space') SpaceResponseModel space,@JsonKey(name: 'role') String role
});


@override $SpaceResponseModelCopyWith<$Res> get space;

}
/// @nodoc
class __$SpaceJoinResponseModelCopyWithImpl<$Res>
    implements _$SpaceJoinResponseModelCopyWith<$Res> {
  __$SpaceJoinResponseModelCopyWithImpl(this._self, this._then);

  final _SpaceJoinResponseModel _self;
  final $Res Function(_SpaceJoinResponseModel) _then;

/// Create a copy of SpaceJoinResponseModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? space = null,Object? role = null,}) {
  return _then(_SpaceJoinResponseModel(
space: null == space ? _self.space : space // ignore: cast_nullable_to_non_nullable
as SpaceResponseModel,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of SpaceJoinResponseModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpaceResponseModelCopyWith<$Res> get space {
  
  return $SpaceResponseModelCopyWith<$Res>(_self.space, (value) {
    return _then(_self.copyWith(space: value));
  });
}
}

// dart format on
