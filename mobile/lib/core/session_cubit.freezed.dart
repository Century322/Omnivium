// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionMessage {

 String get role; String get content;
/// Create a copy of SessionMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionMessageCopyWith<SessionMessage> get copyWith => _$SessionMessageCopyWithImpl<SessionMessage>(this as SessionMessage, _$identity);

  /// Serializes this SessionMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionMessage&&(identical(other.role, role) || other.role == role)&&(identical(other.content, content) || other.content == content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,role,content);

@override
String toString() {
  return 'SessionMessage(role: $role, content: $content)';
}


}

/// @nodoc
abstract mixin class $SessionMessageCopyWith<$Res>  {
  factory $SessionMessageCopyWith(SessionMessage value, $Res Function(SessionMessage) _then) = _$SessionMessageCopyWithImpl;
@useResult
$Res call({
 String role, String content
});




}
/// @nodoc
class _$SessionMessageCopyWithImpl<$Res>
    implements $SessionMessageCopyWith<$Res> {
  _$SessionMessageCopyWithImpl(this._self, this._then);

  final SessionMessage _self;
  final $Res Function(SessionMessage) _then;

/// Create a copy of SessionMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? role = null,Object? content = null,}) {
  return _then(_self.copyWith(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionMessage].
extension SessionMessagePatterns on SessionMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionMessage value)  $default,){
final _that = this;
switch (_that) {
case _SessionMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionMessage value)?  $default,){
final _that = this;
switch (_that) {
case _SessionMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String role,  String content)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionMessage() when $default != null:
return $default(_that.role,_that.content);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String role,  String content)  $default,) {final _that = this;
switch (_that) {
case _SessionMessage():
return $default(_that.role,_that.content);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String role,  String content)?  $default,) {final _that = this;
switch (_that) {
case _SessionMessage() when $default != null:
return $default(_that.role,_that.content);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionMessage extends SessionMessage {
  const _SessionMessage({required this.role, required this.content}): super._();
  factory _SessionMessage.fromJson(Map<String, dynamic> json) => _$SessionMessageFromJson(json);

@override final  String role;
@override final  String content;

/// Create a copy of SessionMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionMessageCopyWith<_SessionMessage> get copyWith => __$SessionMessageCopyWithImpl<_SessionMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionMessage&&(identical(other.role, role) || other.role == role)&&(identical(other.content, content) || other.content == content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,role,content);

@override
String toString() {
  return 'SessionMessage(role: $role, content: $content)';
}


}

/// @nodoc
abstract mixin class _$SessionMessageCopyWith<$Res> implements $SessionMessageCopyWith<$Res> {
  factory _$SessionMessageCopyWith(_SessionMessage value, $Res Function(_SessionMessage) _then) = __$SessionMessageCopyWithImpl;
@override @useResult
$Res call({
 String role, String content
});




}
/// @nodoc
class __$SessionMessageCopyWithImpl<$Res>
    implements _$SessionMessageCopyWith<$Res> {
  __$SessionMessageCopyWithImpl(this._self, this._then);

  final _SessionMessage _self;
  final $Res Function(_SessionMessage) _then;

/// Create a copy of SessionMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? role = null,Object? content = null,}) {
  return _then(_SessionMessage(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ConversationSession {

 String get id; String get title; DateTime get createdAt; DateTime? get lastActiveAt; List<SessionMessage> get messages; bool get isArchived; bool get isFavorite; bool get isPinned; bool get isMuted;
/// Create a copy of ConversationSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationSessionCopyWith<ConversationSession> get copyWith => _$ConversationSessionCopyWithImpl<ConversationSession>(this as ConversationSession, _$identity);

  /// Serializes this ConversationSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationSession&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt)&&const DeepCollectionEquality().equals(other.messages, messages)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,createdAt,lastActiveAt,const DeepCollectionEquality().hash(messages),isArchived,isFavorite,isPinned,isMuted);

@override
String toString() {
  return 'ConversationSession(id: $id, title: $title, createdAt: $createdAt, lastActiveAt: $lastActiveAt, messages: $messages, isArchived: $isArchived, isFavorite: $isFavorite, isPinned: $isPinned, isMuted: $isMuted)';
}


}

/// @nodoc
abstract mixin class $ConversationSessionCopyWith<$Res>  {
  factory $ConversationSessionCopyWith(ConversationSession value, $Res Function(ConversationSession) _then) = _$ConversationSessionCopyWithImpl;
@useResult
$Res call({
 String id, String title, DateTime createdAt, DateTime? lastActiveAt, List<SessionMessage> messages, bool isArchived, bool isFavorite, bool isPinned, bool isMuted
});




}
/// @nodoc
class _$ConversationSessionCopyWithImpl<$Res>
    implements $ConversationSessionCopyWith<$Res> {
  _$ConversationSessionCopyWithImpl(this._self, this._then);

  final ConversationSession _self;
  final $Res Function(ConversationSession) _then;

/// Create a copy of ConversationSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? createdAt = null,Object? lastActiveAt = freezed,Object? messages = null,Object? isArchived = null,Object? isFavorite = null,Object? isPinned = null,Object? isMuted = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastActiveAt: freezed == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<SessionMessage>,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ConversationSession].
extension ConversationSessionPatterns on ConversationSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationSession value)  $default,){
final _that = this;
switch (_that) {
case _ConversationSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationSession value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  DateTime createdAt,  DateTime? lastActiveAt,  List<SessionMessage> messages,  bool isArchived,  bool isFavorite,  bool isPinned,  bool isMuted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationSession() when $default != null:
return $default(_that.id,_that.title,_that.createdAt,_that.lastActiveAt,_that.messages,_that.isArchived,_that.isFavorite,_that.isPinned,_that.isMuted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  DateTime createdAt,  DateTime? lastActiveAt,  List<SessionMessage> messages,  bool isArchived,  bool isFavorite,  bool isPinned,  bool isMuted)  $default,) {final _that = this;
switch (_that) {
case _ConversationSession():
return $default(_that.id,_that.title,_that.createdAt,_that.lastActiveAt,_that.messages,_that.isArchived,_that.isFavorite,_that.isPinned,_that.isMuted);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  DateTime createdAt,  DateTime? lastActiveAt,  List<SessionMessage> messages,  bool isArchived,  bool isFavorite,  bool isPinned,  bool isMuted)?  $default,) {final _that = this;
switch (_that) {
case _ConversationSession() when $default != null:
return $default(_that.id,_that.title,_that.createdAt,_that.lastActiveAt,_that.messages,_that.isArchived,_that.isFavorite,_that.isPinned,_that.isMuted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConversationSession extends ConversationSession {
  const _ConversationSession({required this.id, required this.title, required this.createdAt, this.lastActiveAt, final  List<SessionMessage> messages = const [], this.isArchived = false, this.isFavorite = false, this.isPinned = false, this.isMuted = false}): _messages = messages,super._();
  factory _ConversationSession.fromJson(Map<String, dynamic> json) => _$ConversationSessionFromJson(json);

@override final  String id;
@override final  String title;
@override final  DateTime createdAt;
@override final  DateTime? lastActiveAt;
 final  List<SessionMessage> _messages;
@override@JsonKey() List<SessionMessage> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}

@override@JsonKey() final  bool isArchived;
@override@JsonKey() final  bool isFavorite;
@override@JsonKey() final  bool isPinned;
@override@JsonKey() final  bool isMuted;

/// Create a copy of ConversationSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationSessionCopyWith<_ConversationSession> get copyWith => __$ConversationSessionCopyWithImpl<_ConversationSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConversationSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationSession&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt)&&const DeepCollectionEquality().equals(other._messages, _messages)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,createdAt,lastActiveAt,const DeepCollectionEquality().hash(_messages),isArchived,isFavorite,isPinned,isMuted);

@override
String toString() {
  return 'ConversationSession(id: $id, title: $title, createdAt: $createdAt, lastActiveAt: $lastActiveAt, messages: $messages, isArchived: $isArchived, isFavorite: $isFavorite, isPinned: $isPinned, isMuted: $isMuted)';
}


}

/// @nodoc
abstract mixin class _$ConversationSessionCopyWith<$Res> implements $ConversationSessionCopyWith<$Res> {
  factory _$ConversationSessionCopyWith(_ConversationSession value, $Res Function(_ConversationSession) _then) = __$ConversationSessionCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, DateTime createdAt, DateTime? lastActiveAt, List<SessionMessage> messages, bool isArchived, bool isFavorite, bool isPinned, bool isMuted
});




}
/// @nodoc
class __$ConversationSessionCopyWithImpl<$Res>
    implements _$ConversationSessionCopyWith<$Res> {
  __$ConversationSessionCopyWithImpl(this._self, this._then);

  final _ConversationSession _self;
  final $Res Function(_ConversationSession) _then;

/// Create a copy of ConversationSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? createdAt = null,Object? lastActiveAt = freezed,Object? messages = null,Object? isArchived = null,Object? isFavorite = null,Object? isPinned = null,Object? isMuted = null,}) {
  return _then(_ConversationSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastActiveAt: freezed == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<SessionMessage>,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
