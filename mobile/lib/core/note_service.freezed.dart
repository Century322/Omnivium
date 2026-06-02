// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'note_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NoteItem {

 String get id; String get title; String get content; NoteType get type; bool get isDone; DateTime? get dueDate; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of NoteItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoteItemCopyWith<NoteItem> get copyWith => _$NoteItemCopyWithImpl<NoteItem>(this as NoteItem, _$identity);

  /// Serializes this NoteItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoteItem&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.type, type) || other.type == type)&&(identical(other.isDone, isDone) || other.isDone == isDone)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,content,type,isDone,dueDate,createdAt,updatedAt);

@override
String toString() {
  return 'NoteItem(id: $id, title: $title, content: $content, type: $type, isDone: $isDone, dueDate: $dueDate, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $NoteItemCopyWith<$Res>  {
  factory $NoteItemCopyWith(NoteItem value, $Res Function(NoteItem) _then) = _$NoteItemCopyWithImpl;
@useResult
$Res call({
 String id, String title, String content, NoteType type, bool isDone, DateTime? dueDate, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$NoteItemCopyWithImpl<$Res>
    implements $NoteItemCopyWith<$Res> {
  _$NoteItemCopyWithImpl(this._self, this._then);

  final NoteItem _self;
  final $Res Function(NoteItem) _then;

/// Create a copy of NoteItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? content = null,Object? type = null,Object? isDone = null,Object? dueDate = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as NoteType,isDone: null == isDone ? _self.isDone : isDone // ignore: cast_nullable_to_non_nullable
as bool,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [NoteItem].
extension NoteItemPatterns on NoteItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NoteItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NoteItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NoteItem value)  $default,){
final _that = this;
switch (_that) {
case _NoteItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NoteItem value)?  $default,){
final _that = this;
switch (_that) {
case _NoteItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String content,  NoteType type,  bool isDone,  DateTime? dueDate,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NoteItem() when $default != null:
return $default(_that.id,_that.title,_that.content,_that.type,_that.isDone,_that.dueDate,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String content,  NoteType type,  bool isDone,  DateTime? dueDate,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _NoteItem():
return $default(_that.id,_that.title,_that.content,_that.type,_that.isDone,_that.dueDate,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String content,  NoteType type,  bool isDone,  DateTime? dueDate,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _NoteItem() when $default != null:
return $default(_that.id,_that.title,_that.content,_that.type,_that.isDone,_that.dueDate,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NoteItem extends NoteItem {
  const _NoteItem({required this.id, required this.title, required this.content, this.type = NoteType.text, this.isDone = false, this.dueDate, required this.createdAt, required this.updatedAt}): super._();
  factory _NoteItem.fromJson(Map<String, dynamic> json) => _$NoteItemFromJson(json);

@override final  String id;
@override final  String title;
@override final  String content;
@override@JsonKey() final  NoteType type;
@override@JsonKey() final  bool isDone;
@override final  DateTime? dueDate;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of NoteItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NoteItemCopyWith<_NoteItem> get copyWith => __$NoteItemCopyWithImpl<_NoteItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NoteItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NoteItem&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.type, type) || other.type == type)&&(identical(other.isDone, isDone) || other.isDone == isDone)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,content,type,isDone,dueDate,createdAt,updatedAt);

@override
String toString() {
  return 'NoteItem(id: $id, title: $title, content: $content, type: $type, isDone: $isDone, dueDate: $dueDate, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$NoteItemCopyWith<$Res> implements $NoteItemCopyWith<$Res> {
  factory _$NoteItemCopyWith(_NoteItem value, $Res Function(_NoteItem) _then) = __$NoteItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String content, NoteType type, bool isDone, DateTime? dueDate, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$NoteItemCopyWithImpl<$Res>
    implements _$NoteItemCopyWith<$Res> {
  __$NoteItemCopyWithImpl(this._self, this._then);

  final _NoteItem _self;
  final $Res Function(_NoteItem) _then;

/// Create a copy of NoteItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? content = null,Object? type = null,Object? isDone = null,Object? dueDate = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_NoteItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as NoteType,isDone: null == isDone ? _self.isDone : isDone // ignore: cast_nullable_to_non_nullable
as bool,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
