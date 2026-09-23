// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'add_document_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AddDocumentResponse {

@JsonKey(name: 'id') String? get id;@JsonKey(name: 'name') String? get name;@JsonKey(name: 'description') String? get description;
/// Create a copy of AddDocumentResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddDocumentResponseCopyWith<AddDocumentResponse> get copyWith => _$AddDocumentResponseCopyWithImpl<AddDocumentResponse>(this as AddDocumentResponse, _$identity);

  /// Serializes this AddDocumentResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddDocumentResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description);

@override
String toString() {
  return 'AddDocumentResponse(id: $id, name: $name, description: $description)';
}


}

/// @nodoc
abstract mixin class $AddDocumentResponseCopyWith<$Res>  {
  factory $AddDocumentResponseCopyWith(AddDocumentResponse value, $Res Function(AddDocumentResponse) _then) = _$AddDocumentResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String? id,@JsonKey(name: 'name') String? name,@JsonKey(name: 'description') String? description
});




}
/// @nodoc
class _$AddDocumentResponseCopyWithImpl<$Res>
    implements $AddDocumentResponseCopyWith<$Res> {
  _$AddDocumentResponseCopyWithImpl(this._self, this._then);

  final AddDocumentResponse _self;
  final $Res Function(AddDocumentResponse) _then;

/// Create a copy of AddDocumentResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? name = freezed,Object? description = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AddDocumentResponse].
extension AddDocumentResponsePatterns on AddDocumentResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AddDocumentResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AddDocumentResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AddDocumentResponse value)  $default,){
final _that = this;
switch (_that) {
case _AddDocumentResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AddDocumentResponse value)?  $default,){
final _that = this;
switch (_that) {
case _AddDocumentResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String? id, @JsonKey(name: 'name')  String? name, @JsonKey(name: 'description')  String? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AddDocumentResponse() when $default != null:
return $default(_that.id,_that.name,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String? id, @JsonKey(name: 'name')  String? name, @JsonKey(name: 'description')  String? description)  $default,) {final _that = this;
switch (_that) {
case _AddDocumentResponse():
return $default(_that.id,_that.name,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String? id, @JsonKey(name: 'name')  String? name, @JsonKey(name: 'description')  String? description)?  $default,) {final _that = this;
switch (_that) {
case _AddDocumentResponse() when $default != null:
return $default(_that.id,_that.name,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AddDocumentResponse implements AddDocumentResponse {
  const _AddDocumentResponse({@JsonKey(name: 'id') this.id, @JsonKey(name: 'name') this.name, @JsonKey(name: 'description') this.description});
  factory _AddDocumentResponse.fromJson(Map<String, dynamic> json) => _$AddDocumentResponseFromJson(json);

@override@JsonKey(name: 'id') final  String? id;
@override@JsonKey(name: 'name') final  String? name;
@override@JsonKey(name: 'description') final  String? description;

/// Create a copy of AddDocumentResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddDocumentResponseCopyWith<_AddDocumentResponse> get copyWith => __$AddDocumentResponseCopyWithImpl<_AddDocumentResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AddDocumentResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddDocumentResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description);

@override
String toString() {
  return 'AddDocumentResponse(id: $id, name: $name, description: $description)';
}


}

/// @nodoc
abstract mixin class _$AddDocumentResponseCopyWith<$Res> implements $AddDocumentResponseCopyWith<$Res> {
  factory _$AddDocumentResponseCopyWith(_AddDocumentResponse value, $Res Function(_AddDocumentResponse) _then) = __$AddDocumentResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String? id,@JsonKey(name: 'name') String? name,@JsonKey(name: 'description') String? description
});




}
/// @nodoc
class __$AddDocumentResponseCopyWithImpl<$Res>
    implements _$AddDocumentResponseCopyWith<$Res> {
  __$AddDocumentResponseCopyWithImpl(this._self, this._then);

  final _AddDocumentResponse _self;
  final $Res Function(_AddDocumentResponse) _then;

/// Create a copy of AddDocumentResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? name = freezed,Object? description = freezed,}) {
  return _then(_AddDocumentResponse(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
