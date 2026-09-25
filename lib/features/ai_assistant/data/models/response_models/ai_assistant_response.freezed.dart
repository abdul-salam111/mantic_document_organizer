// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_assistant_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AiAssistantResponse {

@JsonKey(name: 'id') String? get id;@JsonKey(name: 'name') String? get name;@JsonKey(name: 'description') String? get description;@JsonKey(name: 'success') bool? get success;
/// Create a copy of AiAssistantResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiAssistantResponseCopyWith<AiAssistantResponse> get copyWith => _$AiAssistantResponseCopyWithImpl<AiAssistantResponse>(this as AiAssistantResponse, _$identity);

  /// Serializes this AiAssistantResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiAssistantResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.success, success) || other.success == success));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,success);

@override
String toString() {
  return 'AiAssistantResponse(id: $id, name: $name, description: $description, success: $success)';
}


}

/// @nodoc
abstract mixin class $AiAssistantResponseCopyWith<$Res>  {
  factory $AiAssistantResponseCopyWith(AiAssistantResponse value, $Res Function(AiAssistantResponse) _then) = _$AiAssistantResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String? id,@JsonKey(name: 'name') String? name,@JsonKey(name: 'description') String? description,@JsonKey(name: 'success') bool? success
});




}
/// @nodoc
class _$AiAssistantResponseCopyWithImpl<$Res>
    implements $AiAssistantResponseCopyWith<$Res> {
  _$AiAssistantResponseCopyWithImpl(this._self, this._then);

  final AiAssistantResponse _self;
  final $Res Function(AiAssistantResponse) _then;

/// Create a copy of AiAssistantResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? name = freezed,Object? description = freezed,Object? success = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,success: freezed == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [AiAssistantResponse].
extension AiAssistantResponsePatterns on AiAssistantResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AiAssistantResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AiAssistantResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AiAssistantResponse value)  $default,){
final _that = this;
switch (_that) {
case _AiAssistantResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AiAssistantResponse value)?  $default,){
final _that = this;
switch (_that) {
case _AiAssistantResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String? id, @JsonKey(name: 'name')  String? name, @JsonKey(name: 'description')  String? description, @JsonKey(name: 'success')  bool? success)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AiAssistantResponse() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.success);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String? id, @JsonKey(name: 'name')  String? name, @JsonKey(name: 'description')  String? description, @JsonKey(name: 'success')  bool? success)  $default,) {final _that = this;
switch (_that) {
case _AiAssistantResponse():
return $default(_that.id,_that.name,_that.description,_that.success);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String? id, @JsonKey(name: 'name')  String? name, @JsonKey(name: 'description')  String? description, @JsonKey(name: 'success')  bool? success)?  $default,) {final _that = this;
switch (_that) {
case _AiAssistantResponse() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.success);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AiAssistantResponse implements AiAssistantResponse {
  const _AiAssistantResponse({@JsonKey(name: 'id') this.id, @JsonKey(name: 'name') this.name, @JsonKey(name: 'description') this.description, @JsonKey(name: 'success') this.success});
  factory _AiAssistantResponse.fromJson(Map<String, dynamic> json) => _$AiAssistantResponseFromJson(json);

@override@JsonKey(name: 'id') final  String? id;
@override@JsonKey(name: 'name') final  String? name;
@override@JsonKey(name: 'description') final  String? description;
@override@JsonKey(name: 'success') final  bool? success;

/// Create a copy of AiAssistantResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiAssistantResponseCopyWith<_AiAssistantResponse> get copyWith => __$AiAssistantResponseCopyWithImpl<_AiAssistantResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AiAssistantResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiAssistantResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.success, success) || other.success == success));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,success);

@override
String toString() {
  return 'AiAssistantResponse(id: $id, name: $name, description: $description, success: $success)';
}


}

/// @nodoc
abstract mixin class _$AiAssistantResponseCopyWith<$Res> implements $AiAssistantResponseCopyWith<$Res> {
  factory _$AiAssistantResponseCopyWith(_AiAssistantResponse value, $Res Function(_AiAssistantResponse) _then) = __$AiAssistantResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String? id,@JsonKey(name: 'name') String? name,@JsonKey(name: 'description') String? description,@JsonKey(name: 'success') bool? success
});




}
/// @nodoc
class __$AiAssistantResponseCopyWithImpl<$Res>
    implements _$AiAssistantResponseCopyWith<$Res> {
  __$AiAssistantResponseCopyWithImpl(this._self, this._then);

  final _AiAssistantResponse _self;
  final $Res Function(_AiAssistantResponse) _then;

/// Create a copy of AiAssistantResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? name = freezed,Object? description = freezed,Object? success = freezed,}) {
  return _then(_AiAssistantResponse(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,success: freezed == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
