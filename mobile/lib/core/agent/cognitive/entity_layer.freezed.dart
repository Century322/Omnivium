// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'entity_layer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EntityState {

 String get id; String get entityId; String get state; DateTime get since; String? get sourceEventId; Map<String, dynamic> get context;
/// Create a copy of EntityState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntityStateCopyWith<EntityState> get copyWith => _$EntityStateCopyWithImpl<EntityState>(this as EntityState, _$identity);

  /// Serializes this EntityState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EntityState&&(identical(other.id, id) || other.id == id)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.state, state) || other.state == state)&&(identical(other.since, since) || other.since == since)&&(identical(other.sourceEventId, sourceEventId) || other.sourceEventId == sourceEventId)&&const DeepCollectionEquality().equals(other.context, context));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,entityId,state,since,sourceEventId,const DeepCollectionEquality().hash(context));

@override
String toString() {
  return 'EntityState(id: $id, entityId: $entityId, state: $state, since: $since, sourceEventId: $sourceEventId, context: $context)';
}


}

/// @nodoc
abstract mixin class $EntityStateCopyWith<$Res>  {
  factory $EntityStateCopyWith(EntityState value, $Res Function(EntityState) _then) = _$EntityStateCopyWithImpl;
@useResult
$Res call({
 String id, String entityId, String state, DateTime since, String? sourceEventId, Map<String, dynamic> context
});




}
/// @nodoc
class _$EntityStateCopyWithImpl<$Res>
    implements $EntityStateCopyWith<$Res> {
  _$EntityStateCopyWithImpl(this._self, this._then);

  final EntityState _self;
  final $Res Function(EntityState) _then;

/// Create a copy of EntityState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? entityId = null,Object? state = null,Object? since = null,Object? sourceEventId = freezed,Object? context = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,since: null == since ? _self.since : since // ignore: cast_nullable_to_non_nullable
as DateTime,sourceEventId: freezed == sourceEventId ? _self.sourceEventId : sourceEventId // ignore: cast_nullable_to_non_nullable
as String?,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [EntityState].
extension EntityStatePatterns on EntityState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EntityState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EntityState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EntityState value)  $default,){
final _that = this;
switch (_that) {
case _EntityState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EntityState value)?  $default,){
final _that = this;
switch (_that) {
case _EntityState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String entityId,  String state,  DateTime since,  String? sourceEventId,  Map<String, dynamic> context)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EntityState() when $default != null:
return $default(_that.id,_that.entityId,_that.state,_that.since,_that.sourceEventId,_that.context);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String entityId,  String state,  DateTime since,  String? sourceEventId,  Map<String, dynamic> context)  $default,) {final _that = this;
switch (_that) {
case _EntityState():
return $default(_that.id,_that.entityId,_that.state,_that.since,_that.sourceEventId,_that.context);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String entityId,  String state,  DateTime since,  String? sourceEventId,  Map<String, dynamic> context)?  $default,) {final _that = this;
switch (_that) {
case _EntityState() when $default != null:
return $default(_that.id,_that.entityId,_that.state,_that.since,_that.sourceEventId,_that.context);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EntityState extends EntityState {
  const _EntityState({required this.id, required this.entityId, required this.state, required this.since, this.sourceEventId, final  Map<String, dynamic> context = const <String, dynamic>{}}): _context = context,super._();
  factory _EntityState.fromJson(Map<String, dynamic> json) => _$EntityStateFromJson(json);

@override final  String id;
@override final  String entityId;
@override final  String state;
@override final  DateTime since;
@override final  String? sourceEventId;
 final  Map<String, dynamic> _context;
@override@JsonKey() Map<String, dynamic> get context {
  if (_context is EqualUnmodifiableMapView) return _context;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_context);
}


/// Create a copy of EntityState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EntityStateCopyWith<_EntityState> get copyWith => __$EntityStateCopyWithImpl<_EntityState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EntityStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EntityState&&(identical(other.id, id) || other.id == id)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.state, state) || other.state == state)&&(identical(other.since, since) || other.since == since)&&(identical(other.sourceEventId, sourceEventId) || other.sourceEventId == sourceEventId)&&const DeepCollectionEquality().equals(other._context, _context));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,entityId,state,since,sourceEventId,const DeepCollectionEquality().hash(_context));

@override
String toString() {
  return 'EntityState(id: $id, entityId: $entityId, state: $state, since: $since, sourceEventId: $sourceEventId, context: $context)';
}


}

/// @nodoc
abstract mixin class _$EntityStateCopyWith<$Res> implements $EntityStateCopyWith<$Res> {
  factory _$EntityStateCopyWith(_EntityState value, $Res Function(_EntityState) _then) = __$EntityStateCopyWithImpl;
@override @useResult
$Res call({
 String id, String entityId, String state, DateTime since, String? sourceEventId, Map<String, dynamic> context
});




}
/// @nodoc
class __$EntityStateCopyWithImpl<$Res>
    implements _$EntityStateCopyWith<$Res> {
  __$EntityStateCopyWithImpl(this._self, this._then);

  final _EntityState _self;
  final $Res Function(_EntityState) _then;

/// Create a copy of EntityState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? entityId = null,Object? state = null,Object? since = null,Object? sourceEventId = freezed,Object? context = null,}) {
  return _then(_EntityState(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,since: null == since ? _self.since : since // ignore: cast_nullable_to_non_nullable
as DateTime,sourceEventId: freezed == sourceEventId ? _self.sourceEventId : sourceEventId // ignore: cast_nullable_to_non_nullable
as String?,context: null == context ? _self._context : context // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$MemoryEntity {

 String get id; String get name; EntityType get type; MemoryDomain get domain; String? get workspaceId; MemoryLifecycle get lifecycle; String get currentState; DateTime get createdAt; DateTime get updatedAt; DateTime get lastAccessedAt; Map<String, dynamic> get properties;
/// Create a copy of MemoryEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemoryEntityCopyWith<MemoryEntity> get copyWith => _$MemoryEntityCopyWithImpl<MemoryEntity>(this as MemoryEntity, _$identity);

  /// Serializes this MemoryEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemoryEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.domain, domain) || other.domain == domain)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.lifecycle, lifecycle) || other.lifecycle == lifecycle)&&(identical(other.currentState, currentState) || other.currentState == currentState)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.lastAccessedAt, lastAccessedAt) || other.lastAccessedAt == lastAccessedAt)&&const DeepCollectionEquality().equals(other.properties, properties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,domain,workspaceId,lifecycle,currentState,createdAt,updatedAt,lastAccessedAt,const DeepCollectionEquality().hash(properties));

@override
String toString() {
  return 'MemoryEntity(id: $id, name: $name, type: $type, domain: $domain, workspaceId: $workspaceId, lifecycle: $lifecycle, currentState: $currentState, createdAt: $createdAt, updatedAt: $updatedAt, lastAccessedAt: $lastAccessedAt, properties: $properties)';
}


}

/// @nodoc
abstract mixin class $MemoryEntityCopyWith<$Res>  {
  factory $MemoryEntityCopyWith(MemoryEntity value, $Res Function(MemoryEntity) _then) = _$MemoryEntityCopyWithImpl;
@useResult
$Res call({
 String id, String name, EntityType type, MemoryDomain domain, String? workspaceId, MemoryLifecycle lifecycle, String currentState, DateTime createdAt, DateTime updatedAt, DateTime lastAccessedAt, Map<String, dynamic> properties
});




}
/// @nodoc
class _$MemoryEntityCopyWithImpl<$Res>
    implements $MemoryEntityCopyWith<$Res> {
  _$MemoryEntityCopyWithImpl(this._self, this._then);

  final MemoryEntity _self;
  final $Res Function(MemoryEntity) _then;

/// Create a copy of MemoryEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? domain = null,Object? workspaceId = freezed,Object? lifecycle = null,Object? currentState = null,Object? createdAt = null,Object? updatedAt = null,Object? lastAccessedAt = null,Object? properties = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as EntityType,domain: null == domain ? _self.domain : domain // ignore: cast_nullable_to_non_nullable
as MemoryDomain,workspaceId: freezed == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String?,lifecycle: null == lifecycle ? _self.lifecycle : lifecycle // ignore: cast_nullable_to_non_nullable
as MemoryLifecycle,currentState: null == currentState ? _self.currentState : currentState // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastAccessedAt: null == lastAccessedAt ? _self.lastAccessedAt : lastAccessedAt // ignore: cast_nullable_to_non_nullable
as DateTime,properties: null == properties ? _self.properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [MemoryEntity].
extension MemoryEntityPatterns on MemoryEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemoryEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemoryEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemoryEntity value)  $default,){
final _that = this;
switch (_that) {
case _MemoryEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemoryEntity value)?  $default,){
final _that = this;
switch (_that) {
case _MemoryEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  EntityType type,  MemoryDomain domain,  String? workspaceId,  MemoryLifecycle lifecycle,  String currentState,  DateTime createdAt,  DateTime updatedAt,  DateTime lastAccessedAt,  Map<String, dynamic> properties)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemoryEntity() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.domain,_that.workspaceId,_that.lifecycle,_that.currentState,_that.createdAt,_that.updatedAt,_that.lastAccessedAt,_that.properties);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  EntityType type,  MemoryDomain domain,  String? workspaceId,  MemoryLifecycle lifecycle,  String currentState,  DateTime createdAt,  DateTime updatedAt,  DateTime lastAccessedAt,  Map<String, dynamic> properties)  $default,) {final _that = this;
switch (_that) {
case _MemoryEntity():
return $default(_that.id,_that.name,_that.type,_that.domain,_that.workspaceId,_that.lifecycle,_that.currentState,_that.createdAt,_that.updatedAt,_that.lastAccessedAt,_that.properties);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  EntityType type,  MemoryDomain domain,  String? workspaceId,  MemoryLifecycle lifecycle,  String currentState,  DateTime createdAt,  DateTime updatedAt,  DateTime lastAccessedAt,  Map<String, dynamic> properties)?  $default,) {final _that = this;
switch (_that) {
case _MemoryEntity() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.domain,_that.workspaceId,_that.lifecycle,_that.currentState,_that.createdAt,_that.updatedAt,_that.lastAccessedAt,_that.properties);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemoryEntity extends MemoryEntity {
  const _MemoryEntity({required this.id, required this.name, required this.type, this.domain = MemoryDomain.project, this.workspaceId, this.lifecycle = MemoryLifecycle.active, this.currentState = 'unknown', required this.createdAt, required this.updatedAt, required this.lastAccessedAt, final  Map<String, dynamic> properties = const <String, dynamic>{}}): _properties = properties,super._();
  factory _MemoryEntity.fromJson(Map<String, dynamic> json) => _$MemoryEntityFromJson(json);

@override final  String id;
@override final  String name;
@override final  EntityType type;
@override@JsonKey() final  MemoryDomain domain;
@override final  String? workspaceId;
@override@JsonKey() final  MemoryLifecycle lifecycle;
@override@JsonKey() final  String currentState;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  DateTime lastAccessedAt;
 final  Map<String, dynamic> _properties;
@override@JsonKey() Map<String, dynamic> get properties {
  if (_properties is EqualUnmodifiableMapView) return _properties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_properties);
}


/// Create a copy of MemoryEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemoryEntityCopyWith<_MemoryEntity> get copyWith => __$MemoryEntityCopyWithImpl<_MemoryEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemoryEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemoryEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.domain, domain) || other.domain == domain)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.lifecycle, lifecycle) || other.lifecycle == lifecycle)&&(identical(other.currentState, currentState) || other.currentState == currentState)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.lastAccessedAt, lastAccessedAt) || other.lastAccessedAt == lastAccessedAt)&&const DeepCollectionEquality().equals(other._properties, _properties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,domain,workspaceId,lifecycle,currentState,createdAt,updatedAt,lastAccessedAt,const DeepCollectionEquality().hash(_properties));

@override
String toString() {
  return 'MemoryEntity(id: $id, name: $name, type: $type, domain: $domain, workspaceId: $workspaceId, lifecycle: $lifecycle, currentState: $currentState, createdAt: $createdAt, updatedAt: $updatedAt, lastAccessedAt: $lastAccessedAt, properties: $properties)';
}


}

/// @nodoc
abstract mixin class _$MemoryEntityCopyWith<$Res> implements $MemoryEntityCopyWith<$Res> {
  factory _$MemoryEntityCopyWith(_MemoryEntity value, $Res Function(_MemoryEntity) _then) = __$MemoryEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, EntityType type, MemoryDomain domain, String? workspaceId, MemoryLifecycle lifecycle, String currentState, DateTime createdAt, DateTime updatedAt, DateTime lastAccessedAt, Map<String, dynamic> properties
});




}
/// @nodoc
class __$MemoryEntityCopyWithImpl<$Res>
    implements _$MemoryEntityCopyWith<$Res> {
  __$MemoryEntityCopyWithImpl(this._self, this._then);

  final _MemoryEntity _self;
  final $Res Function(_MemoryEntity) _then;

/// Create a copy of MemoryEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? domain = null,Object? workspaceId = freezed,Object? lifecycle = null,Object? currentState = null,Object? createdAt = null,Object? updatedAt = null,Object? lastAccessedAt = null,Object? properties = null,}) {
  return _then(_MemoryEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as EntityType,domain: null == domain ? _self.domain : domain // ignore: cast_nullable_to_non_nullable
as MemoryDomain,workspaceId: freezed == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String?,lifecycle: null == lifecycle ? _self.lifecycle : lifecycle // ignore: cast_nullable_to_non_nullable
as MemoryLifecycle,currentState: null == currentState ? _self.currentState : currentState // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastAccessedAt: null == lastAccessedAt ? _self.lastAccessedAt : lastAccessedAt // ignore: cast_nullable_to_non_nullable
as DateTime,properties: null == properties ? _self._properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$EntityRelation {

 String get id; String get fromEntityId; String get toEntityId; RelationType get type; double get strength; DateTime get since; String? get sourceEventId; Map<String, dynamic> get metadata;
/// Create a copy of EntityRelation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntityRelationCopyWith<EntityRelation> get copyWith => _$EntityRelationCopyWithImpl<EntityRelation>(this as EntityRelation, _$identity);

  /// Serializes this EntityRelation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EntityRelation&&(identical(other.id, id) || other.id == id)&&(identical(other.fromEntityId, fromEntityId) || other.fromEntityId == fromEntityId)&&(identical(other.toEntityId, toEntityId) || other.toEntityId == toEntityId)&&(identical(other.type, type) || other.type == type)&&(identical(other.strength, strength) || other.strength == strength)&&(identical(other.since, since) || other.since == since)&&(identical(other.sourceEventId, sourceEventId) || other.sourceEventId == sourceEventId)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fromEntityId,toEntityId,type,strength,since,sourceEventId,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'EntityRelation(id: $id, fromEntityId: $fromEntityId, toEntityId: $toEntityId, type: $type, strength: $strength, since: $since, sourceEventId: $sourceEventId, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $EntityRelationCopyWith<$Res>  {
  factory $EntityRelationCopyWith(EntityRelation value, $Res Function(EntityRelation) _then) = _$EntityRelationCopyWithImpl;
@useResult
$Res call({
 String id, String fromEntityId, String toEntityId, RelationType type, double strength, DateTime since, String? sourceEventId, Map<String, dynamic> metadata
});




}
/// @nodoc
class _$EntityRelationCopyWithImpl<$Res>
    implements $EntityRelationCopyWith<$Res> {
  _$EntityRelationCopyWithImpl(this._self, this._then);

  final EntityRelation _self;
  final $Res Function(EntityRelation) _then;

/// Create a copy of EntityRelation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fromEntityId = null,Object? toEntityId = null,Object? type = null,Object? strength = null,Object? since = null,Object? sourceEventId = freezed,Object? metadata = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fromEntityId: null == fromEntityId ? _self.fromEntityId : fromEntityId // ignore: cast_nullable_to_non_nullable
as String,toEntityId: null == toEntityId ? _self.toEntityId : toEntityId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as RelationType,strength: null == strength ? _self.strength : strength // ignore: cast_nullable_to_non_nullable
as double,since: null == since ? _self.since : since // ignore: cast_nullable_to_non_nullable
as DateTime,sourceEventId: freezed == sourceEventId ? _self.sourceEventId : sourceEventId // ignore: cast_nullable_to_non_nullable
as String?,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [EntityRelation].
extension EntityRelationPatterns on EntityRelation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EntityRelation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EntityRelation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EntityRelation value)  $default,){
final _that = this;
switch (_that) {
case _EntityRelation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EntityRelation value)?  $default,){
final _that = this;
switch (_that) {
case _EntityRelation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fromEntityId,  String toEntityId,  RelationType type,  double strength,  DateTime since,  String? sourceEventId,  Map<String, dynamic> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EntityRelation() when $default != null:
return $default(_that.id,_that.fromEntityId,_that.toEntityId,_that.type,_that.strength,_that.since,_that.sourceEventId,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fromEntityId,  String toEntityId,  RelationType type,  double strength,  DateTime since,  String? sourceEventId,  Map<String, dynamic> metadata)  $default,) {final _that = this;
switch (_that) {
case _EntityRelation():
return $default(_that.id,_that.fromEntityId,_that.toEntityId,_that.type,_that.strength,_that.since,_that.sourceEventId,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fromEntityId,  String toEntityId,  RelationType type,  double strength,  DateTime since,  String? sourceEventId,  Map<String, dynamic> metadata)?  $default,) {final _that = this;
switch (_that) {
case _EntityRelation() when $default != null:
return $default(_that.id,_that.fromEntityId,_that.toEntityId,_that.type,_that.strength,_that.since,_that.sourceEventId,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EntityRelation extends EntityRelation {
  const _EntityRelation({required this.id, required this.fromEntityId, required this.toEntityId, required this.type, this.strength = 1.0, required this.since, this.sourceEventId, final  Map<String, dynamic> metadata = const <String, dynamic>{}}): _metadata = metadata,super._();
  factory _EntityRelation.fromJson(Map<String, dynamic> json) => _$EntityRelationFromJson(json);

@override final  String id;
@override final  String fromEntityId;
@override final  String toEntityId;
@override final  RelationType type;
@override@JsonKey() final  double strength;
@override final  DateTime since;
@override final  String? sourceEventId;
 final  Map<String, dynamic> _metadata;
@override@JsonKey() Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}


/// Create a copy of EntityRelation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EntityRelationCopyWith<_EntityRelation> get copyWith => __$EntityRelationCopyWithImpl<_EntityRelation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EntityRelationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EntityRelation&&(identical(other.id, id) || other.id == id)&&(identical(other.fromEntityId, fromEntityId) || other.fromEntityId == fromEntityId)&&(identical(other.toEntityId, toEntityId) || other.toEntityId == toEntityId)&&(identical(other.type, type) || other.type == type)&&(identical(other.strength, strength) || other.strength == strength)&&(identical(other.since, since) || other.since == since)&&(identical(other.sourceEventId, sourceEventId) || other.sourceEventId == sourceEventId)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fromEntityId,toEntityId,type,strength,since,sourceEventId,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'EntityRelation(id: $id, fromEntityId: $fromEntityId, toEntityId: $toEntityId, type: $type, strength: $strength, since: $since, sourceEventId: $sourceEventId, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$EntityRelationCopyWith<$Res> implements $EntityRelationCopyWith<$Res> {
  factory _$EntityRelationCopyWith(_EntityRelation value, $Res Function(_EntityRelation) _then) = __$EntityRelationCopyWithImpl;
@override @useResult
$Res call({
 String id, String fromEntityId, String toEntityId, RelationType type, double strength, DateTime since, String? sourceEventId, Map<String, dynamic> metadata
});




}
/// @nodoc
class __$EntityRelationCopyWithImpl<$Res>
    implements _$EntityRelationCopyWith<$Res> {
  __$EntityRelationCopyWithImpl(this._self, this._then);

  final _EntityRelation _self;
  final $Res Function(_EntityRelation) _then;

/// Create a copy of EntityRelation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fromEntityId = null,Object? toEntityId = null,Object? type = null,Object? strength = null,Object? since = null,Object? sourceEventId = freezed,Object? metadata = null,}) {
  return _then(_EntityRelation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fromEntityId: null == fromEntityId ? _self.fromEntityId : fromEntityId // ignore: cast_nullable_to_non_nullable
as String,toEntityId: null == toEntityId ? _self.toEntityId : toEntityId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as RelationType,strength: null == strength ? _self.strength : strength // ignore: cast_nullable_to_non_nullable
as double,since: null == since ? _self.since : since // ignore: cast_nullable_to_non_nullable
as DateTime,sourceEventId: freezed == sourceEventId ? _self.sourceEventId : sourceEventId // ignore: cast_nullable_to_non_nullable
as String?,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
