// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'node_descriptor.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NodeDescriptor {

 String get nodeId; String get address; int get port; NodeRole get role; NodeState get state; int get incarnation; int get joinedAt; int get lastHeartbeatAt; Map<String, String> get metadata;
/// Create a copy of NodeDescriptor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodeDescriptorCopyWith<NodeDescriptor> get copyWith => _$NodeDescriptorCopyWithImpl<NodeDescriptor>(this as NodeDescriptor, _$identity);

  /// Serializes this NodeDescriptor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodeDescriptor&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId)&&(identical(other.address, address) || other.address == address)&&(identical(other.port, port) || other.port == port)&&(identical(other.role, role) || other.role == role)&&(identical(other.state, state) || other.state == state)&&(identical(other.incarnation, incarnation) || other.incarnation == incarnation)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.lastHeartbeatAt, lastHeartbeatAt) || other.lastHeartbeatAt == lastHeartbeatAt)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,nodeId,address,port,role,state,incarnation,joinedAt,lastHeartbeatAt,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'NodeDescriptor(nodeId: $nodeId, address: $address, port: $port, role: $role, state: $state, incarnation: $incarnation, joinedAt: $joinedAt, lastHeartbeatAt: $lastHeartbeatAt, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $NodeDescriptorCopyWith<$Res>  {
  factory $NodeDescriptorCopyWith(NodeDescriptor value, $Res Function(NodeDescriptor) _then) = _$NodeDescriptorCopyWithImpl;
@useResult
$Res call({
 String nodeId, String address, int port, NodeRole role, NodeState state, int incarnation, int joinedAt, int lastHeartbeatAt, Map<String, String> metadata
});




}
/// @nodoc
class _$NodeDescriptorCopyWithImpl<$Res>
    implements $NodeDescriptorCopyWith<$Res> {
  _$NodeDescriptorCopyWithImpl(this._self, this._then);

  final NodeDescriptor _self;
  final $Res Function(NodeDescriptor) _then;

/// Create a copy of NodeDescriptor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nodeId = null,Object? address = null,Object? port = null,Object? role = null,Object? state = null,Object? incarnation = null,Object? joinedAt = null,Object? lastHeartbeatAt = null,Object? metadata = null,}) {
  return _then(_self.copyWith(
nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as NodeRole,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as NodeState,incarnation: null == incarnation ? _self.incarnation : incarnation // ignore: cast_nullable_to_non_nullable
as int,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as int,lastHeartbeatAt: null == lastHeartbeatAt ? _self.lastHeartbeatAt : lastHeartbeatAt // ignore: cast_nullable_to_non_nullable
as int,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [NodeDescriptor].
extension NodeDescriptorPatterns on NodeDescriptor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NodeDescriptor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NodeDescriptor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NodeDescriptor value)  $default,){
final _that = this;
switch (_that) {
case _NodeDescriptor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NodeDescriptor value)?  $default,){
final _that = this;
switch (_that) {
case _NodeDescriptor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String nodeId,  String address,  int port,  NodeRole role,  NodeState state,  int incarnation,  int joinedAt,  int lastHeartbeatAt,  Map<String, String> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NodeDescriptor() when $default != null:
return $default(_that.nodeId,_that.address,_that.port,_that.role,_that.state,_that.incarnation,_that.joinedAt,_that.lastHeartbeatAt,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String nodeId,  String address,  int port,  NodeRole role,  NodeState state,  int incarnation,  int joinedAt,  int lastHeartbeatAt,  Map<String, String> metadata)  $default,) {final _that = this;
switch (_that) {
case _NodeDescriptor():
return $default(_that.nodeId,_that.address,_that.port,_that.role,_that.state,_that.incarnation,_that.joinedAt,_that.lastHeartbeatAt,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String nodeId,  String address,  int port,  NodeRole role,  NodeState state,  int incarnation,  int joinedAt,  int lastHeartbeatAt,  Map<String, String> metadata)?  $default,) {final _that = this;
switch (_that) {
case _NodeDescriptor() when $default != null:
return $default(_that.nodeId,_that.address,_that.port,_that.role,_that.state,_that.incarnation,_that.joinedAt,_that.lastHeartbeatAt,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NodeDescriptor extends NodeDescriptor {
  const _NodeDescriptor({required this.nodeId, required this.address, this.port = 0, this.role = NodeRole.worker, this.state = NodeState.joining, this.incarnation = 0, this.joinedAt = 0, this.lastHeartbeatAt = 0, final  Map<String, String> metadata = const <String, String>{}}): _metadata = metadata,super._();
  factory _NodeDescriptor.fromJson(Map<String, dynamic> json) => _$NodeDescriptorFromJson(json);

@override final  String nodeId;
@override final  String address;
@override@JsonKey() final  int port;
@override@JsonKey() final  NodeRole role;
@override@JsonKey() final  NodeState state;
@override@JsonKey() final  int incarnation;
@override@JsonKey() final  int joinedAt;
@override@JsonKey() final  int lastHeartbeatAt;
 final  Map<String, String> _metadata;
@override@JsonKey() Map<String, String> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}


/// Create a copy of NodeDescriptor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NodeDescriptorCopyWith<_NodeDescriptor> get copyWith => __$NodeDescriptorCopyWithImpl<_NodeDescriptor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NodeDescriptorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NodeDescriptor&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId)&&(identical(other.address, address) || other.address == address)&&(identical(other.port, port) || other.port == port)&&(identical(other.role, role) || other.role == role)&&(identical(other.state, state) || other.state == state)&&(identical(other.incarnation, incarnation) || other.incarnation == incarnation)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.lastHeartbeatAt, lastHeartbeatAt) || other.lastHeartbeatAt == lastHeartbeatAt)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,nodeId,address,port,role,state,incarnation,joinedAt,lastHeartbeatAt,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'NodeDescriptor(nodeId: $nodeId, address: $address, port: $port, role: $role, state: $state, incarnation: $incarnation, joinedAt: $joinedAt, lastHeartbeatAt: $lastHeartbeatAt, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$NodeDescriptorCopyWith<$Res> implements $NodeDescriptorCopyWith<$Res> {
  factory _$NodeDescriptorCopyWith(_NodeDescriptor value, $Res Function(_NodeDescriptor) _then) = __$NodeDescriptorCopyWithImpl;
@override @useResult
$Res call({
 String nodeId, String address, int port, NodeRole role, NodeState state, int incarnation, int joinedAt, int lastHeartbeatAt, Map<String, String> metadata
});




}
/// @nodoc
class __$NodeDescriptorCopyWithImpl<$Res>
    implements _$NodeDescriptorCopyWith<$Res> {
  __$NodeDescriptorCopyWithImpl(this._self, this._then);

  final _NodeDescriptor _self;
  final $Res Function(_NodeDescriptor) _then;

/// Create a copy of NodeDescriptor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nodeId = null,Object? address = null,Object? port = null,Object? role = null,Object? state = null,Object? incarnation = null,Object? joinedAt = null,Object? lastHeartbeatAt = null,Object? metadata = null,}) {
  return _then(_NodeDescriptor(
nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as NodeRole,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as NodeState,incarnation: null == incarnation ? _self.incarnation : incarnation // ignore: cast_nullable_to_non_nullable
as int,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as int,lastHeartbeatAt: null == lastHeartbeatAt ? _self.lastHeartbeatAt : lastHeartbeatAt // ignore: cast_nullable_to_non_nullable
as int,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on
