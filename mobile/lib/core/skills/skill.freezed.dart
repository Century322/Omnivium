// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'skill.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SkillResult {

 bool get success; Object? get data; String? get error;
/// Create a copy of SkillResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillResultCopyWith<SkillResult> get copyWith => _$SkillResultCopyWithImpl<SkillResult>(this as SkillResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillResult&&(identical(other.success, success) || other.success == success)&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,success,const DeepCollectionEquality().hash(data),error);

@override
String toString() {
  return 'SkillResult(success: $success, data: $data, error: $error)';
}


}

/// @nodoc
abstract mixin class $SkillResultCopyWith<$Res>  {
  factory $SkillResultCopyWith(SkillResult value, $Res Function(SkillResult) _then) = _$SkillResultCopyWithImpl;
@useResult
$Res call({
 bool success, Object? data, String? error
});




}
/// @nodoc
class _$SkillResultCopyWithImpl<$Res>
    implements $SkillResultCopyWith<$Res> {
  _$SkillResultCopyWithImpl(this._self, this._then);

  final SkillResult _self;
  final $Res Function(SkillResult) _then;

/// Create a copy of SkillResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? success = null,Object? data = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,data: freezed == data ? _self.data : data ,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillResult].
extension SkillResultPatterns on SkillResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillResult value)  $default,){
final _that = this;
switch (_that) {
case _SkillResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillResult value)?  $default,){
final _that = this;
switch (_that) {
case _SkillResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool success,  Object? data,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillResult() when $default != null:
return $default(_that.success,_that.data,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool success,  Object? data,  String? error)  $default,) {final _that = this;
switch (_that) {
case _SkillResult():
return $default(_that.success,_that.data,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool success,  Object? data,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _SkillResult() when $default != null:
return $default(_that.success,_that.data,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _SkillResult extends SkillResult {
  const _SkillResult({required this.success, this.data, this.error}): super._();
  

@override final  bool success;
@override final  Object? data;
@override final  String? error;

/// Create a copy of SkillResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillResultCopyWith<_SkillResult> get copyWith => __$SkillResultCopyWithImpl<_SkillResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillResult&&(identical(other.success, success) || other.success == success)&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,success,const DeepCollectionEquality().hash(data),error);

@override
String toString() {
  return 'SkillResult(success: $success, data: $data, error: $error)';
}


}

/// @nodoc
abstract mixin class _$SkillResultCopyWith<$Res> implements $SkillResultCopyWith<$Res> {
  factory _$SkillResultCopyWith(_SkillResult value, $Res Function(_SkillResult) _then) = __$SkillResultCopyWithImpl;
@override @useResult
$Res call({
 bool success, Object? data, String? error
});




}
/// @nodoc
class __$SkillResultCopyWithImpl<$Res>
    implements _$SkillResultCopyWith<$Res> {
  __$SkillResultCopyWithImpl(this._self, this._then);

  final _SkillResult _self;
  final $Res Function(_SkillResult) _then;

/// Create a copy of SkillResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? success = null,Object? data = freezed,Object? error = freezed,}) {
  return _then(_SkillResult(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,data: freezed == data ? _self.data : data ,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$SkillVersion {

 int get major; int get minor; int get patch;
/// Create a copy of SkillVersion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillVersionCopyWith<SkillVersion> get copyWith => _$SkillVersionCopyWithImpl<SkillVersion>(this as SkillVersion, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillVersion&&(identical(other.major, major) || other.major == major)&&(identical(other.minor, minor) || other.minor == minor)&&(identical(other.patch, patch) || other.patch == patch));
}


@override
int get hashCode => Object.hash(runtimeType,major,minor,patch);

@override
String toString() {
  return 'SkillVersion(major: $major, minor: $minor, patch: $patch)';
}


}

/// @nodoc
abstract mixin class $SkillVersionCopyWith<$Res>  {
  factory $SkillVersionCopyWith(SkillVersion value, $Res Function(SkillVersion) _then) = _$SkillVersionCopyWithImpl;
@useResult
$Res call({
 int major, int minor, int patch
});




}
/// @nodoc
class _$SkillVersionCopyWithImpl<$Res>
    implements $SkillVersionCopyWith<$Res> {
  _$SkillVersionCopyWithImpl(this._self, this._then);

  final SkillVersion _self;
  final $Res Function(SkillVersion) _then;

/// Create a copy of SkillVersion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? major = null,Object? minor = null,Object? patch = null,}) {
  return _then(_self.copyWith(
major: null == major ? _self.major : major // ignore: cast_nullable_to_non_nullable
as int,minor: null == minor ? _self.minor : minor // ignore: cast_nullable_to_non_nullable
as int,patch: null == patch ? _self.patch : patch // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillVersion].
extension SkillVersionPatterns on SkillVersion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillVersion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillVersion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillVersion value)  $default,){
final _that = this;
switch (_that) {
case _SkillVersion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillVersion value)?  $default,){
final _that = this;
switch (_that) {
case _SkillVersion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int major,  int minor,  int patch)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillVersion() when $default != null:
return $default(_that.major,_that.minor,_that.patch);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int major,  int minor,  int patch)  $default,) {final _that = this;
switch (_that) {
case _SkillVersion():
return $default(_that.major,_that.minor,_that.patch);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int major,  int minor,  int patch)?  $default,) {final _that = this;
switch (_that) {
case _SkillVersion() when $default != null:
return $default(_that.major,_that.minor,_that.patch);case _:
  return null;

}
}

}

/// @nodoc


class _SkillVersion extends SkillVersion {
  const _SkillVersion({required this.major, this.minor = 0, this.patch = 0}): super._();
  

@override final  int major;
@override@JsonKey() final  int minor;
@override@JsonKey() final  int patch;

/// Create a copy of SkillVersion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillVersionCopyWith<_SkillVersion> get copyWith => __$SkillVersionCopyWithImpl<_SkillVersion>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillVersion&&(identical(other.major, major) || other.major == major)&&(identical(other.minor, minor) || other.minor == minor)&&(identical(other.patch, patch) || other.patch == patch));
}


@override
int get hashCode => Object.hash(runtimeType,major,minor,patch);

@override
String toString() {
  return 'SkillVersion(major: $major, minor: $minor, patch: $patch)';
}


}

/// @nodoc
abstract mixin class _$SkillVersionCopyWith<$Res> implements $SkillVersionCopyWith<$Res> {
  factory _$SkillVersionCopyWith(_SkillVersion value, $Res Function(_SkillVersion) _then) = __$SkillVersionCopyWithImpl;
@override @useResult
$Res call({
 int major, int minor, int patch
});




}
/// @nodoc
class __$SkillVersionCopyWithImpl<$Res>
    implements _$SkillVersionCopyWith<$Res> {
  __$SkillVersionCopyWithImpl(this._self, this._then);

  final _SkillVersion _self;
  final $Res Function(_SkillVersion) _then;

/// Create a copy of SkillVersion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? major = null,Object? minor = null,Object? patch = null,}) {
  return _then(_SkillVersion(
major: null == major ? _self.major : major // ignore: cast_nullable_to_non_nullable
as int,minor: null == minor ? _self.minor : minor // ignore: cast_nullable_to_non_nullable
as int,patch: null == patch ? _self.patch : patch // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
