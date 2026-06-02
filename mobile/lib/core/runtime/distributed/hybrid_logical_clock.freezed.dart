// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hybrid_logical_clock.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HybridTimestamp {

@JsonKey(name: 'pt') int get physicalTime;@JsonKey(name: 'lt') int get logicalTime;@JsonKey(name: 'node') String get nodeId;
/// Create a copy of HybridTimestamp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HybridTimestampCopyWith<HybridTimestamp> get copyWith => _$HybridTimestampCopyWithImpl<HybridTimestamp>(this as HybridTimestamp, _$identity);

  /// Serializes this HybridTimestamp to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HybridTimestamp&&(identical(other.physicalTime, physicalTime) || other.physicalTime == physicalTime)&&(identical(other.logicalTime, logicalTime) || other.logicalTime == logicalTime)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,physicalTime,logicalTime,nodeId);

@override
String toString() {
  return 'HybridTimestamp(physicalTime: $physicalTime, logicalTime: $logicalTime, nodeId: $nodeId)';
}


}

/// @nodoc
abstract mixin class $HybridTimestampCopyWith<$Res>  {
  factory $HybridTimestampCopyWith(HybridTimestamp value, $Res Function(HybridTimestamp) _then) = _$HybridTimestampCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'pt') int physicalTime,@JsonKey(name: 'lt') int logicalTime,@JsonKey(name: 'node') String nodeId
});




}
/// @nodoc
class _$HybridTimestampCopyWithImpl<$Res>
    implements $HybridTimestampCopyWith<$Res> {
  _$HybridTimestampCopyWithImpl(this._self, this._then);

  final HybridTimestamp _self;
  final $Res Function(HybridTimestamp) _then;

/// Create a copy of HybridTimestamp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? physicalTime = null,Object? logicalTime = null,Object? nodeId = null,}) {
  return _then(_self.copyWith(
physicalTime: null == physicalTime ? _self.physicalTime : physicalTime // ignore: cast_nullable_to_non_nullable
as int,logicalTime: null == logicalTime ? _self.logicalTime : logicalTime // ignore: cast_nullable_to_non_nullable
as int,nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [HybridTimestamp].
extension HybridTimestampPatterns on HybridTimestamp {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HybridTimestamp value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HybridTimestamp() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HybridTimestamp value)  $default,){
final _that = this;
switch (_that) {
case _HybridTimestamp():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HybridTimestamp value)?  $default,){
final _that = this;
switch (_that) {
case _HybridTimestamp() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'pt')  int physicalTime, @JsonKey(name: 'lt')  int logicalTime, @JsonKey(name: 'node')  String nodeId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HybridTimestamp() when $default != null:
return $default(_that.physicalTime,_that.logicalTime,_that.nodeId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'pt')  int physicalTime, @JsonKey(name: 'lt')  int logicalTime, @JsonKey(name: 'node')  String nodeId)  $default,) {final _that = this;
switch (_that) {
case _HybridTimestamp():
return $default(_that.physicalTime,_that.logicalTime,_that.nodeId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'pt')  int physicalTime, @JsonKey(name: 'lt')  int logicalTime, @JsonKey(name: 'node')  String nodeId)?  $default,) {final _that = this;
switch (_that) {
case _HybridTimestamp() when $default != null:
return $default(_that.physicalTime,_that.logicalTime,_that.nodeId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HybridTimestamp extends HybridTimestamp {
  const _HybridTimestamp({@JsonKey(name: 'pt') required this.physicalTime, @JsonKey(name: 'lt') this.logicalTime = 0, @JsonKey(name: 'node') this.nodeId = 'local'}): super._();
  factory _HybridTimestamp.fromJson(Map<String, dynamic> json) => _$HybridTimestampFromJson(json);

@override@JsonKey(name: 'pt') final  int physicalTime;
@override@JsonKey(name: 'lt') final  int logicalTime;
@override@JsonKey(name: 'node') final  String nodeId;

/// Create a copy of HybridTimestamp
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HybridTimestampCopyWith<_HybridTimestamp> get copyWith => __$HybridTimestampCopyWithImpl<_HybridTimestamp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HybridTimestampToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HybridTimestamp&&(identical(other.physicalTime, physicalTime) || other.physicalTime == physicalTime)&&(identical(other.logicalTime, logicalTime) || other.logicalTime == logicalTime)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,physicalTime,logicalTime,nodeId);

@override
String toString() {
  return 'HybridTimestamp(physicalTime: $physicalTime, logicalTime: $logicalTime, nodeId: $nodeId)';
}


}

/// @nodoc
abstract mixin class _$HybridTimestampCopyWith<$Res> implements $HybridTimestampCopyWith<$Res> {
  factory _$HybridTimestampCopyWith(_HybridTimestamp value, $Res Function(_HybridTimestamp) _then) = __$HybridTimestampCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'pt') int physicalTime,@JsonKey(name: 'lt') int logicalTime,@JsonKey(name: 'node') String nodeId
});




}
/// @nodoc
class __$HybridTimestampCopyWithImpl<$Res>
    implements _$HybridTimestampCopyWith<$Res> {
  __$HybridTimestampCopyWithImpl(this._self, this._then);

  final _HybridTimestamp _self;
  final $Res Function(_HybridTimestamp) _then;

/// Create a copy of HybridTimestamp
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? physicalTime = null,Object? logicalTime = null,Object? nodeId = null,}) {
  return _then(_HybridTimestamp(
physicalTime: null == physicalTime ? _self.physicalTime : physicalTime // ignore: cast_nullable_to_non_nullable
as int,logicalTime: null == logicalTime ? _self.logicalTime : logicalTime // ignore: cast_nullable_to_non_nullable
as int,nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
