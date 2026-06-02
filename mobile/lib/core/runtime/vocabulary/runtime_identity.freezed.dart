// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'runtime_identity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RuntimeIdentity {

 String get identity; String get instance; String get node;
/// Create a copy of RuntimeIdentity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RuntimeIdentityCopyWith<RuntimeIdentity> get copyWith => _$RuntimeIdentityCopyWithImpl<RuntimeIdentity>(this as RuntimeIdentity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RuntimeIdentity&&(identical(other.identity, identity) || other.identity == identity)&&(identical(other.instance, instance) || other.instance == instance)&&(identical(other.node, node) || other.node == node));
}


@override
int get hashCode => Object.hash(runtimeType,identity,instance,node);

@override
String toString() {
  return 'RuntimeIdentity(identity: $identity, instance: $instance, node: $node)';
}


}

/// @nodoc
abstract mixin class $RuntimeIdentityCopyWith<$Res>  {
  factory $RuntimeIdentityCopyWith(RuntimeIdentity value, $Res Function(RuntimeIdentity) _then) = _$RuntimeIdentityCopyWithImpl;
@useResult
$Res call({
 String identity, String instance, String node
});




}
/// @nodoc
class _$RuntimeIdentityCopyWithImpl<$Res>
    implements $RuntimeIdentityCopyWith<$Res> {
  _$RuntimeIdentityCopyWithImpl(this._self, this._then);

  final RuntimeIdentity _self;
  final $Res Function(RuntimeIdentity) _then;

/// Create a copy of RuntimeIdentity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? identity = null,Object? instance = null,Object? node = null,}) {
  return _then(_self.copyWith(
identity: null == identity ? _self.identity : identity // ignore: cast_nullable_to_non_nullable
as String,instance: null == instance ? _self.instance : instance // ignore: cast_nullable_to_non_nullable
as String,node: null == node ? _self.node : node // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RuntimeIdentity].
extension RuntimeIdentityPatterns on RuntimeIdentity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RuntimeIdentity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RuntimeIdentity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RuntimeIdentity value)  $default,){
final _that = this;
switch (_that) {
case _RuntimeIdentity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RuntimeIdentity value)?  $default,){
final _that = this;
switch (_that) {
case _RuntimeIdentity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String identity,  String instance,  String node)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RuntimeIdentity() when $default != null:
return $default(_that.identity,_that.instance,_that.node);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String identity,  String instance,  String node)  $default,) {final _that = this;
switch (_that) {
case _RuntimeIdentity():
return $default(_that.identity,_that.instance,_that.node);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String identity,  String instance,  String node)?  $default,) {final _that = this;
switch (_that) {
case _RuntimeIdentity() when $default != null:
return $default(_that.identity,_that.instance,_that.node);case _:
  return null;

}
}

}

/// @nodoc


class _RuntimeIdentity extends RuntimeIdentity {
  const _RuntimeIdentity({required this.identity, this.instance = 'default', this.node = 'local'}): super._();
  

@override final  String identity;
@override@JsonKey() final  String instance;
@override@JsonKey() final  String node;

/// Create a copy of RuntimeIdentity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RuntimeIdentityCopyWith<_RuntimeIdentity> get copyWith => __$RuntimeIdentityCopyWithImpl<_RuntimeIdentity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RuntimeIdentity&&(identical(other.identity, identity) || other.identity == identity)&&(identical(other.instance, instance) || other.instance == instance)&&(identical(other.node, node) || other.node == node));
}


@override
int get hashCode => Object.hash(runtimeType,identity,instance,node);

@override
String toString() {
  return 'RuntimeIdentity(identity: $identity, instance: $instance, node: $node)';
}


}

/// @nodoc
abstract mixin class _$RuntimeIdentityCopyWith<$Res> implements $RuntimeIdentityCopyWith<$Res> {
  factory _$RuntimeIdentityCopyWith(_RuntimeIdentity value, $Res Function(_RuntimeIdentity) _then) = __$RuntimeIdentityCopyWithImpl;
@override @useResult
$Res call({
 String identity, String instance, String node
});




}
/// @nodoc
class __$RuntimeIdentityCopyWithImpl<$Res>
    implements _$RuntimeIdentityCopyWith<$Res> {
  __$RuntimeIdentityCopyWithImpl(this._self, this._then);

  final _RuntimeIdentity _self;
  final $Res Function(_RuntimeIdentity) _then;

/// Create a copy of RuntimeIdentity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? identity = null,Object? instance = null,Object? node = null,}) {
  return _then(_RuntimeIdentity(
identity: null == identity ? _self.identity : identity // ignore: cast_nullable_to_non_nullable
as String,instance: null == instance ? _self.instance : instance // ignore: cast_nullable_to_non_nullable
as String,node: null == node ? _self.node : node // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
