// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unified_lease.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UnifiedLease {

 String get leaseId; LeaseType get leaseType; LeaseState get state; String get ownerId; String get targetId; int get acquiredAt; int get expiresAt; int get renewalCount; int get incarnation; Map<String, dynamic> get constraints;
/// Create a copy of UnifiedLease
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnifiedLeaseCopyWith<UnifiedLease> get copyWith => _$UnifiedLeaseCopyWithImpl<UnifiedLease>(this as UnifiedLease, _$identity);

  /// Serializes this UnifiedLease to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnifiedLease&&(identical(other.leaseId, leaseId) || other.leaseId == leaseId)&&(identical(other.leaseType, leaseType) || other.leaseType == leaseType)&&(identical(other.state, state) || other.state == state)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.acquiredAt, acquiredAt) || other.acquiredAt == acquiredAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.renewalCount, renewalCount) || other.renewalCount == renewalCount)&&(identical(other.incarnation, incarnation) || other.incarnation == incarnation)&&const DeepCollectionEquality().equals(other.constraints, constraints));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,leaseId,leaseType,state,ownerId,targetId,acquiredAt,expiresAt,renewalCount,incarnation,const DeepCollectionEquality().hash(constraints));

@override
String toString() {
  return 'UnifiedLease(leaseId: $leaseId, leaseType: $leaseType, state: $state, ownerId: $ownerId, targetId: $targetId, acquiredAt: $acquiredAt, expiresAt: $expiresAt, renewalCount: $renewalCount, incarnation: $incarnation, constraints: $constraints)';
}


}

/// @nodoc
abstract mixin class $UnifiedLeaseCopyWith<$Res>  {
  factory $UnifiedLeaseCopyWith(UnifiedLease value, $Res Function(UnifiedLease) _then) = _$UnifiedLeaseCopyWithImpl;
@useResult
$Res call({
 String leaseId, LeaseType leaseType, LeaseState state, String ownerId, String targetId, int acquiredAt, int expiresAt, int renewalCount, int incarnation, Map<String, dynamic> constraints
});




}
/// @nodoc
class _$UnifiedLeaseCopyWithImpl<$Res>
    implements $UnifiedLeaseCopyWith<$Res> {
  _$UnifiedLeaseCopyWithImpl(this._self, this._then);

  final UnifiedLease _self;
  final $Res Function(UnifiedLease) _then;

/// Create a copy of UnifiedLease
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? leaseId = null,Object? leaseType = null,Object? state = null,Object? ownerId = null,Object? targetId = null,Object? acquiredAt = null,Object? expiresAt = null,Object? renewalCount = null,Object? incarnation = null,Object? constraints = null,}) {
  return _then(_self.copyWith(
leaseId: null == leaseId ? _self.leaseId : leaseId // ignore: cast_nullable_to_non_nullable
as String,leaseType: null == leaseType ? _self.leaseType : leaseType // ignore: cast_nullable_to_non_nullable
as LeaseType,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as LeaseState,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,acquiredAt: null == acquiredAt ? _self.acquiredAt : acquiredAt // ignore: cast_nullable_to_non_nullable
as int,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as int,renewalCount: null == renewalCount ? _self.renewalCount : renewalCount // ignore: cast_nullable_to_non_nullable
as int,incarnation: null == incarnation ? _self.incarnation : incarnation // ignore: cast_nullable_to_non_nullable
as int,constraints: null == constraints ? _self.constraints : constraints // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [UnifiedLease].
extension UnifiedLeasePatterns on UnifiedLease {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UnifiedLease value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UnifiedLease() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UnifiedLease value)  $default,){
final _that = this;
switch (_that) {
case _UnifiedLease():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UnifiedLease value)?  $default,){
final _that = this;
switch (_that) {
case _UnifiedLease() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String leaseId,  LeaseType leaseType,  LeaseState state,  String ownerId,  String targetId,  int acquiredAt,  int expiresAt,  int renewalCount,  int incarnation,  Map<String, dynamic> constraints)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UnifiedLease() when $default != null:
return $default(_that.leaseId,_that.leaseType,_that.state,_that.ownerId,_that.targetId,_that.acquiredAt,_that.expiresAt,_that.renewalCount,_that.incarnation,_that.constraints);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String leaseId,  LeaseType leaseType,  LeaseState state,  String ownerId,  String targetId,  int acquiredAt,  int expiresAt,  int renewalCount,  int incarnation,  Map<String, dynamic> constraints)  $default,) {final _that = this;
switch (_that) {
case _UnifiedLease():
return $default(_that.leaseId,_that.leaseType,_that.state,_that.ownerId,_that.targetId,_that.acquiredAt,_that.expiresAt,_that.renewalCount,_that.incarnation,_that.constraints);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String leaseId,  LeaseType leaseType,  LeaseState state,  String ownerId,  String targetId,  int acquiredAt,  int expiresAt,  int renewalCount,  int incarnation,  Map<String, dynamic> constraints)?  $default,) {final _that = this;
switch (_that) {
case _UnifiedLease() when $default != null:
return $default(_that.leaseId,_that.leaseType,_that.state,_that.ownerId,_that.targetId,_that.acquiredAt,_that.expiresAt,_that.renewalCount,_that.incarnation,_that.constraints);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UnifiedLease extends UnifiedLease {
  const _UnifiedLease({required this.leaseId, required this.leaseType, this.state = LeaseState.active, required this.ownerId, required this.targetId, required this.acquiredAt, required this.expiresAt, this.renewalCount = 0, this.incarnation = 0, final  Map<String, dynamic> constraints = const <String, dynamic>{}}): _constraints = constraints,super._();
  factory _UnifiedLease.fromJson(Map<String, dynamic> json) => _$UnifiedLeaseFromJson(json);

@override final  String leaseId;
@override final  LeaseType leaseType;
@override@JsonKey() final  LeaseState state;
@override final  String ownerId;
@override final  String targetId;
@override final  int acquiredAt;
@override final  int expiresAt;
@override@JsonKey() final  int renewalCount;
@override@JsonKey() final  int incarnation;
 final  Map<String, dynamic> _constraints;
@override@JsonKey() Map<String, dynamic> get constraints {
  if (_constraints is EqualUnmodifiableMapView) return _constraints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_constraints);
}


/// Create a copy of UnifiedLease
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnifiedLeaseCopyWith<_UnifiedLease> get copyWith => __$UnifiedLeaseCopyWithImpl<_UnifiedLease>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UnifiedLeaseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnifiedLease&&(identical(other.leaseId, leaseId) || other.leaseId == leaseId)&&(identical(other.leaseType, leaseType) || other.leaseType == leaseType)&&(identical(other.state, state) || other.state == state)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.acquiredAt, acquiredAt) || other.acquiredAt == acquiredAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.renewalCount, renewalCount) || other.renewalCount == renewalCount)&&(identical(other.incarnation, incarnation) || other.incarnation == incarnation)&&const DeepCollectionEquality().equals(other._constraints, _constraints));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,leaseId,leaseType,state,ownerId,targetId,acquiredAt,expiresAt,renewalCount,incarnation,const DeepCollectionEquality().hash(_constraints));

@override
String toString() {
  return 'UnifiedLease(leaseId: $leaseId, leaseType: $leaseType, state: $state, ownerId: $ownerId, targetId: $targetId, acquiredAt: $acquiredAt, expiresAt: $expiresAt, renewalCount: $renewalCount, incarnation: $incarnation, constraints: $constraints)';
}


}

/// @nodoc
abstract mixin class _$UnifiedLeaseCopyWith<$Res> implements $UnifiedLeaseCopyWith<$Res> {
  factory _$UnifiedLeaseCopyWith(_UnifiedLease value, $Res Function(_UnifiedLease) _then) = __$UnifiedLeaseCopyWithImpl;
@override @useResult
$Res call({
 String leaseId, LeaseType leaseType, LeaseState state, String ownerId, String targetId, int acquiredAt, int expiresAt, int renewalCount, int incarnation, Map<String, dynamic> constraints
});




}
/// @nodoc
class __$UnifiedLeaseCopyWithImpl<$Res>
    implements _$UnifiedLeaseCopyWith<$Res> {
  __$UnifiedLeaseCopyWithImpl(this._self, this._then);

  final _UnifiedLease _self;
  final $Res Function(_UnifiedLease) _then;

/// Create a copy of UnifiedLease
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? leaseId = null,Object? leaseType = null,Object? state = null,Object? ownerId = null,Object? targetId = null,Object? acquiredAt = null,Object? expiresAt = null,Object? renewalCount = null,Object? incarnation = null,Object? constraints = null,}) {
  return _then(_UnifiedLease(
leaseId: null == leaseId ? _self.leaseId : leaseId // ignore: cast_nullable_to_non_nullable
as String,leaseType: null == leaseType ? _self.leaseType : leaseType // ignore: cast_nullable_to_non_nullable
as LeaseType,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as LeaseState,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,acquiredAt: null == acquiredAt ? _self.acquiredAt : acquiredAt // ignore: cast_nullable_to_non_nullable
as int,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as int,renewalCount: null == renewalCount ? _self.renewalCount : renewalCount // ignore: cast_nullable_to_non_nullable
as int,incarnation: null == incarnation ? _self.incarnation : incarnation // ignore: cast_nullable_to_non_nullable
as int,constraints: null == constraints ? _self._constraints : constraints // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
