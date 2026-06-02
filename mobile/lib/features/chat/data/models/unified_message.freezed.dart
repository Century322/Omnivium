// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unified_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UnifiedMessage {

 String get id; String get senderId; String get content; MessageType get type; MessageFormat get format; DateTime get timestamp; String? get replyToId; String? get sourceContext; Map<String, dynamic> get metadata;
/// Create a copy of UnifiedMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnifiedMessageCopyWith<UnifiedMessage> get copyWith => _$UnifiedMessageCopyWithImpl<UnifiedMessage>(this as UnifiedMessage, _$identity);

  /// Serializes this UnifiedMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnifiedMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.content, content) || other.content == content)&&(identical(other.type, type) || other.type == type)&&(identical(other.format, format) || other.format == format)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.replyToId, replyToId) || other.replyToId == replyToId)&&(identical(other.sourceContext, sourceContext) || other.sourceContext == sourceContext)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,senderId,content,type,format,timestamp,replyToId,sourceContext,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'UnifiedMessage(id: $id, senderId: $senderId, content: $content, type: $type, format: $format, timestamp: $timestamp, replyToId: $replyToId, sourceContext: $sourceContext, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $UnifiedMessageCopyWith<$Res>  {
  factory $UnifiedMessageCopyWith(UnifiedMessage value, $Res Function(UnifiedMessage) _then) = _$UnifiedMessageCopyWithImpl;
@useResult
$Res call({
 String id, String senderId, String content, MessageType type, MessageFormat format, DateTime timestamp, String? replyToId, String? sourceContext, Map<String, dynamic> metadata
});




}
/// @nodoc
class _$UnifiedMessageCopyWithImpl<$Res>
    implements $UnifiedMessageCopyWith<$Res> {
  _$UnifiedMessageCopyWithImpl(this._self, this._then);

  final UnifiedMessage _self;
  final $Res Function(UnifiedMessage) _then;

/// Create a copy of UnifiedMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? senderId = null,Object? content = null,Object? type = null,Object? format = null,Object? timestamp = null,Object? replyToId = freezed,Object? sourceContext = freezed,Object? metadata = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MessageType,format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as MessageFormat,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,replyToId: freezed == replyToId ? _self.replyToId : replyToId // ignore: cast_nullable_to_non_nullable
as String?,sourceContext: freezed == sourceContext ? _self.sourceContext : sourceContext // ignore: cast_nullable_to_non_nullable
as String?,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [UnifiedMessage].
extension UnifiedMessagePatterns on UnifiedMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UnifiedMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UnifiedMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UnifiedMessage value)  $default,){
final _that = this;
switch (_that) {
case _UnifiedMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UnifiedMessage value)?  $default,){
final _that = this;
switch (_that) {
case _UnifiedMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String senderId,  String content,  MessageType type,  MessageFormat format,  DateTime timestamp,  String? replyToId,  String? sourceContext,  Map<String, dynamic> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UnifiedMessage() when $default != null:
return $default(_that.id,_that.senderId,_that.content,_that.type,_that.format,_that.timestamp,_that.replyToId,_that.sourceContext,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String senderId,  String content,  MessageType type,  MessageFormat format,  DateTime timestamp,  String? replyToId,  String? sourceContext,  Map<String, dynamic> metadata)  $default,) {final _that = this;
switch (_that) {
case _UnifiedMessage():
return $default(_that.id,_that.senderId,_that.content,_that.type,_that.format,_that.timestamp,_that.replyToId,_that.sourceContext,_that.metadata);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String senderId,  String content,  MessageType type,  MessageFormat format,  DateTime timestamp,  String? replyToId,  String? sourceContext,  Map<String, dynamic> metadata)?  $default,) {final _that = this;
switch (_that) {
case _UnifiedMessage() when $default != null:
return $default(_that.id,_that.senderId,_that.content,_that.type,_that.format,_that.timestamp,_that.replyToId,_that.sourceContext,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UnifiedMessage extends UnifiedMessage {
  const _UnifiedMessage({required this.id, required this.senderId, required this.content, required this.type, required this.format, required this.timestamp, this.replyToId, this.sourceContext, final  Map<String, dynamic> metadata = const {}}): _metadata = metadata,super._();
  factory _UnifiedMessage.fromJson(Map<String, dynamic> json) => _$UnifiedMessageFromJson(json);

@override final  String id;
@override final  String senderId;
@override final  String content;
@override final  MessageType type;
@override final  MessageFormat format;
@override final  DateTime timestamp;
@override final  String? replyToId;
@override final  String? sourceContext;
 final  Map<String, dynamic> _metadata;
@override@JsonKey() Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}


/// Create a copy of UnifiedMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnifiedMessageCopyWith<_UnifiedMessage> get copyWith => __$UnifiedMessageCopyWithImpl<_UnifiedMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UnifiedMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnifiedMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.content, content) || other.content == content)&&(identical(other.type, type) || other.type == type)&&(identical(other.format, format) || other.format == format)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.replyToId, replyToId) || other.replyToId == replyToId)&&(identical(other.sourceContext, sourceContext) || other.sourceContext == sourceContext)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,senderId,content,type,format,timestamp,replyToId,sourceContext,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'UnifiedMessage(id: $id, senderId: $senderId, content: $content, type: $type, format: $format, timestamp: $timestamp, replyToId: $replyToId, sourceContext: $sourceContext, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$UnifiedMessageCopyWith<$Res> implements $UnifiedMessageCopyWith<$Res> {
  factory _$UnifiedMessageCopyWith(_UnifiedMessage value, $Res Function(_UnifiedMessage) _then) = __$UnifiedMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String senderId, String content, MessageType type, MessageFormat format, DateTime timestamp, String? replyToId, String? sourceContext, Map<String, dynamic> metadata
});




}
/// @nodoc
class __$UnifiedMessageCopyWithImpl<$Res>
    implements _$UnifiedMessageCopyWith<$Res> {
  __$UnifiedMessageCopyWithImpl(this._self, this._then);

  final _UnifiedMessage _self;
  final $Res Function(_UnifiedMessage) _then;

/// Create a copy of UnifiedMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? senderId = null,Object? content = null,Object? type = null,Object? format = null,Object? timestamp = null,Object? replyToId = freezed,Object? sourceContext = freezed,Object? metadata = null,}) {
  return _then(_UnifiedMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MessageType,format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as MessageFormat,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,replyToId: freezed == replyToId ? _self.replyToId : replyToId // ignore: cast_nullable_to_non_nullable
as String?,sourceContext: freezed == sourceContext ? _self.sourceContext : sourceContext // ignore: cast_nullable_to_non_nullable
as String?,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
