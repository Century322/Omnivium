// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'state_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StateChange {

 String get id; String get objectId; String get objectType; StateChangeType get changeType; String? get actionId; Map<String, dynamic> get previousState; Map<String, dynamic> get newState; Map<String, dynamic>? get actionParams; bool get success; String? get error; String? get agentId; String? get workspaceId; DateTime get timestamp;
/// Create a copy of StateChange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StateChangeCopyWith<StateChange> get copyWith => _$StateChangeCopyWithImpl<StateChange>(this as StateChange, _$identity);

  /// Serializes this StateChange to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StateChange&&(identical(other.id, id) || other.id == id)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.objectType, objectType) || other.objectType == objectType)&&(identical(other.changeType, changeType) || other.changeType == changeType)&&(identical(other.actionId, actionId) || other.actionId == actionId)&&const DeepCollectionEquality().equals(other.previousState, previousState)&&const DeepCollectionEquality().equals(other.newState, newState)&&const DeepCollectionEquality().equals(other.actionParams, actionParams)&&(identical(other.success, success) || other.success == success)&&(identical(other.error, error) || other.error == error)&&(identical(other.agentId, agentId) || other.agentId == agentId)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,objectId,objectType,changeType,actionId,const DeepCollectionEquality().hash(previousState),const DeepCollectionEquality().hash(newState),const DeepCollectionEquality().hash(actionParams),success,error,agentId,workspaceId,timestamp);

@override
String toString() {
  return 'StateChange(id: $id, objectId: $objectId, objectType: $objectType, changeType: $changeType, actionId: $actionId, previousState: $previousState, newState: $newState, actionParams: $actionParams, success: $success, error: $error, agentId: $agentId, workspaceId: $workspaceId, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class $StateChangeCopyWith<$Res>  {
  factory $StateChangeCopyWith(StateChange value, $Res Function(StateChange) _then) = _$StateChangeCopyWithImpl;
@useResult
$Res call({
 String id, String objectId, String objectType, StateChangeType changeType, String? actionId, Map<String, dynamic> previousState, Map<String, dynamic> newState, Map<String, dynamic>? actionParams, bool success, String? error, String? agentId, String? workspaceId, DateTime timestamp
});




}
/// @nodoc
class _$StateChangeCopyWithImpl<$Res>
    implements $StateChangeCopyWith<$Res> {
  _$StateChangeCopyWithImpl(this._self, this._then);

  final StateChange _self;
  final $Res Function(StateChange) _then;

/// Create a copy of StateChange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? objectId = null,Object? objectType = null,Object? changeType = null,Object? actionId = freezed,Object? previousState = null,Object? newState = null,Object? actionParams = freezed,Object? success = null,Object? error = freezed,Object? agentId = freezed,Object? workspaceId = freezed,Object? timestamp = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,objectId: null == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String,objectType: null == objectType ? _self.objectType : objectType // ignore: cast_nullable_to_non_nullable
as String,changeType: null == changeType ? _self.changeType : changeType // ignore: cast_nullable_to_non_nullable
as StateChangeType,actionId: freezed == actionId ? _self.actionId : actionId // ignore: cast_nullable_to_non_nullable
as String?,previousState: null == previousState ? _self.previousState : previousState // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,newState: null == newState ? _self.newState : newState // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,actionParams: freezed == actionParams ? _self.actionParams : actionParams // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,agentId: freezed == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String?,workspaceId: freezed == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [StateChange].
extension StateChangePatterns on StateChange {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StateChange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StateChange() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StateChange value)  $default,){
final _that = this;
switch (_that) {
case _StateChange():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StateChange value)?  $default,){
final _that = this;
switch (_that) {
case _StateChange() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String objectId,  String objectType,  StateChangeType changeType,  String? actionId,  Map<String, dynamic> previousState,  Map<String, dynamic> newState,  Map<String, dynamic>? actionParams,  bool success,  String? error,  String? agentId,  String? workspaceId,  DateTime timestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StateChange() when $default != null:
return $default(_that.id,_that.objectId,_that.objectType,_that.changeType,_that.actionId,_that.previousState,_that.newState,_that.actionParams,_that.success,_that.error,_that.agentId,_that.workspaceId,_that.timestamp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String objectId,  String objectType,  StateChangeType changeType,  String? actionId,  Map<String, dynamic> previousState,  Map<String, dynamic> newState,  Map<String, dynamic>? actionParams,  bool success,  String? error,  String? agentId,  String? workspaceId,  DateTime timestamp)  $default,) {final _that = this;
switch (_that) {
case _StateChange():
return $default(_that.id,_that.objectId,_that.objectType,_that.changeType,_that.actionId,_that.previousState,_that.newState,_that.actionParams,_that.success,_that.error,_that.agentId,_that.workspaceId,_that.timestamp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String objectId,  String objectType,  StateChangeType changeType,  String? actionId,  Map<String, dynamic> previousState,  Map<String, dynamic> newState,  Map<String, dynamic>? actionParams,  bool success,  String? error,  String? agentId,  String? workspaceId,  DateTime timestamp)?  $default,) {final _that = this;
switch (_that) {
case _StateChange() when $default != null:
return $default(_that.id,_that.objectId,_that.objectType,_that.changeType,_that.actionId,_that.previousState,_that.newState,_that.actionParams,_that.success,_that.error,_that.agentId,_that.workspaceId,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StateChange extends StateChange {
  const _StateChange({required this.id, required this.objectId, required this.objectType, required this.changeType, this.actionId, final  Map<String, dynamic> previousState = const <String, dynamic>{}, final  Map<String, dynamic> newState = const <String, dynamic>{}, final  Map<String, dynamic>? actionParams, required this.success, this.error, this.agentId, this.workspaceId, required this.timestamp}): _previousState = previousState,_newState = newState,_actionParams = actionParams,super._();
  factory _StateChange.fromJson(Map<String, dynamic> json) => _$StateChangeFromJson(json);

@override final  String id;
@override final  String objectId;
@override final  String objectType;
@override final  StateChangeType changeType;
@override final  String? actionId;
 final  Map<String, dynamic> _previousState;
@override@JsonKey() Map<String, dynamic> get previousState {
  if (_previousState is EqualUnmodifiableMapView) return _previousState;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_previousState);
}

 final  Map<String, dynamic> _newState;
@override@JsonKey() Map<String, dynamic> get newState {
  if (_newState is EqualUnmodifiableMapView) return _newState;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_newState);
}

 final  Map<String, dynamic>? _actionParams;
@override Map<String, dynamic>? get actionParams {
  final value = _actionParams;
  if (value == null) return null;
  if (_actionParams is EqualUnmodifiableMapView) return _actionParams;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  bool success;
@override final  String? error;
@override final  String? agentId;
@override final  String? workspaceId;
@override final  DateTime timestamp;

/// Create a copy of StateChange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StateChangeCopyWith<_StateChange> get copyWith => __$StateChangeCopyWithImpl<_StateChange>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StateChangeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StateChange&&(identical(other.id, id) || other.id == id)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.objectType, objectType) || other.objectType == objectType)&&(identical(other.changeType, changeType) || other.changeType == changeType)&&(identical(other.actionId, actionId) || other.actionId == actionId)&&const DeepCollectionEquality().equals(other._previousState, _previousState)&&const DeepCollectionEquality().equals(other._newState, _newState)&&const DeepCollectionEquality().equals(other._actionParams, _actionParams)&&(identical(other.success, success) || other.success == success)&&(identical(other.error, error) || other.error == error)&&(identical(other.agentId, agentId) || other.agentId == agentId)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,objectId,objectType,changeType,actionId,const DeepCollectionEquality().hash(_previousState),const DeepCollectionEquality().hash(_newState),const DeepCollectionEquality().hash(_actionParams),success,error,agentId,workspaceId,timestamp);

@override
String toString() {
  return 'StateChange(id: $id, objectId: $objectId, objectType: $objectType, changeType: $changeType, actionId: $actionId, previousState: $previousState, newState: $newState, actionParams: $actionParams, success: $success, error: $error, agentId: $agentId, workspaceId: $workspaceId, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class _$StateChangeCopyWith<$Res> implements $StateChangeCopyWith<$Res> {
  factory _$StateChangeCopyWith(_StateChange value, $Res Function(_StateChange) _then) = __$StateChangeCopyWithImpl;
@override @useResult
$Res call({
 String id, String objectId, String objectType, StateChangeType changeType, String? actionId, Map<String, dynamic> previousState, Map<String, dynamic> newState, Map<String, dynamic>? actionParams, bool success, String? error, String? agentId, String? workspaceId, DateTime timestamp
});




}
/// @nodoc
class __$StateChangeCopyWithImpl<$Res>
    implements _$StateChangeCopyWith<$Res> {
  __$StateChangeCopyWithImpl(this._self, this._then);

  final _StateChange _self;
  final $Res Function(_StateChange) _then;

/// Create a copy of StateChange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? objectId = null,Object? objectType = null,Object? changeType = null,Object? actionId = freezed,Object? previousState = null,Object? newState = null,Object? actionParams = freezed,Object? success = null,Object? error = freezed,Object? agentId = freezed,Object? workspaceId = freezed,Object? timestamp = null,}) {
  return _then(_StateChange(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,objectId: null == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String,objectType: null == objectType ? _self.objectType : objectType // ignore: cast_nullable_to_non_nullable
as String,changeType: null == changeType ? _self.changeType : changeType // ignore: cast_nullable_to_non_nullable
as StateChangeType,actionId: freezed == actionId ? _self.actionId : actionId // ignore: cast_nullable_to_non_nullable
as String?,previousState: null == previousState ? _self._previousState : previousState // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,newState: null == newState ? _self._newState : newState // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,actionParams: freezed == actionParams ? _self._actionParams : actionParams // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,agentId: freezed == agentId ? _self.agentId : agentId // ignore: cast_nullable_to_non_nullable
as String?,workspaceId: freezed == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$ObjectState {

 String get objectId; String get objectType; Map<String, dynamic> get state; DateTime get lastModified; String? get lastActionId; int get changeCount; String? get workspaceId;
/// Create a copy of ObjectState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ObjectStateCopyWith<ObjectState> get copyWith => _$ObjectStateCopyWithImpl<ObjectState>(this as ObjectState, _$identity);

  /// Serializes this ObjectState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ObjectState&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.objectType, objectType) || other.objectType == objectType)&&const DeepCollectionEquality().equals(other.state, state)&&(identical(other.lastModified, lastModified) || other.lastModified == lastModified)&&(identical(other.lastActionId, lastActionId) || other.lastActionId == lastActionId)&&(identical(other.changeCount, changeCount) || other.changeCount == changeCount)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,objectId,objectType,const DeepCollectionEquality().hash(state),lastModified,lastActionId,changeCount,workspaceId);

@override
String toString() {
  return 'ObjectState(objectId: $objectId, objectType: $objectType, state: $state, lastModified: $lastModified, lastActionId: $lastActionId, changeCount: $changeCount, workspaceId: $workspaceId)';
}


}

/// @nodoc
abstract mixin class $ObjectStateCopyWith<$Res>  {
  factory $ObjectStateCopyWith(ObjectState value, $Res Function(ObjectState) _then) = _$ObjectStateCopyWithImpl;
@useResult
$Res call({
 String objectId, String objectType, Map<String, dynamic> state, DateTime lastModified, String? lastActionId, int changeCount, String? workspaceId
});




}
/// @nodoc
class _$ObjectStateCopyWithImpl<$Res>
    implements $ObjectStateCopyWith<$Res> {
  _$ObjectStateCopyWithImpl(this._self, this._then);

  final ObjectState _self;
  final $Res Function(ObjectState) _then;

/// Create a copy of ObjectState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? objectId = null,Object? objectType = null,Object? state = null,Object? lastModified = null,Object? lastActionId = freezed,Object? changeCount = null,Object? workspaceId = freezed,}) {
  return _then(_self.copyWith(
objectId: null == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String,objectType: null == objectType ? _self.objectType : objectType // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,lastModified: null == lastModified ? _self.lastModified : lastModified // ignore: cast_nullable_to_non_nullable
as DateTime,lastActionId: freezed == lastActionId ? _self.lastActionId : lastActionId // ignore: cast_nullable_to_non_nullable
as String?,changeCount: null == changeCount ? _self.changeCount : changeCount // ignore: cast_nullable_to_non_nullable
as int,workspaceId: freezed == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ObjectState].
extension ObjectStatePatterns on ObjectState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ObjectState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ObjectState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ObjectState value)  $default,){
final _that = this;
switch (_that) {
case _ObjectState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ObjectState value)?  $default,){
final _that = this;
switch (_that) {
case _ObjectState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String objectId,  String objectType,  Map<String, dynamic> state,  DateTime lastModified,  String? lastActionId,  int changeCount,  String? workspaceId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ObjectState() when $default != null:
return $default(_that.objectId,_that.objectType,_that.state,_that.lastModified,_that.lastActionId,_that.changeCount,_that.workspaceId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String objectId,  String objectType,  Map<String, dynamic> state,  DateTime lastModified,  String? lastActionId,  int changeCount,  String? workspaceId)  $default,) {final _that = this;
switch (_that) {
case _ObjectState():
return $default(_that.objectId,_that.objectType,_that.state,_that.lastModified,_that.lastActionId,_that.changeCount,_that.workspaceId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String objectId,  String objectType,  Map<String, dynamic> state,  DateTime lastModified,  String? lastActionId,  int changeCount,  String? workspaceId)?  $default,) {final _that = this;
switch (_that) {
case _ObjectState() when $default != null:
return $default(_that.objectId,_that.objectType,_that.state,_that.lastModified,_that.lastActionId,_that.changeCount,_that.workspaceId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ObjectState extends ObjectState {
  const _ObjectState({required this.objectId, required this.objectType, final  Map<String, dynamic> state = const <String, dynamic>{}, required this.lastModified, this.lastActionId, this.changeCount = 1, this.workspaceId}): _state = state,super._();
  factory _ObjectState.fromJson(Map<String, dynamic> json) => _$ObjectStateFromJson(json);

@override final  String objectId;
@override final  String objectType;
 final  Map<String, dynamic> _state;
@override@JsonKey() Map<String, dynamic> get state {
  if (_state is EqualUnmodifiableMapView) return _state;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_state);
}

@override final  DateTime lastModified;
@override final  String? lastActionId;
@override@JsonKey() final  int changeCount;
@override final  String? workspaceId;

/// Create a copy of ObjectState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ObjectStateCopyWith<_ObjectState> get copyWith => __$ObjectStateCopyWithImpl<_ObjectState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ObjectStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ObjectState&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.objectType, objectType) || other.objectType == objectType)&&const DeepCollectionEquality().equals(other._state, _state)&&(identical(other.lastModified, lastModified) || other.lastModified == lastModified)&&(identical(other.lastActionId, lastActionId) || other.lastActionId == lastActionId)&&(identical(other.changeCount, changeCount) || other.changeCount == changeCount)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,objectId,objectType,const DeepCollectionEquality().hash(_state),lastModified,lastActionId,changeCount,workspaceId);

@override
String toString() {
  return 'ObjectState(objectId: $objectId, objectType: $objectType, state: $state, lastModified: $lastModified, lastActionId: $lastActionId, changeCount: $changeCount, workspaceId: $workspaceId)';
}


}

/// @nodoc
abstract mixin class _$ObjectStateCopyWith<$Res> implements $ObjectStateCopyWith<$Res> {
  factory _$ObjectStateCopyWith(_ObjectState value, $Res Function(_ObjectState) _then) = __$ObjectStateCopyWithImpl;
@override @useResult
$Res call({
 String objectId, String objectType, Map<String, dynamic> state, DateTime lastModified, String? lastActionId, int changeCount, String? workspaceId
});




}
/// @nodoc
class __$ObjectStateCopyWithImpl<$Res>
    implements _$ObjectStateCopyWith<$Res> {
  __$ObjectStateCopyWithImpl(this._self, this._then);

  final _ObjectState _self;
  final $Res Function(_ObjectState) _then;

/// Create a copy of ObjectState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? objectId = null,Object? objectType = null,Object? state = null,Object? lastModified = null,Object? lastActionId = freezed,Object? changeCount = null,Object? workspaceId = freezed,}) {
  return _then(_ObjectState(
objectId: null == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String,objectType: null == objectType ? _self.objectType : objectType // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self._state : state // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,lastModified: null == lastModified ? _self.lastModified : lastModified // ignore: cast_nullable_to_non_nullable
as DateTime,lastActionId: freezed == lastActionId ? _self.lastActionId : lastActionId // ignore: cast_nullable_to_non_nullable
as String?,changeCount: null == changeCount ? _self.changeCount : changeCount // ignore: cast_nullable_to_non_nullable
as int,workspaceId: freezed == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
