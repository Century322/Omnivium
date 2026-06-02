// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'call_entities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CallState {

 String get callId; String get roomId; String get remoteUserId; String get remoteUserName; String? get remoteAvatarUrl; CallStatus get status; bool get isVideo; DateTime? get startedAt;@DurationMillisConverter() Duration? get duration;
/// Create a copy of CallState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallStateCopyWith<CallState> get copyWith => _$CallStateCopyWithImpl<CallState>(this as CallState, _$identity);

  /// Serializes this CallState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallState&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.remoteUserId, remoteUserId) || other.remoteUserId == remoteUserId)&&(identical(other.remoteUserName, remoteUserName) || other.remoteUserName == remoteUserName)&&(identical(other.remoteAvatarUrl, remoteAvatarUrl) || other.remoteAvatarUrl == remoteAvatarUrl)&&(identical(other.status, status) || other.status == status)&&(identical(other.isVideo, isVideo) || other.isVideo == isVideo)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.duration, duration) || other.duration == duration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,callId,roomId,remoteUserId,remoteUserName,remoteAvatarUrl,status,isVideo,startedAt,duration);

@override
String toString() {
  return 'CallState(callId: $callId, roomId: $roomId, remoteUserId: $remoteUserId, remoteUserName: $remoteUserName, remoteAvatarUrl: $remoteAvatarUrl, status: $status, isVideo: $isVideo, startedAt: $startedAt, duration: $duration)';
}


}

/// @nodoc
abstract mixin class $CallStateCopyWith<$Res>  {
  factory $CallStateCopyWith(CallState value, $Res Function(CallState) _then) = _$CallStateCopyWithImpl;
@useResult
$Res call({
 String callId, String roomId, String remoteUserId, String remoteUserName, String? remoteAvatarUrl, CallStatus status, bool isVideo, DateTime? startedAt,@DurationMillisConverter() Duration? duration
});




}
/// @nodoc
class _$CallStateCopyWithImpl<$Res>
    implements $CallStateCopyWith<$Res> {
  _$CallStateCopyWithImpl(this._self, this._then);

  final CallState _self;
  final $Res Function(CallState) _then;

/// Create a copy of CallState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? callId = null,Object? roomId = null,Object? remoteUserId = null,Object? remoteUserName = null,Object? remoteAvatarUrl = freezed,Object? status = null,Object? isVideo = null,Object? startedAt = freezed,Object? duration = freezed,}) {
  return _then(_self.copyWith(
callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,remoteUserId: null == remoteUserId ? _self.remoteUserId : remoteUserId // ignore: cast_nullable_to_non_nullable
as String,remoteUserName: null == remoteUserName ? _self.remoteUserName : remoteUserName // ignore: cast_nullable_to_non_nullable
as String,remoteAvatarUrl: freezed == remoteAvatarUrl ? _self.remoteAvatarUrl : remoteAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CallStatus,isVideo: null == isVideo ? _self.isVideo : isVideo // ignore: cast_nullable_to_non_nullable
as bool,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}

}


/// Adds pattern-matching-related methods to [CallState].
extension CallStatePatterns on CallState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CallState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CallState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CallState value)  $default,){
final _that = this;
switch (_that) {
case _CallState():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CallState value)?  $default,){
final _that = this;
switch (_that) {
case _CallState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String callId,  String roomId,  String remoteUserId,  String remoteUserName,  String? remoteAvatarUrl,  CallStatus status,  bool isVideo,  DateTime? startedAt, @DurationMillisConverter()  Duration? duration)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CallState() when $default != null:
return $default(_that.callId,_that.roomId,_that.remoteUserId,_that.remoteUserName,_that.remoteAvatarUrl,_that.status,_that.isVideo,_that.startedAt,_that.duration);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String callId,  String roomId,  String remoteUserId,  String remoteUserName,  String? remoteAvatarUrl,  CallStatus status,  bool isVideo,  DateTime? startedAt, @DurationMillisConverter()  Duration? duration)  $default,) {final _that = this;
switch (_that) {
case _CallState():
return $default(_that.callId,_that.roomId,_that.remoteUserId,_that.remoteUserName,_that.remoteAvatarUrl,_that.status,_that.isVideo,_that.startedAt,_that.duration);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String callId,  String roomId,  String remoteUserId,  String remoteUserName,  String? remoteAvatarUrl,  CallStatus status,  bool isVideo,  DateTime? startedAt, @DurationMillisConverter()  Duration? duration)?  $default,) {final _that = this;
switch (_that) {
case _CallState() when $default != null:
return $default(_that.callId,_that.roomId,_that.remoteUserId,_that.remoteUserName,_that.remoteAvatarUrl,_that.status,_that.isVideo,_that.startedAt,_that.duration);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CallState implements CallState {
  const _CallState({required this.callId, required this.roomId, required this.remoteUserId, required this.remoteUserName, this.remoteAvatarUrl, this.status = CallStatus.idle, this.isVideo = false, this.startedAt, @DurationMillisConverter() this.duration});
  factory _CallState.fromJson(Map<String, dynamic> json) => _$CallStateFromJson(json);

@override final  String callId;
@override final  String roomId;
@override final  String remoteUserId;
@override final  String remoteUserName;
@override final  String? remoteAvatarUrl;
@override@JsonKey() final  CallStatus status;
@override@JsonKey() final  bool isVideo;
@override final  DateTime? startedAt;
@override@DurationMillisConverter() final  Duration? duration;

/// Create a copy of CallState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CallStateCopyWith<_CallState> get copyWith => __$CallStateCopyWithImpl<_CallState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CallStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CallState&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.remoteUserId, remoteUserId) || other.remoteUserId == remoteUserId)&&(identical(other.remoteUserName, remoteUserName) || other.remoteUserName == remoteUserName)&&(identical(other.remoteAvatarUrl, remoteAvatarUrl) || other.remoteAvatarUrl == remoteAvatarUrl)&&(identical(other.status, status) || other.status == status)&&(identical(other.isVideo, isVideo) || other.isVideo == isVideo)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.duration, duration) || other.duration == duration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,callId,roomId,remoteUserId,remoteUserName,remoteAvatarUrl,status,isVideo,startedAt,duration);

@override
String toString() {
  return 'CallState(callId: $callId, roomId: $roomId, remoteUserId: $remoteUserId, remoteUserName: $remoteUserName, remoteAvatarUrl: $remoteAvatarUrl, status: $status, isVideo: $isVideo, startedAt: $startedAt, duration: $duration)';
}


}

/// @nodoc
abstract mixin class _$CallStateCopyWith<$Res> implements $CallStateCopyWith<$Res> {
  factory _$CallStateCopyWith(_CallState value, $Res Function(_CallState) _then) = __$CallStateCopyWithImpl;
@override @useResult
$Res call({
 String callId, String roomId, String remoteUserId, String remoteUserName, String? remoteAvatarUrl, CallStatus status, bool isVideo, DateTime? startedAt,@DurationMillisConverter() Duration? duration
});




}
/// @nodoc
class __$CallStateCopyWithImpl<$Res>
    implements _$CallStateCopyWith<$Res> {
  __$CallStateCopyWithImpl(this._self, this._then);

  final _CallState _self;
  final $Res Function(_CallState) _then;

/// Create a copy of CallState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? callId = null,Object? roomId = null,Object? remoteUserId = null,Object? remoteUserName = null,Object? remoteAvatarUrl = freezed,Object? status = null,Object? isVideo = null,Object? startedAt = freezed,Object? duration = freezed,}) {
  return _then(_CallState(
callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,remoteUserId: null == remoteUserId ? _self.remoteUserId : remoteUserId // ignore: cast_nullable_to_non_nullable
as String,remoteUserName: null == remoteUserName ? _self.remoteUserName : remoteUserName // ignore: cast_nullable_to_non_nullable
as String,remoteAvatarUrl: freezed == remoteAvatarUrl ? _self.remoteAvatarUrl : remoteAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CallStatus,isVideo: null == isVideo ? _self.isVideo : isVideo // ignore: cast_nullable_to_non_nullable
as bool,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}


}

// dart format on
