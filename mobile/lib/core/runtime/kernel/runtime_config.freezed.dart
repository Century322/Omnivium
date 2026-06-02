// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'runtime_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RuntimeConfig {

 String get runtimeVersion; String get nodeId; int get defaultTimeoutMs; int get maxConcurrentTasks; int get maxPlugins; bool get enableHotReload; bool get enableAsyncDiscovery; int get maxEventBusCapacity; int get defaultRetryMaxAttempts; int get defaultRetryBackoffMs; double get defaultRetryBackoffMultiplier; int get defaultRetryMaxBackoffMs;
/// Create a copy of RuntimeConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RuntimeConfigCopyWith<RuntimeConfig> get copyWith => _$RuntimeConfigCopyWithImpl<RuntimeConfig>(this as RuntimeConfig, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RuntimeConfig&&(identical(other.runtimeVersion, runtimeVersion) || other.runtimeVersion == runtimeVersion)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId)&&(identical(other.defaultTimeoutMs, defaultTimeoutMs) || other.defaultTimeoutMs == defaultTimeoutMs)&&(identical(other.maxConcurrentTasks, maxConcurrentTasks) || other.maxConcurrentTasks == maxConcurrentTasks)&&(identical(other.maxPlugins, maxPlugins) || other.maxPlugins == maxPlugins)&&(identical(other.enableHotReload, enableHotReload) || other.enableHotReload == enableHotReload)&&(identical(other.enableAsyncDiscovery, enableAsyncDiscovery) || other.enableAsyncDiscovery == enableAsyncDiscovery)&&(identical(other.maxEventBusCapacity, maxEventBusCapacity) || other.maxEventBusCapacity == maxEventBusCapacity)&&(identical(other.defaultRetryMaxAttempts, defaultRetryMaxAttempts) || other.defaultRetryMaxAttempts == defaultRetryMaxAttempts)&&(identical(other.defaultRetryBackoffMs, defaultRetryBackoffMs) || other.defaultRetryBackoffMs == defaultRetryBackoffMs)&&(identical(other.defaultRetryBackoffMultiplier, defaultRetryBackoffMultiplier) || other.defaultRetryBackoffMultiplier == defaultRetryBackoffMultiplier)&&(identical(other.defaultRetryMaxBackoffMs, defaultRetryMaxBackoffMs) || other.defaultRetryMaxBackoffMs == defaultRetryMaxBackoffMs));
}


@override
int get hashCode => Object.hash(runtimeType,runtimeVersion,nodeId,defaultTimeoutMs,maxConcurrentTasks,maxPlugins,enableHotReload,enableAsyncDiscovery,maxEventBusCapacity,defaultRetryMaxAttempts,defaultRetryBackoffMs,defaultRetryBackoffMultiplier,defaultRetryMaxBackoffMs);

@override
String toString() {
  return 'RuntimeConfig(runtimeVersion: $runtimeVersion, nodeId: $nodeId, defaultTimeoutMs: $defaultTimeoutMs, maxConcurrentTasks: $maxConcurrentTasks, maxPlugins: $maxPlugins, enableHotReload: $enableHotReload, enableAsyncDiscovery: $enableAsyncDiscovery, maxEventBusCapacity: $maxEventBusCapacity, defaultRetryMaxAttempts: $defaultRetryMaxAttempts, defaultRetryBackoffMs: $defaultRetryBackoffMs, defaultRetryBackoffMultiplier: $defaultRetryBackoffMultiplier, defaultRetryMaxBackoffMs: $defaultRetryMaxBackoffMs)';
}


}

/// @nodoc
abstract mixin class $RuntimeConfigCopyWith<$Res>  {
  factory $RuntimeConfigCopyWith(RuntimeConfig value, $Res Function(RuntimeConfig) _then) = _$RuntimeConfigCopyWithImpl;
@useResult
$Res call({
 String runtimeVersion, String nodeId, int defaultTimeoutMs, int maxConcurrentTasks, int maxPlugins, bool enableHotReload, bool enableAsyncDiscovery, int maxEventBusCapacity, int defaultRetryMaxAttempts, int defaultRetryBackoffMs, double defaultRetryBackoffMultiplier, int defaultRetryMaxBackoffMs
});




}
/// @nodoc
class _$RuntimeConfigCopyWithImpl<$Res>
    implements $RuntimeConfigCopyWith<$Res> {
  _$RuntimeConfigCopyWithImpl(this._self, this._then);

  final RuntimeConfig _self;
  final $Res Function(RuntimeConfig) _then;

/// Create a copy of RuntimeConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? runtimeVersion = null,Object? nodeId = null,Object? defaultTimeoutMs = null,Object? maxConcurrentTasks = null,Object? maxPlugins = null,Object? enableHotReload = null,Object? enableAsyncDiscovery = null,Object? maxEventBusCapacity = null,Object? defaultRetryMaxAttempts = null,Object? defaultRetryBackoffMs = null,Object? defaultRetryBackoffMultiplier = null,Object? defaultRetryMaxBackoffMs = null,}) {
  return _then(_self.copyWith(
runtimeVersion: null == runtimeVersion ? _self.runtimeVersion : runtimeVersion // ignore: cast_nullable_to_non_nullable
as String,nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,defaultTimeoutMs: null == defaultTimeoutMs ? _self.defaultTimeoutMs : defaultTimeoutMs // ignore: cast_nullable_to_non_nullable
as int,maxConcurrentTasks: null == maxConcurrentTasks ? _self.maxConcurrentTasks : maxConcurrentTasks // ignore: cast_nullable_to_non_nullable
as int,maxPlugins: null == maxPlugins ? _self.maxPlugins : maxPlugins // ignore: cast_nullable_to_non_nullable
as int,enableHotReload: null == enableHotReload ? _self.enableHotReload : enableHotReload // ignore: cast_nullable_to_non_nullable
as bool,enableAsyncDiscovery: null == enableAsyncDiscovery ? _self.enableAsyncDiscovery : enableAsyncDiscovery // ignore: cast_nullable_to_non_nullable
as bool,maxEventBusCapacity: null == maxEventBusCapacity ? _self.maxEventBusCapacity : maxEventBusCapacity // ignore: cast_nullable_to_non_nullable
as int,defaultRetryMaxAttempts: null == defaultRetryMaxAttempts ? _self.defaultRetryMaxAttempts : defaultRetryMaxAttempts // ignore: cast_nullable_to_non_nullable
as int,defaultRetryBackoffMs: null == defaultRetryBackoffMs ? _self.defaultRetryBackoffMs : defaultRetryBackoffMs // ignore: cast_nullable_to_non_nullable
as int,defaultRetryBackoffMultiplier: null == defaultRetryBackoffMultiplier ? _self.defaultRetryBackoffMultiplier : defaultRetryBackoffMultiplier // ignore: cast_nullable_to_non_nullable
as double,defaultRetryMaxBackoffMs: null == defaultRetryMaxBackoffMs ? _self.defaultRetryMaxBackoffMs : defaultRetryMaxBackoffMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RuntimeConfig].
extension RuntimeConfigPatterns on RuntimeConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RuntimeConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RuntimeConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RuntimeConfig value)  $default,){
final _that = this;
switch (_that) {
case _RuntimeConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RuntimeConfig value)?  $default,){
final _that = this;
switch (_that) {
case _RuntimeConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String runtimeVersion,  String nodeId,  int defaultTimeoutMs,  int maxConcurrentTasks,  int maxPlugins,  bool enableHotReload,  bool enableAsyncDiscovery,  int maxEventBusCapacity,  int defaultRetryMaxAttempts,  int defaultRetryBackoffMs,  double defaultRetryBackoffMultiplier,  int defaultRetryMaxBackoffMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RuntimeConfig() when $default != null:
return $default(_that.runtimeVersion,_that.nodeId,_that.defaultTimeoutMs,_that.maxConcurrentTasks,_that.maxPlugins,_that.enableHotReload,_that.enableAsyncDiscovery,_that.maxEventBusCapacity,_that.defaultRetryMaxAttempts,_that.defaultRetryBackoffMs,_that.defaultRetryBackoffMultiplier,_that.defaultRetryMaxBackoffMs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String runtimeVersion,  String nodeId,  int defaultTimeoutMs,  int maxConcurrentTasks,  int maxPlugins,  bool enableHotReload,  bool enableAsyncDiscovery,  int maxEventBusCapacity,  int defaultRetryMaxAttempts,  int defaultRetryBackoffMs,  double defaultRetryBackoffMultiplier,  int defaultRetryMaxBackoffMs)  $default,) {final _that = this;
switch (_that) {
case _RuntimeConfig():
return $default(_that.runtimeVersion,_that.nodeId,_that.defaultTimeoutMs,_that.maxConcurrentTasks,_that.maxPlugins,_that.enableHotReload,_that.enableAsyncDiscovery,_that.maxEventBusCapacity,_that.defaultRetryMaxAttempts,_that.defaultRetryBackoffMs,_that.defaultRetryBackoffMultiplier,_that.defaultRetryMaxBackoffMs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String runtimeVersion,  String nodeId,  int defaultTimeoutMs,  int maxConcurrentTasks,  int maxPlugins,  bool enableHotReload,  bool enableAsyncDiscovery,  int maxEventBusCapacity,  int defaultRetryMaxAttempts,  int defaultRetryBackoffMs,  double defaultRetryBackoffMultiplier,  int defaultRetryMaxBackoffMs)?  $default,) {final _that = this;
switch (_that) {
case _RuntimeConfig() when $default != null:
return $default(_that.runtimeVersion,_that.nodeId,_that.defaultTimeoutMs,_that.maxConcurrentTasks,_that.maxPlugins,_that.enableHotReload,_that.enableAsyncDiscovery,_that.maxEventBusCapacity,_that.defaultRetryMaxAttempts,_that.defaultRetryBackoffMs,_that.defaultRetryBackoffMultiplier,_that.defaultRetryMaxBackoffMs);case _:
  return null;

}
}

}

/// @nodoc


class _RuntimeConfig implements RuntimeConfig {
  const _RuntimeConfig({this.runtimeVersion = '1.0.0', this.nodeId = 'local', this.defaultTimeoutMs = 30000, this.maxConcurrentTasks = 16, this.maxPlugins = 64, this.enableHotReload = true, this.enableAsyncDiscovery = true, this.maxEventBusCapacity = 1024, this.defaultRetryMaxAttempts = 3, this.defaultRetryBackoffMs = 100, this.defaultRetryBackoffMultiplier = 2.0, this.defaultRetryMaxBackoffMs = 10000});
  

@override@JsonKey() final  String runtimeVersion;
@override@JsonKey() final  String nodeId;
@override@JsonKey() final  int defaultTimeoutMs;
@override@JsonKey() final  int maxConcurrentTasks;
@override@JsonKey() final  int maxPlugins;
@override@JsonKey() final  bool enableHotReload;
@override@JsonKey() final  bool enableAsyncDiscovery;
@override@JsonKey() final  int maxEventBusCapacity;
@override@JsonKey() final  int defaultRetryMaxAttempts;
@override@JsonKey() final  int defaultRetryBackoffMs;
@override@JsonKey() final  double defaultRetryBackoffMultiplier;
@override@JsonKey() final  int defaultRetryMaxBackoffMs;

/// Create a copy of RuntimeConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RuntimeConfigCopyWith<_RuntimeConfig> get copyWith => __$RuntimeConfigCopyWithImpl<_RuntimeConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RuntimeConfig&&(identical(other.runtimeVersion, runtimeVersion) || other.runtimeVersion == runtimeVersion)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId)&&(identical(other.defaultTimeoutMs, defaultTimeoutMs) || other.defaultTimeoutMs == defaultTimeoutMs)&&(identical(other.maxConcurrentTasks, maxConcurrentTasks) || other.maxConcurrentTasks == maxConcurrentTasks)&&(identical(other.maxPlugins, maxPlugins) || other.maxPlugins == maxPlugins)&&(identical(other.enableHotReload, enableHotReload) || other.enableHotReload == enableHotReload)&&(identical(other.enableAsyncDiscovery, enableAsyncDiscovery) || other.enableAsyncDiscovery == enableAsyncDiscovery)&&(identical(other.maxEventBusCapacity, maxEventBusCapacity) || other.maxEventBusCapacity == maxEventBusCapacity)&&(identical(other.defaultRetryMaxAttempts, defaultRetryMaxAttempts) || other.defaultRetryMaxAttempts == defaultRetryMaxAttempts)&&(identical(other.defaultRetryBackoffMs, defaultRetryBackoffMs) || other.defaultRetryBackoffMs == defaultRetryBackoffMs)&&(identical(other.defaultRetryBackoffMultiplier, defaultRetryBackoffMultiplier) || other.defaultRetryBackoffMultiplier == defaultRetryBackoffMultiplier)&&(identical(other.defaultRetryMaxBackoffMs, defaultRetryMaxBackoffMs) || other.defaultRetryMaxBackoffMs == defaultRetryMaxBackoffMs));
}


@override
int get hashCode => Object.hash(runtimeType,runtimeVersion,nodeId,defaultTimeoutMs,maxConcurrentTasks,maxPlugins,enableHotReload,enableAsyncDiscovery,maxEventBusCapacity,defaultRetryMaxAttempts,defaultRetryBackoffMs,defaultRetryBackoffMultiplier,defaultRetryMaxBackoffMs);

@override
String toString() {
  return 'RuntimeConfig(runtimeVersion: $runtimeVersion, nodeId: $nodeId, defaultTimeoutMs: $defaultTimeoutMs, maxConcurrentTasks: $maxConcurrentTasks, maxPlugins: $maxPlugins, enableHotReload: $enableHotReload, enableAsyncDiscovery: $enableAsyncDiscovery, maxEventBusCapacity: $maxEventBusCapacity, defaultRetryMaxAttempts: $defaultRetryMaxAttempts, defaultRetryBackoffMs: $defaultRetryBackoffMs, defaultRetryBackoffMultiplier: $defaultRetryBackoffMultiplier, defaultRetryMaxBackoffMs: $defaultRetryMaxBackoffMs)';
}


}

/// @nodoc
abstract mixin class _$RuntimeConfigCopyWith<$Res> implements $RuntimeConfigCopyWith<$Res> {
  factory _$RuntimeConfigCopyWith(_RuntimeConfig value, $Res Function(_RuntimeConfig) _then) = __$RuntimeConfigCopyWithImpl;
@override @useResult
$Res call({
 String runtimeVersion, String nodeId, int defaultTimeoutMs, int maxConcurrentTasks, int maxPlugins, bool enableHotReload, bool enableAsyncDiscovery, int maxEventBusCapacity, int defaultRetryMaxAttempts, int defaultRetryBackoffMs, double defaultRetryBackoffMultiplier, int defaultRetryMaxBackoffMs
});




}
/// @nodoc
class __$RuntimeConfigCopyWithImpl<$Res>
    implements _$RuntimeConfigCopyWith<$Res> {
  __$RuntimeConfigCopyWithImpl(this._self, this._then);

  final _RuntimeConfig _self;
  final $Res Function(_RuntimeConfig) _then;

/// Create a copy of RuntimeConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? runtimeVersion = null,Object? nodeId = null,Object? defaultTimeoutMs = null,Object? maxConcurrentTasks = null,Object? maxPlugins = null,Object? enableHotReload = null,Object? enableAsyncDiscovery = null,Object? maxEventBusCapacity = null,Object? defaultRetryMaxAttempts = null,Object? defaultRetryBackoffMs = null,Object? defaultRetryBackoffMultiplier = null,Object? defaultRetryMaxBackoffMs = null,}) {
  return _then(_RuntimeConfig(
runtimeVersion: null == runtimeVersion ? _self.runtimeVersion : runtimeVersion // ignore: cast_nullable_to_non_nullable
as String,nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,defaultTimeoutMs: null == defaultTimeoutMs ? _self.defaultTimeoutMs : defaultTimeoutMs // ignore: cast_nullable_to_non_nullable
as int,maxConcurrentTasks: null == maxConcurrentTasks ? _self.maxConcurrentTasks : maxConcurrentTasks // ignore: cast_nullable_to_non_nullable
as int,maxPlugins: null == maxPlugins ? _self.maxPlugins : maxPlugins // ignore: cast_nullable_to_non_nullable
as int,enableHotReload: null == enableHotReload ? _self.enableHotReload : enableHotReload // ignore: cast_nullable_to_non_nullable
as bool,enableAsyncDiscovery: null == enableAsyncDiscovery ? _self.enableAsyncDiscovery : enableAsyncDiscovery // ignore: cast_nullable_to_non_nullable
as bool,maxEventBusCapacity: null == maxEventBusCapacity ? _self.maxEventBusCapacity : maxEventBusCapacity // ignore: cast_nullable_to_non_nullable
as int,defaultRetryMaxAttempts: null == defaultRetryMaxAttempts ? _self.defaultRetryMaxAttempts : defaultRetryMaxAttempts // ignore: cast_nullable_to_non_nullable
as int,defaultRetryBackoffMs: null == defaultRetryBackoffMs ? _self.defaultRetryBackoffMs : defaultRetryBackoffMs // ignore: cast_nullable_to_non_nullable
as int,defaultRetryBackoffMultiplier: null == defaultRetryBackoffMultiplier ? _self.defaultRetryBackoffMultiplier : defaultRetryBackoffMultiplier // ignore: cast_nullable_to_non_nullable
as double,defaultRetryMaxBackoffMs: null == defaultRetryMaxBackoffMs ? _self.defaultRetryMaxBackoffMs : defaultRetryMaxBackoffMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
