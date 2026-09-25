// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_assistant_params.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AiAssistantParams {

@JsonKey(name: 'param1') String get param1;@JsonKey(name: 'param2') String get param2;
/// Create a copy of AiAssistantParams
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiAssistantParamsCopyWith<AiAssistantParams> get copyWith => _$AiAssistantParamsCopyWithImpl<AiAssistantParams>(this as AiAssistantParams, _$identity);

  /// Serializes this AiAssistantParams to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiAssistantParams&&(identical(other.param1, param1) || other.param1 == param1)&&(identical(other.param2, param2) || other.param2 == param2));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,param1,param2);

@override
String toString() {
  return 'AiAssistantParams(param1: $param1, param2: $param2)';
}


}

/// @nodoc
abstract mixin class $AiAssistantParamsCopyWith<$Res>  {
  factory $AiAssistantParamsCopyWith(AiAssistantParams value, $Res Function(AiAssistantParams) _then) = _$AiAssistantParamsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'param1') String param1,@JsonKey(name: 'param2') String param2
});




}
/// @nodoc
class _$AiAssistantParamsCopyWithImpl<$Res>
    implements $AiAssistantParamsCopyWith<$Res> {
  _$AiAssistantParamsCopyWithImpl(this._self, this._then);

  final AiAssistantParams _self;
  final $Res Function(AiAssistantParams) _then;

/// Create a copy of AiAssistantParams
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? param1 = null,Object? param2 = null,}) {
  return _then(_self.copyWith(
param1: null == param1 ? _self.param1 : param1 // ignore: cast_nullable_to_non_nullable
as String,param2: null == param2 ? _self.param2 : param2 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AiAssistantParams].
extension AiAssistantParamsPatterns on AiAssistantParams {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AiAssistantParams value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AiAssistantParams() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AiAssistantParams value)  $default,){
final _that = this;
switch (_that) {
case _AiAssistantParams():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AiAssistantParams value)?  $default,){
final _that = this;
switch (_that) {
case _AiAssistantParams() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'param1')  String param1, @JsonKey(name: 'param2')  String param2)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AiAssistantParams() when $default != null:
return $default(_that.param1,_that.param2);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'param1')  String param1, @JsonKey(name: 'param2')  String param2)  $default,) {final _that = this;
switch (_that) {
case _AiAssistantParams():
return $default(_that.param1,_that.param2);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'param1')  String param1, @JsonKey(name: 'param2')  String param2)?  $default,) {final _that = this;
switch (_that) {
case _AiAssistantParams() when $default != null:
return $default(_that.param1,_that.param2);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AiAssistantParams implements AiAssistantParams {
  const _AiAssistantParams({@JsonKey(name: 'param1') required this.param1, @JsonKey(name: 'param2') required this.param2});
  factory _AiAssistantParams.fromJson(Map<String, dynamic> json) => _$AiAssistantParamsFromJson(json);

@override@JsonKey(name: 'param1') final  String param1;
@override@JsonKey(name: 'param2') final  String param2;

/// Create a copy of AiAssistantParams
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiAssistantParamsCopyWith<_AiAssistantParams> get copyWith => __$AiAssistantParamsCopyWithImpl<_AiAssistantParams>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AiAssistantParamsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiAssistantParams&&(identical(other.param1, param1) || other.param1 == param1)&&(identical(other.param2, param2) || other.param2 == param2));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,param1,param2);

@override
String toString() {
  return 'AiAssistantParams(param1: $param1, param2: $param2)';
}


}

/// @nodoc
abstract mixin class _$AiAssistantParamsCopyWith<$Res> implements $AiAssistantParamsCopyWith<$Res> {
  factory _$AiAssistantParamsCopyWith(_AiAssistantParams value, $Res Function(_AiAssistantParams) _then) = __$AiAssistantParamsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'param1') String param1,@JsonKey(name: 'param2') String param2
});




}
/// @nodoc
class __$AiAssistantParamsCopyWithImpl<$Res>
    implements _$AiAssistantParamsCopyWith<$Res> {
  __$AiAssistantParamsCopyWithImpl(this._self, this._then);

  final _AiAssistantParams _self;
  final $Res Function(_AiAssistantParams) _then;

/// Create a copy of AiAssistantParams
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? param1 = null,Object? param2 = null,}) {
  return _then(_AiAssistantParams(
param1: null == param1 ? _self.param1 : param1 // ignore: cast_nullable_to_non_nullable
as String,param2: null == param2 ? _self.param2 : param2 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
