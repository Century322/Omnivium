// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'world_state_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorldObject {

 String get id; String get name; String get type; WorldObjectStatus get status; double get progress; String? get description; String? get workspaceId; String? get parentId; List<String> get childrenIds; Map<String, dynamic> get properties; List<String> get blockers; String? get assignedAgentId; DateTime get lastModified;
/// Create a copy of WorldObject
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorldObjectCopyWith<WorldObject> get copyWith => _$WorldObjectCopyWithImpl<WorldObject>(this as WorldObject, _$identity);

  /// Serializes this WorldObject to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorldObject&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.description, description) || other.description == description)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&const DeepCollectionEquality().equals(other.childrenIds, childrenIds)&&const DeepCollectionEquality().equals(other.properties, properties)&&const DeepCollectionEquality().equals(other.blockers, blockers)&&(identical(other.assignedAgentId, assignedAgentId) || other.assignedAgentId == assignedAgentId)&&(identical(other.lastModified, lastModified) || other.lastModified == lastModified));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,status,progress,description,workspaceId,parentId,const DeepCollectionEquality().hash(childrenIds),const DeepCollectionEquality().hash(properties),const DeepCollectionEquality().hash(blockers),assignedAgentId,lastModified);

@override
String toString() {
  return 'WorldObject(id: $id, name: $name, type: $type, status: $status, progress: $progress, description: $description, workspaceId: $workspaceId, parentId: $parentId, childrenIds: $childrenIds, properties: $properties, blockers: $blockers, assignedAgentId: $assignedAgentId, lastModified: $lastModified)';
}


}

/// @nodoc
abstract mixin class $WorldObjectCopyWith<$Res>  {
  factory $WorldObjectCopyWith(WorldObject value, $Res Function(WorldObject) _then) = _$WorldObjectCopyWithImpl;
@useResult
$Res call({
 String id, String name, String type, WorldObjectStatus status, double progress, String? description, String? workspaceId, String? parentId, List<String> childrenIds, Map<String, dynamic> properties, List<String> blockers, String? assignedAgentId, DateTime lastModified
});




}
/// @nodoc
class _$WorldObjectCopyWithImpl<$Res>
    implements $WorldObjectCopyWith<$Res> {
  _$WorldObjectCopyWithImpl(this._self, this._then);

  final WorldObject _self;
  final $Res Function(WorldObject) _then;

/// Create a copy of WorldObject
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? status = null,Object? progress = null,Object? description = freezed,Object? workspaceId = freezed,Object? parentId = freezed,Object? childrenIds = null,Object? properties = null,Object? blockers = null,Object? assignedAgentId = freezed,Object? lastModified = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WorldObjectStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,workspaceId: freezed == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String?,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,childrenIds: null == childrenIds ? _self.childrenIds : childrenIds // ignore: cast_nullable_to_non_nullable
as List<String>,properties: null == properties ? _self.properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,blockers: null == blockers ? _self.blockers : blockers // ignore: cast_nullable_to_non_nullable
as List<String>,assignedAgentId: freezed == assignedAgentId ? _self.assignedAgentId : assignedAgentId // ignore: cast_nullable_to_non_nullable
as String?,lastModified: null == lastModified ? _self.lastModified : lastModified // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [WorldObject].
extension WorldObjectPatterns on WorldObject {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorldObject value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorldObject() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorldObject value)  $default,){
final _that = this;
switch (_that) {
case _WorldObject():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorldObject value)?  $default,){
final _that = this;
switch (_that) {
case _WorldObject() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String type,  WorldObjectStatus status,  double progress,  String? description,  String? workspaceId,  String? parentId,  List<String> childrenIds,  Map<String, dynamic> properties,  List<String> blockers,  String? assignedAgentId,  DateTime lastModified)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorldObject() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.status,_that.progress,_that.description,_that.workspaceId,_that.parentId,_that.childrenIds,_that.properties,_that.blockers,_that.assignedAgentId,_that.lastModified);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String type,  WorldObjectStatus status,  double progress,  String? description,  String? workspaceId,  String? parentId,  List<String> childrenIds,  Map<String, dynamic> properties,  List<String> blockers,  String? assignedAgentId,  DateTime lastModified)  $default,) {final _that = this;
switch (_that) {
case _WorldObject():
return $default(_that.id,_that.name,_that.type,_that.status,_that.progress,_that.description,_that.workspaceId,_that.parentId,_that.childrenIds,_that.properties,_that.blockers,_that.assignedAgentId,_that.lastModified);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String type,  WorldObjectStatus status,  double progress,  String? description,  String? workspaceId,  String? parentId,  List<String> childrenIds,  Map<String, dynamic> properties,  List<String> blockers,  String? assignedAgentId,  DateTime lastModified)?  $default,) {final _that = this;
switch (_that) {
case _WorldObject() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.status,_that.progress,_that.description,_that.workspaceId,_that.parentId,_that.childrenIds,_that.properties,_that.blockers,_that.assignedAgentId,_that.lastModified);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorldObject extends WorldObject {
  const _WorldObject({required this.id, required this.name, required this.type, required this.status, this.progress = 0, this.description, this.workspaceId, this.parentId, final  List<String> childrenIds = const <String>[], final  Map<String, dynamic> properties = const <String, dynamic>{}, final  List<String> blockers = const <String>[], this.assignedAgentId, required this.lastModified}): _childrenIds = childrenIds,_properties = properties,_blockers = blockers,super._();
  factory _WorldObject.fromJson(Map<String, dynamic> json) => _$WorldObjectFromJson(json);

@override final  String id;
@override final  String name;
@override final  String type;
@override final  WorldObjectStatus status;
@override@JsonKey() final  double progress;
@override final  String? description;
@override final  String? workspaceId;
@override final  String? parentId;
 final  List<String> _childrenIds;
@override@JsonKey() List<String> get childrenIds {
  if (_childrenIds is EqualUnmodifiableListView) return _childrenIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_childrenIds);
}

 final  Map<String, dynamic> _properties;
@override@JsonKey() Map<String, dynamic> get properties {
  if (_properties is EqualUnmodifiableMapView) return _properties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_properties);
}

 final  List<String> _blockers;
@override@JsonKey() List<String> get blockers {
  if (_blockers is EqualUnmodifiableListView) return _blockers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_blockers);
}

@override final  String? assignedAgentId;
@override final  DateTime lastModified;

/// Create a copy of WorldObject
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorldObjectCopyWith<_WorldObject> get copyWith => __$WorldObjectCopyWithImpl<_WorldObject>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorldObjectToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorldObject&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.description, description) || other.description == description)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&const DeepCollectionEquality().equals(other._childrenIds, _childrenIds)&&const DeepCollectionEquality().equals(other._properties, _properties)&&const DeepCollectionEquality().equals(other._blockers, _blockers)&&(identical(other.assignedAgentId, assignedAgentId) || other.assignedAgentId == assignedAgentId)&&(identical(other.lastModified, lastModified) || other.lastModified == lastModified));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,status,progress,description,workspaceId,parentId,const DeepCollectionEquality().hash(_childrenIds),const DeepCollectionEquality().hash(_properties),const DeepCollectionEquality().hash(_blockers),assignedAgentId,lastModified);

@override
String toString() {
  return 'WorldObject(id: $id, name: $name, type: $type, status: $status, progress: $progress, description: $description, workspaceId: $workspaceId, parentId: $parentId, childrenIds: $childrenIds, properties: $properties, blockers: $blockers, assignedAgentId: $assignedAgentId, lastModified: $lastModified)';
}


}

/// @nodoc
abstract mixin class _$WorldObjectCopyWith<$Res> implements $WorldObjectCopyWith<$Res> {
  factory _$WorldObjectCopyWith(_WorldObject value, $Res Function(_WorldObject) _then) = __$WorldObjectCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String type, WorldObjectStatus status, double progress, String? description, String? workspaceId, String? parentId, List<String> childrenIds, Map<String, dynamic> properties, List<String> blockers, String? assignedAgentId, DateTime lastModified
});




}
/// @nodoc
class __$WorldObjectCopyWithImpl<$Res>
    implements _$WorldObjectCopyWith<$Res> {
  __$WorldObjectCopyWithImpl(this._self, this._then);

  final _WorldObject _self;
  final $Res Function(_WorldObject) _then;

/// Create a copy of WorldObject
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? status = null,Object? progress = null,Object? description = freezed,Object? workspaceId = freezed,Object? parentId = freezed,Object? childrenIds = null,Object? properties = null,Object? blockers = null,Object? assignedAgentId = freezed,Object? lastModified = null,}) {
  return _then(_WorldObject(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WorldObjectStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,workspaceId: freezed == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String?,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,childrenIds: null == childrenIds ? _self._childrenIds : childrenIds // ignore: cast_nullable_to_non_nullable
as List<String>,properties: null == properties ? _self._properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,blockers: null == blockers ? _self._blockers : blockers // ignore: cast_nullable_to_non_nullable
as List<String>,assignedAgentId: freezed == assignedAgentId ? _self.assignedAgentId : assignedAgentId // ignore: cast_nullable_to_non_nullable
as String?,lastModified: null == lastModified ? _self.lastModified : lastModified // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
