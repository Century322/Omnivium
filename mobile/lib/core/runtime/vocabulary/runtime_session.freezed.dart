// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'runtime_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RuntimeSession {

 String get id; String get userId; int get createdAt; int get lastActiveAt; SessionState get state; Map<String, dynamic> get metadata;
/// Create a copy of RuntimeSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RuntimeSessionCopyWith<RuntimeSession> get copyWith => _$RuntimeSessionCopyWithImpl<RuntimeSession>(this as RuntimeSession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RuntimeSession&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt)&&(identical(other.state, state) || other.state == state)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,createdAt,lastActiveAt,state,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'RuntimeSession(id: $id, userId: $userId, createdAt: $createdAt, lastActiveAt: $lastActiveAt, state: $state, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $RuntimeSessionCopyWith<$Res>  {
  factory $RuntimeSessionCopyWith(RuntimeSession value, $Res Function(RuntimeSession) _then) = _$RuntimeSessionCopyWithImpl;
@useResult
$Res call({
 String id, String userId, int createdAt, int lastActiveAt, SessionState state, Map<String, dynamic> metadata
});




}
/// @nodoc
class _$RuntimeSessionCopyWithImpl<$Res>
    implements $RuntimeSessionCopyWith<$Res> {
  _$RuntimeSessionCopyWithImpl(this._self, this._then);

  final RuntimeSession _self;
  final $Res Function(RuntimeSession) _then;

/// Create a copy of RuntimeSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? createdAt = null,Object? lastActiveAt = null,Object? state = null,Object? metadata = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,lastActiveAt: null == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as int,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as SessionState,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [RuntimeSession].
extension RuntimeSessionPatterns on RuntimeSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RuntimeSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RuntimeSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RuntimeSession value)  $default,){
final _that = this;
switch (_that) {
case _RuntimeSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RuntimeSession value)?  $default,){
final _that = this;
switch (_that) {
case _RuntimeSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  int createdAt,  int lastActiveAt,  SessionState state,  Map<String, dynamic> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RuntimeSession() when $default != null:
return $default(_that.id,_that.userId,_that.createdAt,_that.lastActiveAt,_that.state,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  int createdAt,  int lastActiveAt,  SessionState state,  Map<String, dynamic> metadata)  $default,) {final _that = this;
switch (_that) {
case _RuntimeSession():
return $default(_that.id,_that.userId,_that.createdAt,_that.lastActiveAt,_that.state,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  int createdAt,  int lastActiveAt,  SessionState state,  Map<String, dynamic> metadata)?  $default,) {final _that = this;
switch (_that) {
case _RuntimeSession() when $default != null:
return $default(_that.id,_that.userId,_that.createdAt,_that.lastActiveAt,_that.state,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc


class _RuntimeSession extends RuntimeSession {
  const _RuntimeSession({required this.id, required this.userId, required this.createdAt, required this.lastActiveAt, this.state = SessionState.active, final  Map<String, dynamic> metadata = const <String, dynamic>{}}): _metadata = metadata,super._();
  

@override final  String id;
@override final  String userId;
@override final  int createdAt;
@override final  int lastActiveAt;
@override@JsonKey() final  SessionState state;
 final  Map<String, dynamic> _metadata;
@override@JsonKey() Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}


/// Create a copy of RuntimeSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RuntimeSessionCopyWith<_RuntimeSession> get copyWith => __$RuntimeSessionCopyWithImpl<_RuntimeSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RuntimeSession&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt)&&(identical(other.state, state) || other.state == state)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,createdAt,lastActiveAt,state,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'RuntimeSession(id: $id, userId: $userId, createdAt: $createdAt, lastActiveAt: $lastActiveAt, state: $state, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$RuntimeSessionCopyWith<$Res> implements $RuntimeSessionCopyWith<$Res> {
  factory _$RuntimeSessionCopyWith(_RuntimeSession value, $Res Function(_RuntimeSession) _then) = __$RuntimeSessionCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, int createdAt, int lastActiveAt, SessionState state, Map<String, dynamic> metadata
});




}
/// @nodoc
class __$RuntimeSessionCopyWithImpl<$Res>
    implements _$RuntimeSessionCopyWith<$Res> {
  __$RuntimeSessionCopyWithImpl(this._self, this._then);

  final _RuntimeSession _self;
  final $Res Function(_RuntimeSession) _then;

/// Create a copy of RuntimeSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? createdAt = null,Object? lastActiveAt = null,Object? state = null,Object? metadata = null,}) {
  return _then(_RuntimeSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,lastActiveAt: null == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as int,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as SessionState,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
