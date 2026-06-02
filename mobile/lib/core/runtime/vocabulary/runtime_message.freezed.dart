// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'runtime_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RuntimeMessage {

 String get id; int get version; String get type; RuntimeRoute get source; RuntimeRoute get target; Object? get payload; RuntimeMetadata get metadata; PropagationScope get scope; int get timestamp;
/// Create a copy of RuntimeMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RuntimeMessageCopyWith<RuntimeMessage> get copyWith => _$RuntimeMessageCopyWithImpl<RuntimeMessage>(this as RuntimeMessage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RuntimeMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.version, version) || other.version == version)&&(identical(other.type, type) || other.type == type)&&(identical(other.source, source) || other.source == source)&&(identical(other.target, target) || other.target == target)&&const DeepCollectionEquality().equals(other.payload, payload)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&const DeepCollectionEquality().equals(other.scope, scope)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}


@override
int get hashCode => Object.hash(runtimeType,id,version,type,source,target,const DeepCollectionEquality().hash(payload),metadata,const DeepCollectionEquality().hash(scope),timestamp);

@override
String toString() {
  return 'RuntimeMessage(id: $id, version: $version, type: $type, source: $source, target: $target, payload: $payload, metadata: $metadata, scope: $scope, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class $RuntimeMessageCopyWith<$Res>  {
  factory $RuntimeMessageCopyWith(RuntimeMessage value, $Res Function(RuntimeMessage) _then) = _$RuntimeMessageCopyWithImpl;
@useResult
$Res call({
 String id, int version, String type, RuntimeRoute source, RuntimeRoute target, Object? payload, RuntimeMetadata metadata, PropagationScope scope, int timestamp
});


$RuntimeRouteCopyWith<$Res> get source;$RuntimeRouteCopyWith<$Res> get target;$RuntimeMetadataCopyWith<$Res> get metadata;

}
/// @nodoc
class _$RuntimeMessageCopyWithImpl<$Res>
    implements $RuntimeMessageCopyWith<$Res> {
  _$RuntimeMessageCopyWithImpl(this._self, this._then);

  final RuntimeMessage _self;
  final $Res Function(RuntimeMessage) _then;

/// Create a copy of RuntimeMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? version = null,Object? type = null,Object? source = null,Object? target = null,Object? payload = freezed,Object? metadata = null,Object? scope = freezed,Object? timestamp = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as RuntimeRoute,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as RuntimeRoute,payload: freezed == payload ? _self.payload : payload ,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as RuntimeMetadata,scope: freezed == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PropagationScope,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of RuntimeMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RuntimeRouteCopyWith<$Res> get source {
  
  return $RuntimeRouteCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of RuntimeMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RuntimeRouteCopyWith<$Res> get target {
  
  return $RuntimeRouteCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of RuntimeMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RuntimeMetadataCopyWith<$Res> get metadata {
  
  return $RuntimeMetadataCopyWith<$Res>(_self.metadata, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// Adds pattern-matching-related methods to [RuntimeMessage].
extension RuntimeMessagePatterns on RuntimeMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RuntimeMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RuntimeMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RuntimeMessage value)  $default,){
final _that = this;
switch (_that) {
case _RuntimeMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RuntimeMessage value)?  $default,){
final _that = this;
switch (_that) {
case _RuntimeMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int version,  String type,  RuntimeRoute source,  RuntimeRoute target,  Object? payload,  RuntimeMetadata metadata,  PropagationScope scope,  int timestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RuntimeMessage() when $default != null:
return $default(_that.id,_that.version,_that.type,_that.source,_that.target,_that.payload,_that.metadata,_that.scope,_that.timestamp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int version,  String type,  RuntimeRoute source,  RuntimeRoute target,  Object? payload,  RuntimeMetadata metadata,  PropagationScope scope,  int timestamp)  $default,) {final _that = this;
switch (_that) {
case _RuntimeMessage():
return $default(_that.id,_that.version,_that.type,_that.source,_that.target,_that.payload,_that.metadata,_that.scope,_that.timestamp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int version,  String type,  RuntimeRoute source,  RuntimeRoute target,  Object? payload,  RuntimeMetadata metadata,  PropagationScope scope,  int timestamp)?  $default,) {final _that = this;
switch (_that) {
case _RuntimeMessage() when $default != null:
return $default(_that.id,_that.version,_that.type,_that.source,_that.target,_that.payload,_that.metadata,_that.scope,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc


class _RuntimeMessage extends RuntimeMessage {
  const _RuntimeMessage({required this.id, this.version = 1, required this.type, required this.source, required this.target, this.payload, required this.metadata, this.scope = PropagationScope.local, required this.timestamp}): super._();
  

@override final  String id;
@override@JsonKey() final  int version;
@override final  String type;
@override final  RuntimeRoute source;
@override final  RuntimeRoute target;
@override final  Object? payload;
@override final  RuntimeMetadata metadata;
@override@JsonKey() final  PropagationScope scope;
@override final  int timestamp;

/// Create a copy of RuntimeMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RuntimeMessageCopyWith<_RuntimeMessage> get copyWith => __$RuntimeMessageCopyWithImpl<_RuntimeMessage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RuntimeMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.version, version) || other.version == version)&&(identical(other.type, type) || other.type == type)&&(identical(other.source, source) || other.source == source)&&(identical(other.target, target) || other.target == target)&&const DeepCollectionEquality().equals(other.payload, payload)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&const DeepCollectionEquality().equals(other.scope, scope)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}


@override
int get hashCode => Object.hash(runtimeType,id,version,type,source,target,const DeepCollectionEquality().hash(payload),metadata,const DeepCollectionEquality().hash(scope),timestamp);

@override
String toString() {
  return 'RuntimeMessage(id: $id, version: $version, type: $type, source: $source, target: $target, payload: $payload, metadata: $metadata, scope: $scope, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class _$RuntimeMessageCopyWith<$Res> implements $RuntimeMessageCopyWith<$Res> {
  factory _$RuntimeMessageCopyWith(_RuntimeMessage value, $Res Function(_RuntimeMessage) _then) = __$RuntimeMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, int version, String type, RuntimeRoute source, RuntimeRoute target, Object? payload, RuntimeMetadata metadata, PropagationScope scope, int timestamp
});


@override $RuntimeRouteCopyWith<$Res> get source;@override $RuntimeRouteCopyWith<$Res> get target;@override $RuntimeMetadataCopyWith<$Res> get metadata;

}
/// @nodoc
class __$RuntimeMessageCopyWithImpl<$Res>
    implements _$RuntimeMessageCopyWith<$Res> {
  __$RuntimeMessageCopyWithImpl(this._self, this._then);

  final _RuntimeMessage _self;
  final $Res Function(_RuntimeMessage) _then;

/// Create a copy of RuntimeMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? version = null,Object? type = null,Object? source = null,Object? target = null,Object? payload = freezed,Object? metadata = null,Object? scope = freezed,Object? timestamp = null,}) {
  return _then(_RuntimeMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as RuntimeRoute,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as RuntimeRoute,payload: freezed == payload ? _self.payload : payload ,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as RuntimeMetadata,scope: freezed == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PropagationScope,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of RuntimeMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RuntimeRouteCopyWith<$Res> get source {
  
  return $RuntimeRouteCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of RuntimeMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RuntimeRouteCopyWith<$Res> get target {
  
  return $RuntimeRouteCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of RuntimeMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RuntimeMetadataCopyWith<$Res> get metadata {
  
  return $RuntimeMetadataCopyWith<$Res>(_self.metadata, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}

// dart format on
