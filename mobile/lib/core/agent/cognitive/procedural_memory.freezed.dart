// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'procedural_memory.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProceduralMemory {

 String get id; String get lesson; String get trigger; String get action; int get failureCount; DateTime get lastTriggered; double get confidence; Map<String, dynamic> get metadata;
/// Create a copy of ProceduralMemory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProceduralMemoryCopyWith<ProceduralMemory> get copyWith => _$ProceduralMemoryCopyWithImpl<ProceduralMemory>(this as ProceduralMemory, _$identity);

  /// Serializes this ProceduralMemory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProceduralMemory&&(identical(other.id, id) || other.id == id)&&(identical(other.lesson, lesson) || other.lesson == lesson)&&(identical(other.trigger, trigger) || other.trigger == trigger)&&(identical(other.action, action) || other.action == action)&&(identical(other.failureCount, failureCount) || other.failureCount == failureCount)&&(identical(other.lastTriggered, lastTriggered) || other.lastTriggered == lastTriggered)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,lesson,trigger,action,failureCount,lastTriggered,confidence,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'ProceduralMemory(id: $id, lesson: $lesson, trigger: $trigger, action: $action, failureCount: $failureCount, lastTriggered: $lastTriggered, confidence: $confidence, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $ProceduralMemoryCopyWith<$Res>  {
  factory $ProceduralMemoryCopyWith(ProceduralMemory value, $Res Function(ProceduralMemory) _then) = _$ProceduralMemoryCopyWithImpl;
@useResult
$Res call({
 String id, String lesson, String trigger, String action, int failureCount, DateTime lastTriggered, double confidence, Map<String, dynamic> metadata
});




}
/// @nodoc
class _$ProceduralMemoryCopyWithImpl<$Res>
    implements $ProceduralMemoryCopyWith<$Res> {
  _$ProceduralMemoryCopyWithImpl(this._self, this._then);

  final ProceduralMemory _self;
  final $Res Function(ProceduralMemory) _then;

/// Create a copy of ProceduralMemory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? lesson = null,Object? trigger = null,Object? action = null,Object? failureCount = null,Object? lastTriggered = null,Object? confidence = null,Object? metadata = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,lesson: null == lesson ? _self.lesson : lesson // ignore: cast_nullable_to_non_nullable
as String,trigger: null == trigger ? _self.trigger : trigger // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,failureCount: null == failureCount ? _self.failureCount : failureCount // ignore: cast_nullable_to_non_nullable
as int,lastTriggered: null == lastTriggered ? _self.lastTriggered : lastTriggered // ignore: cast_nullable_to_non_nullable
as DateTime,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProceduralMemory].
extension ProceduralMemoryPatterns on ProceduralMemory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProceduralMemory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProceduralMemory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProceduralMemory value)  $default,){
final _that = this;
switch (_that) {
case _ProceduralMemory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProceduralMemory value)?  $default,){
final _that = this;
switch (_that) {
case _ProceduralMemory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String lesson,  String trigger,  String action,  int failureCount,  DateTime lastTriggered,  double confidence,  Map<String, dynamic> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProceduralMemory() when $default != null:
return $default(_that.id,_that.lesson,_that.trigger,_that.action,_that.failureCount,_that.lastTriggered,_that.confidence,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String lesson,  String trigger,  String action,  int failureCount,  DateTime lastTriggered,  double confidence,  Map<String, dynamic> metadata)  $default,) {final _that = this;
switch (_that) {
case _ProceduralMemory():
return $default(_that.id,_that.lesson,_that.trigger,_that.action,_that.failureCount,_that.lastTriggered,_that.confidence,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String lesson,  String trigger,  String action,  int failureCount,  DateTime lastTriggered,  double confidence,  Map<String, dynamic> metadata)?  $default,) {final _that = this;
switch (_that) {
case _ProceduralMemory() when $default != null:
return $default(_that.id,_that.lesson,_that.trigger,_that.action,_that.failureCount,_that.lastTriggered,_that.confidence,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProceduralMemory extends ProceduralMemory {
  const _ProceduralMemory({required this.id, required this.lesson, required this.trigger, required this.action, this.failureCount = 1, required this.lastTriggered, this.confidence = 50, final  Map<String, dynamic> metadata = const <String, dynamic>{}}): _metadata = metadata,super._();
  factory _ProceduralMemory.fromJson(Map<String, dynamic> json) => _$ProceduralMemoryFromJson(json);

@override final  String id;
@override final  String lesson;
@override final  String trigger;
@override final  String action;
@override@JsonKey() final  int failureCount;
@override final  DateTime lastTriggered;
@override@JsonKey() final  double confidence;
 final  Map<String, dynamic> _metadata;
@override@JsonKey() Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}


/// Create a copy of ProceduralMemory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProceduralMemoryCopyWith<_ProceduralMemory> get copyWith => __$ProceduralMemoryCopyWithImpl<_ProceduralMemory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProceduralMemoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProceduralMemory&&(identical(other.id, id) || other.id == id)&&(identical(other.lesson, lesson) || other.lesson == lesson)&&(identical(other.trigger, trigger) || other.trigger == trigger)&&(identical(other.action, action) || other.action == action)&&(identical(other.failureCount, failureCount) || other.failureCount == failureCount)&&(identical(other.lastTriggered, lastTriggered) || other.lastTriggered == lastTriggered)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,lesson,trigger,action,failureCount,lastTriggered,confidence,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'ProceduralMemory(id: $id, lesson: $lesson, trigger: $trigger, action: $action, failureCount: $failureCount, lastTriggered: $lastTriggered, confidence: $confidence, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$ProceduralMemoryCopyWith<$Res> implements $ProceduralMemoryCopyWith<$Res> {
  factory _$ProceduralMemoryCopyWith(_ProceduralMemory value, $Res Function(_ProceduralMemory) _then) = __$ProceduralMemoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String lesson, String trigger, String action, int failureCount, DateTime lastTriggered, double confidence, Map<String, dynamic> metadata
});




}
/// @nodoc
class __$ProceduralMemoryCopyWithImpl<$Res>
    implements _$ProceduralMemoryCopyWith<$Res> {
  __$ProceduralMemoryCopyWithImpl(this._self, this._then);

  final _ProceduralMemory _self;
  final $Res Function(_ProceduralMemory) _then;

/// Create a copy of ProceduralMemory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? lesson = null,Object? trigger = null,Object? action = null,Object? failureCount = null,Object? lastTriggered = null,Object? confidence = null,Object? metadata = null,}) {
  return _then(_ProceduralMemory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,lesson: null == lesson ? _self.lesson : lesson // ignore: cast_nullable_to_non_nullable
as String,trigger: null == trigger ? _self.trigger : trigger // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,failureCount: null == failureCount ? _self.failureCount : failureCount // ignore: cast_nullable_to_non_nullable
as int,lastTriggered: null == lastTriggered ? _self.lastTriggered : lastTriggered // ignore: cast_nullable_to_non_nullable
as DateTime,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
