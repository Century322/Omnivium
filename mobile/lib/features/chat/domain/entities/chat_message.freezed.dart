// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatMessage {

 String get id; String get roomId; String get senderId; String get senderName; String? get senderAvatarUrl; String get content; MessageType get type; DateTime get timestamp; String? get replyToId; String? get replyToContent; String? get replyToSender; bool get isEdited; bool get isRecalled; String? get mediaUrl; String? get mediaFileName; int? get mediaFileSize; int? get mediaDuration; Map<String, dynamic>? get metadata;
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<ChatMessage> get copyWith => _$ChatMessageCopyWithImpl<ChatMessage>(this as ChatMessage, _$identity);

  /// Serializes this ChatMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.senderName, senderName) || other.senderName == senderName)&&(identical(other.senderAvatarUrl, senderAvatarUrl) || other.senderAvatarUrl == senderAvatarUrl)&&(identical(other.content, content) || other.content == content)&&(identical(other.type, type) || other.type == type)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.replyToId, replyToId) || other.replyToId == replyToId)&&(identical(other.replyToContent, replyToContent) || other.replyToContent == replyToContent)&&(identical(other.replyToSender, replyToSender) || other.replyToSender == replyToSender)&&(identical(other.isEdited, isEdited) || other.isEdited == isEdited)&&(identical(other.isRecalled, isRecalled) || other.isRecalled == isRecalled)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl)&&(identical(other.mediaFileName, mediaFileName) || other.mediaFileName == mediaFileName)&&(identical(other.mediaFileSize, mediaFileSize) || other.mediaFileSize == mediaFileSize)&&(identical(other.mediaDuration, mediaDuration) || other.mediaDuration == mediaDuration)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,roomId,senderId,senderName,senderAvatarUrl,content,type,timestamp,replyToId,replyToContent,replyToSender,isEdited,isRecalled,mediaUrl,mediaFileName,mediaFileSize,mediaDuration,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'ChatMessage(id: $id, roomId: $roomId, senderId: $senderId, senderName: $senderName, senderAvatarUrl: $senderAvatarUrl, content: $content, type: $type, timestamp: $timestamp, replyToId: $replyToId, replyToContent: $replyToContent, replyToSender: $replyToSender, isEdited: $isEdited, isRecalled: $isRecalled, mediaUrl: $mediaUrl, mediaFileName: $mediaFileName, mediaFileSize: $mediaFileSize, mediaDuration: $mediaDuration, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $ChatMessageCopyWith<$Res>  {
  factory $ChatMessageCopyWith(ChatMessage value, $Res Function(ChatMessage) _then) = _$ChatMessageCopyWithImpl;
@useResult
$Res call({
 String id, String roomId, String senderId, String senderName, String? senderAvatarUrl, String content, MessageType type, DateTime timestamp, String? replyToId, String? replyToContent, String? replyToSender, bool isEdited, bool isRecalled, String? mediaUrl, String? mediaFileName, int? mediaFileSize, int? mediaDuration, Map<String, dynamic>? metadata
});




}
/// @nodoc
class _$ChatMessageCopyWithImpl<$Res>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._self, this._then);

  final ChatMessage _self;
  final $Res Function(ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? roomId = null,Object? senderId = null,Object? senderName = null,Object? senderAvatarUrl = freezed,Object? content = null,Object? type = null,Object? timestamp = null,Object? replyToId = freezed,Object? replyToContent = freezed,Object? replyToSender = freezed,Object? isEdited = null,Object? isRecalled = null,Object? mediaUrl = freezed,Object? mediaFileName = freezed,Object? mediaFileSize = freezed,Object? mediaDuration = freezed,Object? metadata = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,senderName: null == senderName ? _self.senderName : senderName // ignore: cast_nullable_to_non_nullable
as String,senderAvatarUrl: freezed == senderAvatarUrl ? _self.senderAvatarUrl : senderAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MessageType,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,replyToId: freezed == replyToId ? _self.replyToId : replyToId // ignore: cast_nullable_to_non_nullable
as String?,replyToContent: freezed == replyToContent ? _self.replyToContent : replyToContent // ignore: cast_nullable_to_non_nullable
as String?,replyToSender: freezed == replyToSender ? _self.replyToSender : replyToSender // ignore: cast_nullable_to_non_nullable
as String?,isEdited: null == isEdited ? _self.isEdited : isEdited // ignore: cast_nullable_to_non_nullable
as bool,isRecalled: null == isRecalled ? _self.isRecalled : isRecalled // ignore: cast_nullable_to_non_nullable
as bool,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,mediaFileName: freezed == mediaFileName ? _self.mediaFileName : mediaFileName // ignore: cast_nullable_to_non_nullable
as String?,mediaFileSize: freezed == mediaFileSize ? _self.mediaFileSize : mediaFileSize // ignore: cast_nullable_to_non_nullable
as int?,mediaDuration: freezed == mediaDuration ? _self.mediaDuration : mediaDuration // ignore: cast_nullable_to_non_nullable
as int?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatMessage].
extension ChatMessagePatterns on ChatMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessage value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessage value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String roomId,  String senderId,  String senderName,  String? senderAvatarUrl,  String content,  MessageType type,  DateTime timestamp,  String? replyToId,  String? replyToContent,  String? replyToSender,  bool isEdited,  bool isRecalled,  String? mediaUrl,  String? mediaFileName,  int? mediaFileSize,  int? mediaDuration,  Map<String, dynamic>? metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.roomId,_that.senderId,_that.senderName,_that.senderAvatarUrl,_that.content,_that.type,_that.timestamp,_that.replyToId,_that.replyToContent,_that.replyToSender,_that.isEdited,_that.isRecalled,_that.mediaUrl,_that.mediaFileName,_that.mediaFileSize,_that.mediaDuration,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String roomId,  String senderId,  String senderName,  String? senderAvatarUrl,  String content,  MessageType type,  DateTime timestamp,  String? replyToId,  String? replyToContent,  String? replyToSender,  bool isEdited,  bool isRecalled,  String? mediaUrl,  String? mediaFileName,  int? mediaFileSize,  int? mediaDuration,  Map<String, dynamic>? metadata)  $default,) {final _that = this;
switch (_that) {
case _ChatMessage():
return $default(_that.id,_that.roomId,_that.senderId,_that.senderName,_that.senderAvatarUrl,_that.content,_that.type,_that.timestamp,_that.replyToId,_that.replyToContent,_that.replyToSender,_that.isEdited,_that.isRecalled,_that.mediaUrl,_that.mediaFileName,_that.mediaFileSize,_that.mediaDuration,_that.metadata);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String roomId,  String senderId,  String senderName,  String? senderAvatarUrl,  String content,  MessageType type,  DateTime timestamp,  String? replyToId,  String? replyToContent,  String? replyToSender,  bool isEdited,  bool isRecalled,  String? mediaUrl,  String? mediaFileName,  int? mediaFileSize,  int? mediaDuration,  Map<String, dynamic>? metadata)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.roomId,_that.senderId,_that.senderName,_that.senderAvatarUrl,_that.content,_that.type,_that.timestamp,_that.replyToId,_that.replyToContent,_that.replyToSender,_that.isEdited,_that.isRecalled,_that.mediaUrl,_that.mediaFileName,_that.mediaFileSize,_that.mediaDuration,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatMessage extends ChatMessage {
  const _ChatMessage({required this.id, required this.roomId, required this.senderId, required this.senderName, this.senderAvatarUrl, required this.content, this.type = MessageType.text, required this.timestamp, this.replyToId, this.replyToContent, this.replyToSender, this.isEdited = false, this.isRecalled = false, this.mediaUrl, this.mediaFileName, this.mediaFileSize, this.mediaDuration, final  Map<String, dynamic>? metadata}): _metadata = metadata,super._();
  factory _ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);

@override final  String id;
@override final  String roomId;
@override final  String senderId;
@override final  String senderName;
@override final  String? senderAvatarUrl;
@override final  String content;
@override@JsonKey() final  MessageType type;
@override final  DateTime timestamp;
@override final  String? replyToId;
@override final  String? replyToContent;
@override final  String? replyToSender;
@override@JsonKey() final  bool isEdited;
@override@JsonKey() final  bool isRecalled;
@override final  String? mediaUrl;
@override final  String? mediaFileName;
@override final  int? mediaFileSize;
@override final  int? mediaDuration;
 final  Map<String, dynamic>? _metadata;
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageCopyWith<_ChatMessage> get copyWith => __$ChatMessageCopyWithImpl<_ChatMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.senderName, senderName) || other.senderName == senderName)&&(identical(other.senderAvatarUrl, senderAvatarUrl) || other.senderAvatarUrl == senderAvatarUrl)&&(identical(other.content, content) || other.content == content)&&(identical(other.type, type) || other.type == type)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.replyToId, replyToId) || other.replyToId == replyToId)&&(identical(other.replyToContent, replyToContent) || other.replyToContent == replyToContent)&&(identical(other.replyToSender, replyToSender) || other.replyToSender == replyToSender)&&(identical(other.isEdited, isEdited) || other.isEdited == isEdited)&&(identical(other.isRecalled, isRecalled) || other.isRecalled == isRecalled)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl)&&(identical(other.mediaFileName, mediaFileName) || other.mediaFileName == mediaFileName)&&(identical(other.mediaFileSize, mediaFileSize) || other.mediaFileSize == mediaFileSize)&&(identical(other.mediaDuration, mediaDuration) || other.mediaDuration == mediaDuration)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,roomId,senderId,senderName,senderAvatarUrl,content,type,timestamp,replyToId,replyToContent,replyToSender,isEdited,isRecalled,mediaUrl,mediaFileName,mediaFileSize,mediaDuration,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'ChatMessage(id: $id, roomId: $roomId, senderId: $senderId, senderName: $senderName, senderAvatarUrl: $senderAvatarUrl, content: $content, type: $type, timestamp: $timestamp, replyToId: $replyToId, replyToContent: $replyToContent, replyToSender: $replyToSender, isEdited: $isEdited, isRecalled: $isRecalled, mediaUrl: $mediaUrl, mediaFileName: $mediaFileName, mediaFileSize: $mediaFileSize, mediaDuration: $mediaDuration, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory _$ChatMessageCopyWith(_ChatMessage value, $Res Function(_ChatMessage) _then) = __$ChatMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String roomId, String senderId, String senderName, String? senderAvatarUrl, String content, MessageType type, DateTime timestamp, String? replyToId, String? replyToContent, String? replyToSender, bool isEdited, bool isRecalled, String? mediaUrl, String? mediaFileName, int? mediaFileSize, int? mediaDuration, Map<String, dynamic>? metadata
});




}
/// @nodoc
class __$ChatMessageCopyWithImpl<$Res>
    implements _$ChatMessageCopyWith<$Res> {
  __$ChatMessageCopyWithImpl(this._self, this._then);

  final _ChatMessage _self;
  final $Res Function(_ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? roomId = null,Object? senderId = null,Object? senderName = null,Object? senderAvatarUrl = freezed,Object? content = null,Object? type = null,Object? timestamp = null,Object? replyToId = freezed,Object? replyToContent = freezed,Object? replyToSender = freezed,Object? isEdited = null,Object? isRecalled = null,Object? mediaUrl = freezed,Object? mediaFileName = freezed,Object? mediaFileSize = freezed,Object? mediaDuration = freezed,Object? metadata = freezed,}) {
  return _then(_ChatMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,senderName: null == senderName ? _self.senderName : senderName // ignore: cast_nullable_to_non_nullable
as String,senderAvatarUrl: freezed == senderAvatarUrl ? _self.senderAvatarUrl : senderAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MessageType,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,replyToId: freezed == replyToId ? _self.replyToId : replyToId // ignore: cast_nullable_to_non_nullable
as String?,replyToContent: freezed == replyToContent ? _self.replyToContent : replyToContent // ignore: cast_nullable_to_non_nullable
as String?,replyToSender: freezed == replyToSender ? _self.replyToSender : replyToSender // ignore: cast_nullable_to_non_nullable
as String?,isEdited: null == isEdited ? _self.isEdited : isEdited // ignore: cast_nullable_to_non_nullable
as bool,isRecalled: null == isRecalled ? _self.isRecalled : isRecalled // ignore: cast_nullable_to_non_nullable
as bool,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,mediaFileName: freezed == mediaFileName ? _self.mediaFileName : mediaFileName // ignore: cast_nullable_to_non_nullable
as String?,mediaFileSize: freezed == mediaFileSize ? _self.mediaFileSize : mediaFileSize // ignore: cast_nullable_to_non_nullable
as int?,mediaDuration: freezed == mediaDuration ? _self.mediaDuration : mediaDuration // ignore: cast_nullable_to_non_nullable
as int?,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
