// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_room.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatRoom {

 String get id; String get name; String? get avatarUrl; bool get isDirect; bool get isGroup; int get unreadCount; String? get lastMessage; DateTime? get lastMessageTime; List<String> get memberIds; String? get topic; bool get isEncrypted;
/// Create a copy of ChatRoom
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatRoomCopyWith<ChatRoom> get copyWith => _$ChatRoomCopyWithImpl<ChatRoom>(this as ChatRoom, _$identity);

  /// Serializes this ChatRoom to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatRoom&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isDirect, isDirect) || other.isDirect == isDirect)&&(identical(other.isGroup, isGroup) || other.isGroup == isGroup)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&(identical(other.lastMessage, lastMessage) || other.lastMessage == lastMessage)&&(identical(other.lastMessageTime, lastMessageTime) || other.lastMessageTime == lastMessageTime)&&const DeepCollectionEquality().equals(other.memberIds, memberIds)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.isEncrypted, isEncrypted) || other.isEncrypted == isEncrypted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,avatarUrl,isDirect,isGroup,unreadCount,lastMessage,lastMessageTime,const DeepCollectionEquality().hash(memberIds),topic,isEncrypted);

@override
String toString() {
  return 'ChatRoom(id: $id, name: $name, avatarUrl: $avatarUrl, isDirect: $isDirect, isGroup: $isGroup, unreadCount: $unreadCount, lastMessage: $lastMessage, lastMessageTime: $lastMessageTime, memberIds: $memberIds, topic: $topic, isEncrypted: $isEncrypted)';
}


}

/// @nodoc
abstract mixin class $ChatRoomCopyWith<$Res>  {
  factory $ChatRoomCopyWith(ChatRoom value, $Res Function(ChatRoom) _then) = _$ChatRoomCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? avatarUrl, bool isDirect, bool isGroup, int unreadCount, String? lastMessage, DateTime? lastMessageTime, List<String> memberIds, String? topic, bool isEncrypted
});




}
/// @nodoc
class _$ChatRoomCopyWithImpl<$Res>
    implements $ChatRoomCopyWith<$Res> {
  _$ChatRoomCopyWithImpl(this._self, this._then);

  final ChatRoom _self;
  final $Res Function(ChatRoom) _then;

/// Create a copy of ChatRoom
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? avatarUrl = freezed,Object? isDirect = null,Object? isGroup = null,Object? unreadCount = null,Object? lastMessage = freezed,Object? lastMessageTime = freezed,Object? memberIds = null,Object? topic = freezed,Object? isEncrypted = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isDirect: null == isDirect ? _self.isDirect : isDirect // ignore: cast_nullable_to_non_nullable
as bool,isGroup: null == isGroup ? _self.isGroup : isGroup // ignore: cast_nullable_to_non_nullable
as bool,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,lastMessage: freezed == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as String?,lastMessageTime: freezed == lastMessageTime ? _self.lastMessageTime : lastMessageTime // ignore: cast_nullable_to_non_nullable
as DateTime?,memberIds: null == memberIds ? _self.memberIds : memberIds // ignore: cast_nullable_to_non_nullable
as List<String>,topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String?,isEncrypted: null == isEncrypted ? _self.isEncrypted : isEncrypted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatRoom].
extension ChatRoomPatterns on ChatRoom {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatRoom value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatRoom() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatRoom value)  $default,){
final _that = this;
switch (_that) {
case _ChatRoom():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatRoom value)?  $default,){
final _that = this;
switch (_that) {
case _ChatRoom() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? avatarUrl,  bool isDirect,  bool isGroup,  int unreadCount,  String? lastMessage,  DateTime? lastMessageTime,  List<String> memberIds,  String? topic,  bool isEncrypted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatRoom() when $default != null:
return $default(_that.id,_that.name,_that.avatarUrl,_that.isDirect,_that.isGroup,_that.unreadCount,_that.lastMessage,_that.lastMessageTime,_that.memberIds,_that.topic,_that.isEncrypted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? avatarUrl,  bool isDirect,  bool isGroup,  int unreadCount,  String? lastMessage,  DateTime? lastMessageTime,  List<String> memberIds,  String? topic,  bool isEncrypted)  $default,) {final _that = this;
switch (_that) {
case _ChatRoom():
return $default(_that.id,_that.name,_that.avatarUrl,_that.isDirect,_that.isGroup,_that.unreadCount,_that.lastMessage,_that.lastMessageTime,_that.memberIds,_that.topic,_that.isEncrypted);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? avatarUrl,  bool isDirect,  bool isGroup,  int unreadCount,  String? lastMessage,  DateTime? lastMessageTime,  List<String> memberIds,  String? topic,  bool isEncrypted)?  $default,) {final _that = this;
switch (_that) {
case _ChatRoom() when $default != null:
return $default(_that.id,_that.name,_that.avatarUrl,_that.isDirect,_that.isGroup,_that.unreadCount,_that.lastMessage,_that.lastMessageTime,_that.memberIds,_that.topic,_that.isEncrypted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatRoom implements ChatRoom {
  const _ChatRoom({required this.id, required this.name, this.avatarUrl, this.isDirect = false, this.isGroup = false, this.unreadCount = 0, this.lastMessage, this.lastMessageTime, final  List<String> memberIds = const [], this.topic, this.isEncrypted = false}): _memberIds = memberIds;
  factory _ChatRoom.fromJson(Map<String, dynamic> json) => _$ChatRoomFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? avatarUrl;
@override@JsonKey() final  bool isDirect;
@override@JsonKey() final  bool isGroup;
@override@JsonKey() final  int unreadCount;
@override final  String? lastMessage;
@override final  DateTime? lastMessageTime;
 final  List<String> _memberIds;
@override@JsonKey() List<String> get memberIds {
  if (_memberIds is EqualUnmodifiableListView) return _memberIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_memberIds);
}

@override final  String? topic;
@override@JsonKey() final  bool isEncrypted;

/// Create a copy of ChatRoom
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatRoomCopyWith<_ChatRoom> get copyWith => __$ChatRoomCopyWithImpl<_ChatRoom>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatRoomToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatRoom&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isDirect, isDirect) || other.isDirect == isDirect)&&(identical(other.isGroup, isGroup) || other.isGroup == isGroup)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&(identical(other.lastMessage, lastMessage) || other.lastMessage == lastMessage)&&(identical(other.lastMessageTime, lastMessageTime) || other.lastMessageTime == lastMessageTime)&&const DeepCollectionEquality().equals(other._memberIds, _memberIds)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.isEncrypted, isEncrypted) || other.isEncrypted == isEncrypted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,avatarUrl,isDirect,isGroup,unreadCount,lastMessage,lastMessageTime,const DeepCollectionEquality().hash(_memberIds),topic,isEncrypted);

@override
String toString() {
  return 'ChatRoom(id: $id, name: $name, avatarUrl: $avatarUrl, isDirect: $isDirect, isGroup: $isGroup, unreadCount: $unreadCount, lastMessage: $lastMessage, lastMessageTime: $lastMessageTime, memberIds: $memberIds, topic: $topic, isEncrypted: $isEncrypted)';
}


}

/// @nodoc
abstract mixin class _$ChatRoomCopyWith<$Res> implements $ChatRoomCopyWith<$Res> {
  factory _$ChatRoomCopyWith(_ChatRoom value, $Res Function(_ChatRoom) _then) = __$ChatRoomCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? avatarUrl, bool isDirect, bool isGroup, int unreadCount, String? lastMessage, DateTime? lastMessageTime, List<String> memberIds, String? topic, bool isEncrypted
});




}
/// @nodoc
class __$ChatRoomCopyWithImpl<$Res>
    implements _$ChatRoomCopyWith<$Res> {
  __$ChatRoomCopyWithImpl(this._self, this._then);

  final _ChatRoom _self;
  final $Res Function(_ChatRoom) _then;

/// Create a copy of ChatRoom
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? avatarUrl = freezed,Object? isDirect = null,Object? isGroup = null,Object? unreadCount = null,Object? lastMessage = freezed,Object? lastMessageTime = freezed,Object? memberIds = null,Object? topic = freezed,Object? isEncrypted = null,}) {
  return _then(_ChatRoom(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isDirect: null == isDirect ? _self.isDirect : isDirect // ignore: cast_nullable_to_non_nullable
as bool,isGroup: null == isGroup ? _self.isGroup : isGroup // ignore: cast_nullable_to_non_nullable
as bool,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,lastMessage: freezed == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as String?,lastMessageTime: freezed == lastMessageTime ? _self.lastMessageTime : lastMessageTime // ignore: cast_nullable_to_non_nullable
as DateTime?,memberIds: null == memberIds ? _self._memberIds : memberIds // ignore: cast_nullable_to_non_nullable
as List<String>,topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String?,isEncrypted: null == isEncrypted ? _self.isEncrypted : isEncrypted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
