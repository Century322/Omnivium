// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'runtime_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RuntimeEvent {

 String get id; String get type; RuntimeRoute get source; Object? get data; RuntimeMetadata get metadata; PropagationScope get scope; bool get cancelled;
/// Create a copy of RuntimeEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RuntimeEventCopyWith<RuntimeEvent> get copyWith => _$RuntimeEventCopyWithImpl<RuntimeEvent>(this as RuntimeEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RuntimeEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&const DeepCollectionEquality().equals(other.scope, scope)&&(identical(other.cancelled, cancelled) || other.cancelled == cancelled));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,source,const DeepCollectionEquality().hash(data),metadata,const DeepCollectionEquality().hash(scope),cancelled);

@override
String toString() {
  return 'RuntimeEvent(id: $id, type: $type, source: $source, data: $data, metadata: $metadata, scope: $scope, cancelled: $cancelled)';
}


}

/// @nodoc
abstract mixin class $RuntimeEventCopyWith<$Res>  {
  factory $RuntimeEventCopyWith(RuntimeEvent value, $Res Function(RuntimeEvent) _then) = _$RuntimeEventCopyWithImpl;
@useResult
$Res call({
 String id, String type, RuntimeRoute source, Object? data, RuntimeMetadata metadata, PropagationScope scope, bool cancelled
});


$RuntimeRouteCopyWith<$Res> get source;$RuntimeMetadataCopyWith<$Res> get metadata;

}
/// @nodoc
class _$RuntimeEventCopyWithImpl<$Res>
    implements $RuntimeEventCopyWith<$Res> {
  _$RuntimeEventCopyWithImpl(this._self, this._then);

  final RuntimeEvent _self;
  final $Res Function(RuntimeEvent) _then;

/// Create a copy of RuntimeEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? source = null,Object? data = freezed,Object? metadata = null,Object? scope = freezed,Object? cancelled = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as RuntimeRoute,data: freezed == data ? _self.data : data ,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as RuntimeMetadata,scope: freezed == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PropagationScope,cancelled: null == cancelled ? _self.cancelled : cancelled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of RuntimeEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RuntimeRouteCopyWith<$Res> get source {
  
  return $RuntimeRouteCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of RuntimeEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RuntimeMetadataCopyWith<$Res> get metadata {
  
  return $RuntimeMetadataCopyWith<$Res>(_self.metadata, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// Adds pattern-matching-related methods to [RuntimeEvent].
extension RuntimeEventPatterns on RuntimeEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RuntimeEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RuntimeEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RuntimeEvent value)  $default,){
final _that = this;
switch (_that) {
case _RuntimeEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RuntimeEvent value)?  $default,){
final _that = this;
switch (_that) {
case _RuntimeEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String type,  RuntimeRoute source,  Object? data,  RuntimeMetadata metadata,  PropagationScope scope,  bool cancelled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RuntimeEvent() when $default != null:
return $default(_that.id,_that.type,_that.source,_that.data,_that.metadata,_that.scope,_that.cancelled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String type,  RuntimeRoute source,  Object? data,  RuntimeMetadata metadata,  PropagationScope scope,  bool cancelled)  $default,) {final _that = this;
switch (_that) {
case _RuntimeEvent():
return $default(_that.id,_that.type,_that.source,_that.data,_that.metadata,_that.scope,_that.cancelled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String type,  RuntimeRoute source,  Object? data,  RuntimeMetadata metadata,  PropagationScope scope,  bool cancelled)?  $default,) {final _that = this;
switch (_that) {
case _RuntimeEvent() when $default != null:
return $default(_that.id,_that.type,_that.source,_that.data,_that.metadata,_that.scope,_that.cancelled);case _:
  return null;

}
}

}

/// @nodoc


class _RuntimeEvent extends RuntimeEvent {
  const _RuntimeEvent({required this.id, required this.type, required this.source, this.data, required this.metadata, this.scope = PropagationScope.local, this.cancelled = false}): super._();
  

@override final  String id;
@override final  String type;
@override final  RuntimeRoute source;
@override final  Object? data;
@override final  RuntimeMetadata metadata;
@override@JsonKey() final  PropagationScope scope;
@override@JsonKey() final  bool cancelled;

/// Create a copy of RuntimeEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RuntimeEventCopyWith<_RuntimeEvent> get copyWith => __$RuntimeEventCopyWithImpl<_RuntimeEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RuntimeEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&const DeepCollectionEquality().equals(other.scope, scope)&&(identical(other.cancelled, cancelled) || other.cancelled == cancelled));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,source,const DeepCollectionEquality().hash(data),metadata,const DeepCollectionEquality().hash(scope),cancelled);

@override
String toString() {
  return 'RuntimeEvent(id: $id, type: $type, source: $source, data: $data, metadata: $metadata, scope: $scope, cancelled: $cancelled)';
}


}

/// @nodoc
abstract mixin class _$RuntimeEventCopyWith<$Res> implements $RuntimeEventCopyWith<$Res> {
  factory _$RuntimeEventCopyWith(_RuntimeEvent value, $Res Function(_RuntimeEvent) _then) = __$RuntimeEventCopyWithImpl;
@override @useResult
$Res call({
 String id, String type, RuntimeRoute source, Object? data, RuntimeMetadata metadata, PropagationScope scope, bool cancelled
});


@override $RuntimeRouteCopyWith<$Res> get source;@override $RuntimeMetadataCopyWith<$Res> get metadata;

}
/// @nodoc
class __$RuntimeEventCopyWithImpl<$Res>
    implements _$RuntimeEventCopyWith<$Res> {
  __$RuntimeEventCopyWithImpl(this._self, this._then);

  final _RuntimeEvent _self;
  final $Res Function(_RuntimeEvent) _then;

/// Create a copy of RuntimeEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? source = null,Object? data = freezed,Object? metadata = null,Object? scope = freezed,Object? cancelled = null,}) {
  return _then(_RuntimeEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as RuntimeRoute,data: freezed == data ? _self.data : data ,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as RuntimeMetadata,scope: freezed == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PropagationScope,cancelled: null == cancelled ? _self.cancelled : cancelled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of RuntimeEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RuntimeRouteCopyWith<$Res> get source {
  
  return $RuntimeRouteCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of RuntimeEvent
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
