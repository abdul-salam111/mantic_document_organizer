// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'signup_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SignupUser {

@JsonKey(name: "name") String? get name;@JsonKey(name: "email") String? get email;@JsonKey(name: "password") String? get password;
/// Create a copy of SignupUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignupUserCopyWith<SignupUser> get copyWith => _$SignupUserCopyWithImpl<SignupUser>(this as SignupUser, _$identity);

  /// Serializes this SignupUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignupUser&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,email,password);

@override
String toString() {
  return 'SignupUser(name: $name, email: $email, password: $password)';
}


}

/// @nodoc
abstract mixin class $SignupUserCopyWith<$Res>  {
  factory $SignupUserCopyWith(SignupUser value, $Res Function(SignupUser) _then) = _$SignupUserCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "name") String? name,@JsonKey(name: "email") String? email,@JsonKey(name: "password") String? password
});




}
/// @nodoc
class _$SignupUserCopyWithImpl<$Res>
    implements $SignupUserCopyWith<$Res> {
  _$SignupUserCopyWithImpl(this._self, this._then);

  final SignupUser _self;
  final $Res Function(SignupUser) _then;

/// Create a copy of SignupUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? email = freezed,Object? password = freezed,}) {
  return _then(_self.copyWith(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,password: freezed == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SignupUser].
extension SignupUserPatterns on SignupUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SignupUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SignupUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SignupUser value)  $default,){
final _that = this;
switch (_that) {
case _SignupUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SignupUser value)?  $default,){
final _that = this;
switch (_that) {
case _SignupUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "name")  String? name, @JsonKey(name: "email")  String? email, @JsonKey(name: "password")  String? password)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SignupUser() when $default != null:
return $default(_that.name,_that.email,_that.password);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "name")  String? name, @JsonKey(name: "email")  String? email, @JsonKey(name: "password")  String? password)  $default,) {final _that = this;
switch (_that) {
case _SignupUser():
return $default(_that.name,_that.email,_that.password);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "name")  String? name, @JsonKey(name: "email")  String? email, @JsonKey(name: "password")  String? password)?  $default,) {final _that = this;
switch (_that) {
case _SignupUser() when $default != null:
return $default(_that.name,_that.email,_that.password);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SignupUser implements SignupUser {
  const _SignupUser({@JsonKey(name: "name") this.name, @JsonKey(name: "email") this.email, @JsonKey(name: "password") this.password});
  factory _SignupUser.fromJson(Map<String, dynamic> json) => _$SignupUserFromJson(json);

@override@JsonKey(name: "name") final  String? name;
@override@JsonKey(name: "email") final  String? email;
@override@JsonKey(name: "password") final  String? password;

/// Create a copy of SignupUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SignupUserCopyWith<_SignupUser> get copyWith => __$SignupUserCopyWithImpl<_SignupUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SignupUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignupUser&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,email,password);

@override
String toString() {
  return 'SignupUser(name: $name, email: $email, password: $password)';
}


}

/// @nodoc
abstract mixin class _$SignupUserCopyWith<$Res> implements $SignupUserCopyWith<$Res> {
  factory _$SignupUserCopyWith(_SignupUser value, $Res Function(_SignupUser) _then) = __$SignupUserCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "name") String? name,@JsonKey(name: "email") String? email,@JsonKey(name: "password") String? password
});




}
/// @nodoc
class __$SignupUserCopyWithImpl<$Res>
    implements _$SignupUserCopyWith<$Res> {
  __$SignupUserCopyWithImpl(this._self, this._then);

  final _SignupUser _self;
  final $Res Function(_SignupUser) _then;

/// Create a copy of SignupUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? email = freezed,Object? password = freezed,}) {
  return _then(_SignupUser(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,password: freezed == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
