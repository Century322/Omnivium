// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'runtime_route.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RuntimeRoute {

 String get capability; String get pluginId; String get instanceId; String get nodeId;
/// Create a copy of RuntimeRoute
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RuntimeRouteCopyWith<RuntimeRoute> get copyWith => _$RuntimeRouteCopyWithImpl<RuntimeRoute>(this as RuntimeRoute, _$identity);

  /// Serializes this RuntimeRoute to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RuntimeRoute&&(identical(other.capability, capability) || other.capability == capability)&&(identical(other.pluginId, pluginId) || other.pluginId == pluginId)&&(identical(other.instanceId, instanceId) || other.instanceId == instanceId)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,capability,pluginId,instanceId,nodeId);

@override
String toString() {
  return 'RuntimeRoute(capability: $capability, pluginId: $pluginId, instanceId: $instanceId, nodeId: $nodeId)';
}


}

/// @nodoc
abstract mixin class $RuntimeRouteCopyWith<$Res>  {
  factory $RuntimeRouteCopyWith(RuntimeRoute value, $Res Function(RuntimeRoute) _then) = _$RuntimeRouteCopyWithImpl;
@useResult
$Res call({
 String capability, String pluginId, String instanceId, String nodeId
});




}
/// @nodoc
class _$RuntimeRouteCopyWithImpl<$Res>
    implements $RuntimeRouteCopyWith<$Res> {
  _$RuntimeRouteCopyWithImpl(this._self, this._then);

  final RuntimeRoute _self;
  final $Res Function(RuntimeRoute) _then;

/// Create a copy of RuntimeRoute
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? capability = null,Object? pluginId = null,Object? instanceId = null,Object? nodeId = null,}) {
  return _then(_self.copyWith(
capability: null == capability ? _self.capability : capability // ignore: cast_nullable_to_non_nullable
as String,pluginId: null == pluginId ? _self.pluginId : pluginId // ignore: cast_nullable_to_non_nullable
as String,instanceId: null == instanceId ? _self.instanceId : instanceId // ignore: cast_nullable_to_non_nullable
as String,nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RuntimeRoute].
extension RuntimeRoutePatterns on RuntimeRoute {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RuntimeRoute value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RuntimeRoute() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RuntimeRoute value)  $default,){
final _that = this;
switch (_that) {
case _RuntimeRoute():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RuntimeRoute value)?  $default,){
final _that = this;
switch (_that) {
case _RuntimeRoute() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String capability,  String pluginId,  String instanceId,  String nodeId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RuntimeRoute() when $default != null:
return $default(_that.capability,_that.pluginId,_that.instanceId,_that.nodeId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String capability,  String pluginId,  String instanceId,  String nodeId)  $default,) {final _that = this;
switch (_that) {
case _RuntimeRoute():
return $default(_that.capability,_that.pluginId,_that.instanceId,_that.nodeId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String capability,  String pluginId,  String instanceId,  String nodeId)?  $default,) {final _that = this;
switch (_that) {
case _RuntimeRoute() when $default != null:
return $default(_that.capability,_that.pluginId,_that.instanceId,_that.nodeId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RuntimeRoute extends RuntimeRoute {
  const _RuntimeRoute({required this.capability, required this.pluginId, this.instanceId = 'default', this.nodeId = 'local'}): super._();
  factory _RuntimeRoute.fromJson(Map<String, dynamic> json) => _$RuntimeRouteFromJson(json);

@override final  String capability;
@override final  String pluginId;
@override@JsonKey() final  String instanceId;
@override@JsonKey() final  String nodeId;

/// Create a copy of RuntimeRoute
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RuntimeRouteCopyWith<_RuntimeRoute> get copyWith => __$RuntimeRouteCopyWithImpl<_RuntimeRoute>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RuntimeRouteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RuntimeRoute&&(identical(other.capability, capability) || other.capability == capability)&&(identical(other.pluginId, pluginId) || other.pluginId == pluginId)&&(identical(other.instanceId, instanceId) || other.instanceId == instanceId)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,capability,pluginId,instanceId,nodeId);

@override
String toString() {
  return 'RuntimeRoute(capability: $capability, pluginId: $pluginId, instanceId: $instanceId, nodeId: $nodeId)';
}


}

/// @nodoc
abstract mixin class _$RuntimeRouteCopyWith<$Res> implements $RuntimeRouteCopyWith<$Res> {
  factory _$RuntimeRouteCopyWith(_RuntimeRoute value, $Res Function(_RuntimeRoute) _then) = __$RuntimeRouteCopyWithImpl;
@override @useResult
$Res call({
 String capability, String pluginId, String instanceId, String nodeId
});




}
/// @nodoc
class __$RuntimeRouteCopyWithImpl<$Res>
    implements _$RuntimeRouteCopyWith<$Res> {
  __$RuntimeRouteCopyWithImpl(this._self, this._then);

  final _RuntimeRoute _self;
  final $Res Function(_RuntimeRoute) _then;

/// Create a copy of RuntimeRoute
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? capability = null,Object? pluginId = null,Object? instanceId = null,Object? nodeId = null,}) {
  return _then(_RuntimeRoute(
capability: null == capability ? _self.capability : capability // ignore: cast_nullable_to_non_nullable
as String,pluginId: null == pluginId ? _self.pluginId : pluginId // ignore: cast_nullable_to_non_nullable
as String,instanceId: null == instanceId ? _self.instanceId : instanceId // ignore: cast_nullable_to_non_nullable
as String,nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
