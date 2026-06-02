// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'memory_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MemoryEvent {

 String get id; DateTime get timestamp; String get eventType; String get summary; String? get entityId; int get importance; MemoryPersistence get persistence; double get confidence; MemoryType get memoryType; IntentType get intent; MemoryDomain get domain; String? get workspaceId; String? get speakerId; String get source; String? get snapshotId; MemoryLifecycle get lifecycle; String? get reason; Map<String, dynamic> get properties;
/// Create a copy of MemoryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemoryEventCopyWith<MemoryEvent> get copyWith => _$MemoryEventCopyWithImpl<MemoryEvent>(this as MemoryEvent, _$identity);

  /// Serializes this MemoryEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemoryEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.importance, importance) || other.importance == importance)&&(identical(other.persistence, persistence) || other.persistence == persistence)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.memoryType, memoryType) || other.memoryType == memoryType)&&(identical(other.intent, intent) || other.intent == intent)&&(identical(other.domain, domain) || other.domain == domain)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.speakerId, speakerId) || other.speakerId == speakerId)&&(identical(other.source, source) || other.source == source)&&(identical(other.snapshotId, snapshotId) || other.snapshotId == snapshotId)&&(identical(other.lifecycle, lifecycle) || other.lifecycle == lifecycle)&&(identical(other.reason, reason) || other.reason == reason)&&const DeepCollectionEquality().equals(other.properties, properties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,timestamp,eventType,summary,entityId,importance,persistence,confidence,memoryType,intent,domain,workspaceId,speakerId,source,snapshotId,lifecycle,reason,const DeepCollectionEquality().hash(properties));

@override
String toString() {
  return 'MemoryEvent(id: $id, timestamp: $timestamp, eventType: $eventType, summary: $summary, entityId: $entityId, importance: $importance, persistence: $persistence, confidence: $confidence, memoryType: $memoryType, intent: $intent, domain: $domain, workspaceId: $workspaceId, speakerId: $speakerId, source: $source, snapshotId: $snapshotId, lifecycle: $lifecycle, reason: $reason, properties: $properties)';
}


}

/// @nodoc
abstract mixin class $MemoryEventCopyWith<$Res>  {
  factory $MemoryEventCopyWith(MemoryEvent value, $Res Function(MemoryEvent) _then) = _$MemoryEventCopyWithImpl;
@useResult
$Res call({
 String id, DateTime timestamp, String eventType, String summary, String? entityId, int importance, MemoryPersistence persistence, double confidence, MemoryType memoryType, IntentType intent, MemoryDomain domain, String? workspaceId, String? speakerId, String source, String? snapshotId, MemoryLifecycle lifecycle, String? reason, Map<String, dynamic> properties
});




}
/// @nodoc
class _$MemoryEventCopyWithImpl<$Res>
    implements $MemoryEventCopyWith<$Res> {
  _$MemoryEventCopyWithImpl(this._self, this._then);

  final MemoryEvent _self;
  final $Res Function(MemoryEvent) _then;

/// Create a copy of MemoryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? timestamp = null,Object? eventType = null,Object? summary = null,Object? entityId = freezed,Object? importance = null,Object? persistence = null,Object? confidence = null,Object? memoryType = null,Object? intent = null,Object? domain = null,Object? workspaceId = freezed,Object? speakerId = freezed,Object? source = null,Object? snapshotId = freezed,Object? lifecycle = null,Object? reason = freezed,Object? properties = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,entityId: freezed == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String?,importance: null == importance ? _self.importance : importance // ignore: cast_nullable_to_non_nullable
as int,persistence: null == persistence ? _self.persistence : persistence // ignore: cast_nullable_to_non_nullable
as MemoryPersistence,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,memoryType: null == memoryType ? _self.memoryType : memoryType // ignore: cast_nullable_to_non_nullable
as MemoryType,intent: null == intent ? _self.intent : intent // ignore: cast_nullable_to_non_nullable
as IntentType,domain: null == domain ? _self.domain : domain // ignore: cast_nullable_to_non_nullable
as MemoryDomain,workspaceId: freezed == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String?,speakerId: freezed == speakerId ? _self.speakerId : speakerId // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,snapshotId: freezed == snapshotId ? _self.snapshotId : snapshotId // ignore: cast_nullable_to_non_nullable
as String?,lifecycle: null == lifecycle ? _self.lifecycle : lifecycle // ignore: cast_nullable_to_non_nullable
as MemoryLifecycle,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,properties: null == properties ? _self.properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [MemoryEvent].
extension MemoryEventPatterns on MemoryEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemoryEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemoryEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemoryEvent value)  $default,){
final _that = this;
switch (_that) {
case _MemoryEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemoryEvent value)?  $default,){
final _that = this;
switch (_that) {
case _MemoryEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime timestamp,  String eventType,  String summary,  String? entityId,  int importance,  MemoryPersistence persistence,  double confidence,  MemoryType memoryType,  IntentType intent,  MemoryDomain domain,  String? workspaceId,  String? speakerId,  String source,  String? snapshotId,  MemoryLifecycle lifecycle,  String? reason,  Map<String, dynamic> properties)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemoryEvent() when $default != null:
return $default(_that.id,_that.timestamp,_that.eventType,_that.summary,_that.entityId,_that.importance,_that.persistence,_that.confidence,_that.memoryType,_that.intent,_that.domain,_that.workspaceId,_that.speakerId,_that.source,_that.snapshotId,_that.lifecycle,_that.reason,_that.properties);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime timestamp,  String eventType,  String summary,  String? entityId,  int importance,  MemoryPersistence persistence,  double confidence,  MemoryType memoryType,  IntentType intent,  MemoryDomain domain,  String? workspaceId,  String? speakerId,  String source,  String? snapshotId,  MemoryLifecycle lifecycle,  String? reason,  Map<String, dynamic> properties)  $default,) {final _that = this;
switch (_that) {
case _MemoryEvent():
return $default(_that.id,_that.timestamp,_that.eventType,_that.summary,_that.entityId,_that.importance,_that.persistence,_that.confidence,_that.memoryType,_that.intent,_that.domain,_that.workspaceId,_that.speakerId,_that.source,_that.snapshotId,_that.lifecycle,_that.reason,_that.properties);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime timestamp,  String eventType,  String summary,  String? entityId,  int importance,  MemoryPersistence persistence,  double confidence,  MemoryType memoryType,  IntentType intent,  MemoryDomain domain,  String? workspaceId,  String? speakerId,  String source,  String? snapshotId,  MemoryLifecycle lifecycle,  String? reason,  Map<String, dynamic> properties)?  $default,) {final _that = this;
switch (_that) {
case _MemoryEvent() when $default != null:
return $default(_that.id,_that.timestamp,_that.eventType,_that.summary,_that.entityId,_that.importance,_that.persistence,_that.confidence,_that.memoryType,_that.intent,_that.domain,_that.workspaceId,_that.speakerId,_that.source,_that.snapshotId,_that.lifecycle,_that.reason,_that.properties);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemoryEvent extends MemoryEvent {
  const _MemoryEvent({required this.id, required this.timestamp, required this.eventType, required this.summary, this.entityId, this.importance = 50, this.persistence = MemoryPersistence.shortTerm, this.confidence = 80, this.memoryType = MemoryType.fact, this.intent = IntentType.fact, this.domain = MemoryDomain.project, this.workspaceId, this.speakerId, this.source = 'conversation', this.snapshotId, this.lifecycle = MemoryLifecycle.active, this.reason, final  Map<String, dynamic> properties = const <String, dynamic>{}}): _properties = properties,super._();
  factory _MemoryEvent.fromJson(Map<String, dynamic> json) => _$MemoryEventFromJson(json);

@override final  String id;
@override final  DateTime timestamp;
@override final  String eventType;
@override final  String summary;
@override final  String? entityId;
@override@JsonKey() final  int importance;
@override@JsonKey() final  MemoryPersistence persistence;
@override@JsonKey() final  double confidence;
@override@JsonKey() final  MemoryType memoryType;
@override@JsonKey() final  IntentType intent;
@override@JsonKey() final  MemoryDomain domain;
@override final  String? workspaceId;
@override final  String? speakerId;
@override@JsonKey() final  String source;
@override final  String? snapshotId;
@override@JsonKey() final  MemoryLifecycle lifecycle;
@override final  String? reason;
 final  Map<String, dynamic> _properties;
@override@JsonKey() Map<String, dynamic> get properties {
  if (_properties is EqualUnmodifiableMapView) return _properties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_properties);
}


/// Create a copy of MemoryEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemoryEventCopyWith<_MemoryEvent> get copyWith => __$MemoryEventCopyWithImpl<_MemoryEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemoryEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemoryEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.importance, importance) || other.importance == importance)&&(identical(other.persistence, persistence) || other.persistence == persistence)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.memoryType, memoryType) || other.memoryType == memoryType)&&(identical(other.intent, intent) || other.intent == intent)&&(identical(other.domain, domain) || other.domain == domain)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.speakerId, speakerId) || other.speakerId == speakerId)&&(identical(other.source, source) || other.source == source)&&(identical(other.snapshotId, snapshotId) || other.snapshotId == snapshotId)&&(identical(other.lifecycle, lifecycle) || other.lifecycle == lifecycle)&&(identical(other.reason, reason) || other.reason == reason)&&const DeepCollectionEquality().equals(other._properties, _properties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,timestamp,eventType,summary,entityId,importance,persistence,confidence,memoryType,intent,domain,workspaceId,speakerId,source,snapshotId,lifecycle,reason,const DeepCollectionEquality().hash(_properties));

@override
String toString() {
  return 'MemoryEvent(id: $id, timestamp: $timestamp, eventType: $eventType, summary: $summary, entityId: $entityId, importance: $importance, persistence: $persistence, confidence: $confidence, memoryType: $memoryType, intent: $intent, domain: $domain, workspaceId: $workspaceId, speakerId: $speakerId, source: $source, snapshotId: $snapshotId, lifecycle: $lifecycle, reason: $reason, properties: $properties)';
}


}

/// @nodoc
abstract mixin class _$MemoryEventCopyWith<$Res> implements $MemoryEventCopyWith<$Res> {
  factory _$MemoryEventCopyWith(_MemoryEvent value, $Res Function(_MemoryEvent) _then) = __$MemoryEventCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime timestamp, String eventType, String summary, String? entityId, int importance, MemoryPersistence persistence, double confidence, MemoryType memoryType, IntentType intent, MemoryDomain domain, String? workspaceId, String? speakerId, String source, String? snapshotId, MemoryLifecycle lifecycle, String? reason, Map<String, dynamic> properties
});




}
/// @nodoc
class __$MemoryEventCopyWithImpl<$Res>
    implements _$MemoryEventCopyWith<$Res> {
  __$MemoryEventCopyWithImpl(this._self, this._then);

  final _MemoryEvent _self;
  final $Res Function(_MemoryEvent) _then;

/// Create a copy of MemoryEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? timestamp = null,Object? eventType = null,Object? summary = null,Object? entityId = freezed,Object? importance = null,Object? persistence = null,Object? confidence = null,Object? memoryType = null,Object? intent = null,Object? domain = null,Object? workspaceId = freezed,Object? speakerId = freezed,Object? source = null,Object? snapshotId = freezed,Object? lifecycle = null,Object? reason = freezed,Object? properties = null,}) {
  return _then(_MemoryEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,entityId: freezed == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String?,importance: null == importance ? _self.importance : importance // ignore: cast_nullable_to_non_nullable
as int,persistence: null == persistence ? _self.persistence : persistence // ignore: cast_nullable_to_non_nullable
as MemoryPersistence,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,memoryType: null == memoryType ? _self.memoryType : memoryType // ignore: cast_nullable_to_non_nullable
as MemoryType,intent: null == intent ? _self.intent : intent // ignore: cast_nullable_to_non_nullable
as IntentType,domain: null == domain ? _self.domain : domain // ignore: cast_nullable_to_non_nullable
as MemoryDomain,workspaceId: freezed == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String?,speakerId: freezed == speakerId ? _self.speakerId : speakerId // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,snapshotId: freezed == snapshotId ? _self.snapshotId : snapshotId // ignore: cast_nullable_to_non_nullable
as String?,lifecycle: null == lifecycle ? _self.lifecycle : lifecycle // ignore: cast_nullable_to_non_nullable
as MemoryLifecycle,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,properties: null == properties ? _self._properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$MemorySnapshot {

 String get id; String get eventId; String get rawMessage; List<String> get contextBefore; List<String> get contextAfter; DateTime get createdAt;
/// Create a copy of MemorySnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemorySnapshotCopyWith<MemorySnapshot> get copyWith => _$MemorySnapshotCopyWithImpl<MemorySnapshot>(this as MemorySnapshot, _$identity);

  /// Serializes this MemorySnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemorySnapshot&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.rawMessage, rawMessage) || other.rawMessage == rawMessage)&&const DeepCollectionEquality().equals(other.contextBefore, contextBefore)&&const DeepCollectionEquality().equals(other.contextAfter, contextAfter)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,rawMessage,const DeepCollectionEquality().hash(contextBefore),const DeepCollectionEquality().hash(contextAfter),createdAt);

@override
String toString() {
  return 'MemorySnapshot(id: $id, eventId: $eventId, rawMessage: $rawMessage, contextBefore: $contextBefore, contextAfter: $contextAfter, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MemorySnapshotCopyWith<$Res>  {
  factory $MemorySnapshotCopyWith(MemorySnapshot value, $Res Function(MemorySnapshot) _then) = _$MemorySnapshotCopyWithImpl;
@useResult
$Res call({
 String id, String eventId, String rawMessage, List<String> contextBefore, List<String> contextAfter, DateTime createdAt
});




}
/// @nodoc
class _$MemorySnapshotCopyWithImpl<$Res>
    implements $MemorySnapshotCopyWith<$Res> {
  _$MemorySnapshotCopyWithImpl(this._self, this._then);

  final MemorySnapshot _self;
  final $Res Function(MemorySnapshot) _then;

/// Create a copy of MemorySnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? eventId = null,Object? rawMessage = null,Object? contextBefore = null,Object? contextAfter = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,rawMessage: null == rawMessage ? _self.rawMessage : rawMessage // ignore: cast_nullable_to_non_nullable
as String,contextBefore: null == contextBefore ? _self.contextBefore : contextBefore // ignore: cast_nullable_to_non_nullable
as List<String>,contextAfter: null == contextAfter ? _self.contextAfter : contextAfter // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MemorySnapshot].
extension MemorySnapshotPatterns on MemorySnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemorySnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemorySnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemorySnapshot value)  $default,){
final _that = this;
switch (_that) {
case _MemorySnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemorySnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _MemorySnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String eventId,  String rawMessage,  List<String> contextBefore,  List<String> contextAfter,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemorySnapshot() when $default != null:
return $default(_that.id,_that.eventId,_that.rawMessage,_that.contextBefore,_that.contextAfter,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String eventId,  String rawMessage,  List<String> contextBefore,  List<String> contextAfter,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _MemorySnapshot():
return $default(_that.id,_that.eventId,_that.rawMessage,_that.contextBefore,_that.contextAfter,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String eventId,  String rawMessage,  List<String> contextBefore,  List<String> contextAfter,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MemorySnapshot() when $default != null:
return $default(_that.id,_that.eventId,_that.rawMessage,_that.contextBefore,_that.contextAfter,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemorySnapshot extends MemorySnapshot {
  const _MemorySnapshot({required this.id, required this.eventId, required this.rawMessage, final  List<String> contextBefore = const <String>[], final  List<String> contextAfter = const <String>[], required this.createdAt}): _contextBefore = contextBefore,_contextAfter = contextAfter,super._();
  factory _MemorySnapshot.fromJson(Map<String, dynamic> json) => _$MemorySnapshotFromJson(json);

@override final  String id;
@override final  String eventId;
@override final  String rawMessage;
 final  List<String> _contextBefore;
@override@JsonKey() List<String> get contextBefore {
  if (_contextBefore is EqualUnmodifiableListView) return _contextBefore;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_contextBefore);
}

 final  List<String> _contextAfter;
@override@JsonKey() List<String> get contextAfter {
  if (_contextAfter is EqualUnmodifiableListView) return _contextAfter;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_contextAfter);
}

@override final  DateTime createdAt;

/// Create a copy of MemorySnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemorySnapshotCopyWith<_MemorySnapshot> get copyWith => __$MemorySnapshotCopyWithImpl<_MemorySnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemorySnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemorySnapshot&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.rawMessage, rawMessage) || other.rawMessage == rawMessage)&&const DeepCollectionEquality().equals(other._contextBefore, _contextBefore)&&const DeepCollectionEquality().equals(other._contextAfter, _contextAfter)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,rawMessage,const DeepCollectionEquality().hash(_contextBefore),const DeepCollectionEquality().hash(_contextAfter),createdAt);

@override
String toString() {
  return 'MemorySnapshot(id: $id, eventId: $eventId, rawMessage: $rawMessage, contextBefore: $contextBefore, contextAfter: $contextAfter, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MemorySnapshotCopyWith<$Res> implements $MemorySnapshotCopyWith<$Res> {
  factory _$MemorySnapshotCopyWith(_MemorySnapshot value, $Res Function(_MemorySnapshot) _then) = __$MemorySnapshotCopyWithImpl;
@override @useResult
$Res call({
 String id, String eventId, String rawMessage, List<String> contextBefore, List<String> contextAfter, DateTime createdAt
});




}
/// @nodoc
class __$MemorySnapshotCopyWithImpl<$Res>
    implements _$MemorySnapshotCopyWith<$Res> {
  __$MemorySnapshotCopyWithImpl(this._self, this._then);

  final _MemorySnapshot _self;
  final $Res Function(_MemorySnapshot) _then;

/// Create a copy of MemorySnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventId = null,Object? rawMessage = null,Object? contextBefore = null,Object? contextAfter = null,Object? createdAt = null,}) {
  return _then(_MemorySnapshot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,rawMessage: null == rawMessage ? _self.rawMessage : rawMessage // ignore: cast_nullable_to_non_nullable
as String,contextBefore: null == contextBefore ? _self._contextBefore : contextBefore // ignore: cast_nullable_to_non_nullable
as List<String>,contextAfter: null == contextAfter ? _self._contextAfter : contextAfter // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
