// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document_params.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DocumentParams {

@JsonKey(name: 'name') String get name;@JsonKey(name: 'description') String? get description;
/// Create a copy of DocumentParams
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentParamsCopyWith<DocumentParams> get copyWith => _$DocumentParamsCopyWithImpl<DocumentParams>(this as DocumentParams, _$identity);

  /// Serializes this DocumentParams to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentParams&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description);

@override
String toString() {
  return 'DocumentParams(name: $name, description: $description)';
}


}

/// @nodoc
abstract mixin class $DocumentParamsCopyWith<$Res>  {
  factory $DocumentParamsCopyWith(DocumentParams value, $Res Function(DocumentParams) _then) = _$DocumentParamsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'name') String name,@JsonKey(name: 'description') String? description
});




}
/// @nodoc
class _$DocumentParamsCopyWithImpl<$Res>
    implements $DocumentParamsCopyWith<$Res> {
  _$DocumentParamsCopyWithImpl(this._self, this._then);

  final DocumentParams _self;
  final $Res Function(DocumentParams) _then;

/// Create a copy of DocumentParams
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentParams].
extension DocumentParamsPatterns on DocumentParams {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentParams value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentParams() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentParams value)  $default,){
final _that = this;
switch (_that) {
case _DocumentParams():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentParams value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentParams() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'name')  String name, @JsonKey(name: 'description')  String? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentParams() when $default != null:
return $default(_that.name,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'name')  String name, @JsonKey(name: 'description')  String? description)  $default,) {final _that = this;
switch (_that) {
case _DocumentParams():
return $default(_that.name,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'name')  String name, @JsonKey(name: 'description')  String? description)?  $default,) {final _that = this;
switch (_that) {
case _DocumentParams() when $default != null:
return $default(_that.name,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DocumentParams implements DocumentParams {
  const _DocumentParams({@JsonKey(name: 'name') required this.name, @JsonKey(name: 'description') this.description});
  factory _DocumentParams.fromJson(Map<String, dynamic> json) => _$DocumentParamsFromJson(json);

@override@JsonKey(name: 'name') final  String name;
@override@JsonKey(name: 'description') final  String? description;

/// Create a copy of DocumentParams
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentParamsCopyWith<_DocumentParams> get copyWith => __$DocumentParamsCopyWithImpl<_DocumentParams>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentParamsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentParams&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description);

@override
String toString() {
  return 'DocumentParams(name: $name, description: $description)';
}


}

/// @nodoc
abstract mixin class _$DocumentParamsCopyWith<$Res> implements $DocumentParamsCopyWith<$Res> {
  factory _$DocumentParamsCopyWith(_DocumentParams value, $Res Function(_DocumentParams) _then) = __$DocumentParamsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'name') String name,@JsonKey(name: 'description') String? description
});




}
/// @nodoc
class __$DocumentParamsCopyWithImpl<$Res>
    implements _$DocumentParamsCopyWith<$Res> {
  __$DocumentParamsCopyWithImpl(this._self, this._then);

  final _DocumentParams _self;
  final $Res Function(_DocumentParams) _then;

/// Create a copy of DocumentParams
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = freezed,}) {
  return _then(_DocumentParams(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
