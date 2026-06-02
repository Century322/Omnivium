// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'episodic_memory.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EpisodicMemory {

 String get id; String get scene; List<String> get participants; String? get emotion; DateTime get timestamp; String? get workspaceId; List<String> get relatedEventIds; String? get location; Map<String, dynamic> get metadata;
/// Create a copy of EpisodicMemory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EpisodicMemoryCopyWith<EpisodicMemory> get copyWith => _$EpisodicMemoryCopyWithImpl<EpisodicMemory>(this as EpisodicMemory, _$identity);

  /// Serializes this EpisodicMemory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EpisodicMemory&&(identical(other.id, id) || other.id == id)&&(identical(other.scene, scene) || other.scene == scene)&&const DeepCollectionEquality().equals(other.participants, participants)&&(identical(other.emotion, emotion) || other.emotion == emotion)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&const DeepCollectionEquality().equals(other.relatedEventIds, relatedEventIds)&&(identical(other.location, location) || other.location == location)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,scene,const DeepCollectionEquality().hash(participants),emotion,timestamp,workspaceId,const DeepCollectionEquality().hash(relatedEventIds),location,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'EpisodicMemory(id: $id, scene: $scene, participants: $participants, emotion: $emotion, timestamp: $timestamp, workspaceId: $workspaceId, relatedEventIds: $relatedEventIds, location: $location, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $EpisodicMemoryCopyWith<$Res>  {
  factory $EpisodicMemoryCopyWith(EpisodicMemory value, $Res Function(EpisodicMemory) _then) = _$EpisodicMemoryCopyWithImpl;
@useResult
$Res call({
 String id, String scene, List<String> participants, String? emotion, DateTime timestamp, String? workspaceId, List<String> relatedEventIds, String? location, Map<String, dynamic> metadata
});




}
/// @nodoc
class _$EpisodicMemoryCopyWithImpl<$Res>
    implements $EpisodicMemoryCopyWith<$Res> {
  _$EpisodicMemoryCopyWithImpl(this._self, this._then);

  final EpisodicMemory _self;
  final $Res Function(EpisodicMemory) _then;

/// Create a copy of EpisodicMemory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? scene = null,Object? participants = null,Object? emotion = freezed,Object? timestamp = null,Object? workspaceId = freezed,Object? relatedEventIds = null,Object? location = freezed,Object? metadata = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,scene: null == scene ? _self.scene : scene // ignore: cast_nullable_to_non_nullable
as String,participants: null == participants ? _self.participants : participants // ignore: cast_nullable_to_non_nullable
as List<String>,emotion: freezed == emotion ? _self.emotion : emotion // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,workspaceId: freezed == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String?,relatedEventIds: null == relatedEventIds ? _self.relatedEventIds : relatedEventIds // ignore: cast_nullable_to_non_nullable
as List<String>,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [EpisodicMemory].
extension EpisodicMemoryPatterns on EpisodicMemory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EpisodicMemory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EpisodicMemory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EpisodicMemory value)  $default,){
final _that = this;
switch (_that) {
case _EpisodicMemory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EpisodicMemory value)?  $default,){
final _that = this;
switch (_that) {
case _EpisodicMemory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String scene,  List<String> participants,  String? emotion,  DateTime timestamp,  String? workspaceId,  List<String> relatedEventIds,  String? location,  Map<String, dynamic> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EpisodicMemory() when $default != null:
return $default(_that.id,_that.scene,_that.participants,_that.emotion,_that.timestamp,_that.workspaceId,_that.relatedEventIds,_that.location,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String scene,  List<String> participants,  String? emotion,  DateTime timestamp,  String? workspaceId,  List<String> relatedEventIds,  String? location,  Map<String, dynamic> metadata)  $default,) {final _that = this;
switch (_that) {
case _EpisodicMemory():
return $default(_that.id,_that.scene,_that.participants,_that.emotion,_that.timestamp,_that.workspaceId,_that.relatedEventIds,_that.location,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String scene,  List<String> participants,  String? emotion,  DateTime timestamp,  String? workspaceId,  List<String> relatedEventIds,  String? location,  Map<String, dynamic> metadata)?  $default,) {final _that = this;
switch (_that) {
case _EpisodicMemory() when $default != null:
return $default(_that.id,_that.scene,_that.participants,_that.emotion,_that.timestamp,_that.workspaceId,_that.relatedEventIds,_that.location,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EpisodicMemory extends EpisodicMemory {
  const _EpisodicMemory({required this.id, required this.scene, final  List<String> participants = const <String>[], this.emotion, required this.timestamp, this.workspaceId, final  List<String> relatedEventIds = const <String>[], this.location, final  Map<String, dynamic> metadata = const <String, dynamic>{}}): _participants = participants,_relatedEventIds = relatedEventIds,_metadata = metadata,super._();
  factory _EpisodicMemory.fromJson(Map<String, dynamic> json) => _$EpisodicMemoryFromJson(json);

@override final  String id;
@override final  String scene;
 final  List<String> _participants;
@override@JsonKey() List<String> get participants {
  if (_participants is EqualUnmodifiableListView) return _participants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participants);
}

@override final  String? emotion;
@override final  DateTime timestamp;
@override final  String? workspaceId;
 final  List<String> _relatedEventIds;
@override@JsonKey() List<String> get relatedEventIds {
  if (_relatedEventIds is EqualUnmodifiableListView) return _relatedEventIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_relatedEventIds);
}

@override final  String? location;
 final  Map<String, dynamic> _metadata;
@override@JsonKey() Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}


/// Create a copy of EpisodicMemory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EpisodicMemoryCopyWith<_EpisodicMemory> get copyWith => __$EpisodicMemoryCopyWithImpl<_EpisodicMemory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EpisodicMemoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EpisodicMemory&&(identical(other.id, id) || other.id == id)&&(identical(other.scene, scene) || other.scene == scene)&&const DeepCollectionEquality().equals(other._participants, _participants)&&(identical(other.emotion, emotion) || other.emotion == emotion)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&const DeepCollectionEquality().equals(other._relatedEventIds, _relatedEventIds)&&(identical(other.location, location) || other.location == location)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,scene,const DeepCollectionEquality().hash(_participants),emotion,timestamp,workspaceId,const DeepCollectionEquality().hash(_relatedEventIds),location,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'EpisodicMemory(id: $id, scene: $scene, participants: $participants, emotion: $emotion, timestamp: $timestamp, workspaceId: $workspaceId, relatedEventIds: $relatedEventIds, location: $location, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$EpisodicMemoryCopyWith<$Res> implements $EpisodicMemoryCopyWith<$Res> {
  factory _$EpisodicMemoryCopyWith(_EpisodicMemory value, $Res Function(_EpisodicMemory) _then) = __$EpisodicMemoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String scene, List<String> participants, String? emotion, DateTime timestamp, String? workspaceId, List<String> relatedEventIds, String? location, Map<String, dynamic> metadata
});




}
/// @nodoc
class __$EpisodicMemoryCopyWithImpl<$Res>
    implements _$EpisodicMemoryCopyWith<$Res> {
  __$EpisodicMemoryCopyWithImpl(this._self, this._then);

  final _EpisodicMemory _self;
  final $Res Function(_EpisodicMemory) _then;

/// Create a copy of EpisodicMemory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? scene = null,Object? participants = null,Object? emotion = freezed,Object? timestamp = null,Object? workspaceId = freezed,Object? relatedEventIds = null,Object? location = freezed,Object? metadata = null,}) {
  return _then(_EpisodicMemory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,scene: null == scene ? _self.scene : scene // ignore: cast_nullable_to_non_nullable
as String,participants: null == participants ? _self._participants : participants // ignore: cast_nullable_to_non_nullable
as List<String>,emotion: freezed == emotion ? _self.emotion : emotion // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,workspaceId: freezed == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String?,relatedEventIds: null == relatedEventIds ? _self._relatedEventIds : relatedEventIds // ignore: cast_nullable_to_non_nullable
as List<String>,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
