// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'runtime_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RuntimeStateSnapshot {

 RuntimeStatus get status; int get activeSessionCount; int get activeTaskCount; int get loadedPluginCount; int get activePluginCount; int get capabilityCount; int get bootTimeMs; int get uptimeMs;
/// Create a copy of RuntimeStateSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RuntimeStateSnapshotCopyWith<RuntimeStateSnapshot> get copyWith => _$RuntimeStateSnapshotCopyWithImpl<RuntimeStateSnapshot>(this as RuntimeStateSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RuntimeStateSnapshot&&(identical(other.status, status) || other.status == status)&&(identical(other.activeSessionCount, activeSessionCount) || other.activeSessionCount == activeSessionCount)&&(identical(other.activeTaskCount, activeTaskCount) || other.activeTaskCount == activeTaskCount)&&(identical(other.loadedPluginCount, loadedPluginCount) || other.loadedPluginCount == loadedPluginCount)&&(identical(other.activePluginCount, activePluginCount) || other.activePluginCount == activePluginCount)&&(identical(other.capabilityCount, capabilityCount) || other.capabilityCount == capabilityCount)&&(identical(other.bootTimeMs, bootTimeMs) || other.bootTimeMs == bootTimeMs)&&(identical(other.uptimeMs, uptimeMs) || other.uptimeMs == uptimeMs));
}


@override
int get hashCode => Object.hash(runtimeType,status,activeSessionCount,activeTaskCount,loadedPluginCount,activePluginCount,capabilityCount,bootTimeMs,uptimeMs);

@override
String toString() {
  return 'RuntimeStateSnapshot(status: $status, activeSessionCount: $activeSessionCount, activeTaskCount: $activeTaskCount, loadedPluginCount: $loadedPluginCount, activePluginCount: $activePluginCount, capabilityCount: $capabilityCount, bootTimeMs: $bootTimeMs, uptimeMs: $uptimeMs)';
}


}

/// @nodoc
abstract mixin class $RuntimeStateSnapshotCopyWith<$Res>  {
  factory $RuntimeStateSnapshotCopyWith(RuntimeStateSnapshot value, $Res Function(RuntimeStateSnapshot) _then) = _$RuntimeStateSnapshotCopyWithImpl;
@useResult
$Res call({
 RuntimeStatus status, int activeSessionCount, int activeTaskCount, int loadedPluginCount, int activePluginCount, int capabilityCount, int bootTimeMs, int uptimeMs
});




}
/// @nodoc
class _$RuntimeStateSnapshotCopyWithImpl<$Res>
    implements $RuntimeStateSnapshotCopyWith<$Res> {
  _$RuntimeStateSnapshotCopyWithImpl(this._self, this._then);

  final RuntimeStateSnapshot _self;
  final $Res Function(RuntimeStateSnapshot) _then;

/// Create a copy of RuntimeStateSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? activeSessionCount = null,Object? activeTaskCount = null,Object? loadedPluginCount = null,Object? activePluginCount = null,Object? capabilityCount = null,Object? bootTimeMs = null,Object? uptimeMs = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RuntimeStatus,activeSessionCount: null == activeSessionCount ? _self.activeSessionCount : activeSessionCount // ignore: cast_nullable_to_non_nullable
as int,activeTaskCount: null == activeTaskCount ? _self.activeTaskCount : activeTaskCount // ignore: cast_nullable_to_non_nullable
as int,loadedPluginCount: null == loadedPluginCount ? _self.loadedPluginCount : loadedPluginCount // ignore: cast_nullable_to_non_nullable
as int,activePluginCount: null == activePluginCount ? _self.activePluginCount : activePluginCount // ignore: cast_nullable_to_non_nullable
as int,capabilityCount: null == capabilityCount ? _self.capabilityCount : capabilityCount // ignore: cast_nullable_to_non_nullable
as int,bootTimeMs: null == bootTimeMs ? _self.bootTimeMs : bootTimeMs // ignore: cast_nullable_to_non_nullable
as int,uptimeMs: null == uptimeMs ? _self.uptimeMs : uptimeMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RuntimeStateSnapshot].
extension RuntimeStateSnapshotPatterns on RuntimeStateSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RuntimeStateSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RuntimeStateSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RuntimeStateSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _RuntimeStateSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RuntimeStateSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _RuntimeStateSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RuntimeStatus status,  int activeSessionCount,  int activeTaskCount,  int loadedPluginCount,  int activePluginCount,  int capabilityCount,  int bootTimeMs,  int uptimeMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RuntimeStateSnapshot() when $default != null:
return $default(_that.status,_that.activeSessionCount,_that.activeTaskCount,_that.loadedPluginCount,_that.activePluginCount,_that.capabilityCount,_that.bootTimeMs,_that.uptimeMs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RuntimeStatus status,  int activeSessionCount,  int activeTaskCount,  int loadedPluginCount,  int activePluginCount,  int capabilityCount,  int bootTimeMs,  int uptimeMs)  $default,) {final _that = this;
switch (_that) {
case _RuntimeStateSnapshot():
return $default(_that.status,_that.activeSessionCount,_that.activeTaskCount,_that.loadedPluginCount,_that.activePluginCount,_that.capabilityCount,_that.bootTimeMs,_that.uptimeMs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RuntimeStatus status,  int activeSessionCount,  int activeTaskCount,  int loadedPluginCount,  int activePluginCount,  int capabilityCount,  int bootTimeMs,  int uptimeMs)?  $default,) {final _that = this;
switch (_that) {
case _RuntimeStateSnapshot() when $default != null:
return $default(_that.status,_that.activeSessionCount,_that.activeTaskCount,_that.loadedPluginCount,_that.activePluginCount,_that.capabilityCount,_that.bootTimeMs,_that.uptimeMs);case _:
  return null;

}
}

}

/// @nodoc


class _RuntimeStateSnapshot implements RuntimeStateSnapshot {
  const _RuntimeStateSnapshot({required this.status, this.activeSessionCount = 0, this.activeTaskCount = 0, this.loadedPluginCount = 0, this.activePluginCount = 0, this.capabilityCount = 0, required this.bootTimeMs, required this.uptimeMs});
  

@override final  RuntimeStatus status;
@override@JsonKey() final  int activeSessionCount;
@override@JsonKey() final  int activeTaskCount;
@override@JsonKey() final  int loadedPluginCount;
@override@JsonKey() final  int activePluginCount;
@override@JsonKey() final  int capabilityCount;
@override final  int bootTimeMs;
@override final  int uptimeMs;

/// Create a copy of RuntimeStateSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RuntimeStateSnapshotCopyWith<_RuntimeStateSnapshot> get copyWith => __$RuntimeStateSnapshotCopyWithImpl<_RuntimeStateSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RuntimeStateSnapshot&&(identical(other.status, status) || other.status == status)&&(identical(other.activeSessionCount, activeSessionCount) || other.activeSessionCount == activeSessionCount)&&(identical(other.activeTaskCount, activeTaskCount) || other.activeTaskCount == activeTaskCount)&&(identical(other.loadedPluginCount, loadedPluginCount) || other.loadedPluginCount == loadedPluginCount)&&(identical(other.activePluginCount, activePluginCount) || other.activePluginCount == activePluginCount)&&(identical(other.capabilityCount, capabilityCount) || other.capabilityCount == capabilityCount)&&(identical(other.bootTimeMs, bootTimeMs) || other.bootTimeMs == bootTimeMs)&&(identical(other.uptimeMs, uptimeMs) || other.uptimeMs == uptimeMs));
}


@override
int get hashCode => Object.hash(runtimeType,status,activeSessionCount,activeTaskCount,loadedPluginCount,activePluginCount,capabilityCount,bootTimeMs,uptimeMs);

@override
String toString() {
  return 'RuntimeStateSnapshot(status: $status, activeSessionCount: $activeSessionCount, activeTaskCount: $activeTaskCount, loadedPluginCount: $loadedPluginCount, activePluginCount: $activePluginCount, capabilityCount: $capabilityCount, bootTimeMs: $bootTimeMs, uptimeMs: $uptimeMs)';
}


}

/// @nodoc
abstract mixin class _$RuntimeStateSnapshotCopyWith<$Res> implements $RuntimeStateSnapshotCopyWith<$Res> {
  factory _$RuntimeStateSnapshotCopyWith(_RuntimeStateSnapshot value, $Res Function(_RuntimeStateSnapshot) _then) = __$RuntimeStateSnapshotCopyWithImpl;
@override @useResult
$Res call({
 RuntimeStatus status, int activeSessionCount, int activeTaskCount, int loadedPluginCount, int activePluginCount, int capabilityCount, int bootTimeMs, int uptimeMs
});




}
/// @nodoc
class __$RuntimeStateSnapshotCopyWithImpl<$Res>
    implements _$RuntimeStateSnapshotCopyWith<$Res> {
  __$RuntimeStateSnapshotCopyWithImpl(this._self, this._then);

  final _RuntimeStateSnapshot _self;
  final $Res Function(_RuntimeStateSnapshot) _then;

/// Create a copy of RuntimeStateSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? activeSessionCount = null,Object? activeTaskCount = null,Object? loadedPluginCount = null,Object? activePluginCount = null,Object? capabilityCount = null,Object? bootTimeMs = null,Object? uptimeMs = null,}) {
  return _then(_RuntimeStateSnapshot(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RuntimeStatus,activeSessionCount: null == activeSessionCount ? _self.activeSessionCount : activeSessionCount // ignore: cast_nullable_to_non_nullable
as int,activeTaskCount: null == activeTaskCount ? _self.activeTaskCount : activeTaskCount // ignore: cast_nullable_to_non_nullable
as int,loadedPluginCount: null == loadedPluginCount ? _self.loadedPluginCount : loadedPluginCount // ignore: cast_nullable_to_non_nullable
as int,activePluginCount: null == activePluginCount ? _self.activePluginCount : activePluginCount // ignore: cast_nullable_to_non_nullable
as int,capabilityCount: null == capabilityCount ? _self.capabilityCount : capabilityCount // ignore: cast_nullable_to_non_nullable
as int,bootTimeMs: null == bootTimeMs ? _self.bootTimeMs : bootTimeMs // ignore: cast_nullable_to_non_nullable
as int,uptimeMs: null == uptimeMs ? _self.uptimeMs : uptimeMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
