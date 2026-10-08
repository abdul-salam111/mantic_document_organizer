// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'space_response_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SpaceResponseModel {

@JsonKey(name: 'id') String get id;@JsonKey(name: 'name') String get name;@JsonKey(name: 'owner_id') String get ownerId;@JsonKey(name: 'my_role') String? get myRole;
/// Create a copy of SpaceResponseModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpaceResponseModelCopyWith<SpaceResponseModel> get copyWith => _$SpaceResponseModelCopyWithImpl<SpaceResponseModel>(this as SpaceResponseModel, _$identity);

  /// Serializes this SpaceResponseModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpaceResponseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.myRole, myRole) || other.myRole == myRole));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,ownerId,myRole);

@override
String toString() {
  return 'SpaceResponseModel(id: $id, name: $name, ownerId: $ownerId, myRole: $myRole)';
}


}

/// @nodoc
abstract mixin class $SpaceResponseModelCopyWith<$Res>  {
  factory $SpaceResponseModelCopyWith(SpaceResponseModel value, $Res Function(SpaceResponseModel) _then) = _$SpaceResponseModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'name') String name,@JsonKey(name: 'owner_id') String ownerId,@JsonKey(name: 'my_role') String? myRole
});




}
/// @nodoc
class _$SpaceResponseModelCopyWithImpl<$Res>
    implements $SpaceResponseModelCopyWith<$Res> {
  _$SpaceResponseModelCopyWithImpl(this._self, this._then);

  final SpaceResponseModel _self;
  final $Res Function(SpaceResponseModel) _then;

/// Create a copy of SpaceResponseModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? ownerId = null,Object? myRole = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,myRole: freezed == myRole ? _self.myRole : myRole // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SpaceResponseModel].
extension SpaceResponseModelPatterns on SpaceResponseModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpaceResponseModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpaceResponseModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpaceResponseModel value)  $default,){
final _that = this;
switch (_that) {
case _SpaceResponseModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpaceResponseModel value)?  $default,){
final _that = this;
switch (_that) {
case _SpaceResponseModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'name')  String name, @JsonKey(name: 'owner_id')  String ownerId, @JsonKey(name: 'my_role')  String? myRole)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpaceResponseModel() when $default != null:
return $default(_that.id,_that.name,_that.ownerId,_that.myRole);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'name')  String name, @JsonKey(name: 'owner_id')  String ownerId, @JsonKey(name: 'my_role')  String? myRole)  $default,) {final _that = this;
switch (_that) {
case _SpaceResponseModel():
return $default(_that.id,_that.name,_that.ownerId,_that.myRole);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'name')  String name, @JsonKey(name: 'owner_id')  String ownerId, @JsonKey(name: 'my_role')  String? myRole)?  $default,) {final _that = this;
switch (_that) {
case _SpaceResponseModel() when $default != null:
return $default(_that.id,_that.name,_that.ownerId,_that.myRole);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SpaceResponseModel implements SpaceResponseModel {
  const _SpaceResponseModel({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'name') required this.name, @JsonKey(name: 'owner_id') required this.ownerId, @JsonKey(name: 'my_role') this.myRole});
  factory _SpaceResponseModel.fromJson(Map<String, dynamic> json) => _$SpaceResponseModelFromJson(json);

@override@JsonKey(name: 'id') final  String id;
@override@JsonKey(name: 'name') final  String name;
@override@JsonKey(name: 'owner_id') final  String ownerId;
@override@JsonKey(name: 'my_role') final  String? myRole;

/// Create a copy of SpaceResponseModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpaceResponseModelCopyWith<_SpaceResponseModel> get copyWith => __$SpaceResponseModelCopyWithImpl<_SpaceResponseModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SpaceResponseModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpaceResponseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.myRole, myRole) || other.myRole == myRole));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,ownerId,myRole);

@override
String toString() {
  return 'SpaceResponseModel(id: $id, name: $name, ownerId: $ownerId, myRole: $myRole)';
}


}

/// @nodoc
abstract mixin class _$SpaceResponseModelCopyWith<$Res> implements $SpaceResponseModelCopyWith<$Res> {
  factory _$SpaceResponseModelCopyWith(_SpaceResponseModel value, $Res Function(_SpaceResponseModel) _then) = __$SpaceResponseModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'name') String name,@JsonKey(name: 'owner_id') String ownerId,@JsonKey(name: 'my_role') String? myRole
});




}
/// @nodoc
class __$SpaceResponseModelCopyWithImpl<$Res>
    implements _$SpaceResponseModelCopyWith<$Res> {
  __$SpaceResponseModelCopyWithImpl(this._self, this._then);

  final _SpaceResponseModel _self;
  final $Res Function(_SpaceResponseModel) _then;

/// Create a copy of SpaceResponseModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? ownerId = null,Object? myRole = freezed,}) {
  return _then(_SpaceResponseModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,myRole: freezed == myRole ? _self.myRole : myRole // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
