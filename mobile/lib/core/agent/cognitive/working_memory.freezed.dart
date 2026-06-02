// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'working_memory.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkingMemoryItem {

 String get id; String get content; MemoryType get type; int get importance; DateTime get addedAt; DateTime get lastAccessedAt; double get relevanceScore;
/// Create a copy of WorkingMemoryItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkingMemoryItemCopyWith<WorkingMemoryItem> get copyWith => _$WorkingMemoryItemCopyWithImpl<WorkingMemoryItem>(this as WorkingMemoryItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkingMemoryItem&&(identical(other.id, id) || other.id == id)&&(identical(other.content, content) || other.content == content)&&(identical(other.type, type) || other.type == type)&&(identical(other.importance, importance) || other.importance == importance)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt)&&(identical(other.lastAccessedAt, lastAccessedAt) || other.lastAccessedAt == lastAccessedAt)&&(identical(other.relevanceScore, relevanceScore) || other.relevanceScore == relevanceScore));
}


@override
int get hashCode => Object.hash(runtimeType,id,content,type,importance,addedAt,lastAccessedAt,relevanceScore);

@override
String toString() {
  return 'WorkingMemoryItem(id: $id, content: $content, type: $type, importance: $importance, addedAt: $addedAt, lastAccessedAt: $lastAccessedAt, relevanceScore: $relevanceScore)';
}


}

/// @nodoc
abstract mixin class $WorkingMemoryItemCopyWith<$Res>  {
  factory $WorkingMemoryItemCopyWith(WorkingMemoryItem value, $Res Function(WorkingMemoryItem) _then) = _$WorkingMemoryItemCopyWithImpl;
@useResult
$Res call({
 String id, String content, MemoryType type, int importance, DateTime addedAt, DateTime lastAccessedAt, double relevanceScore
});




}
/// @nodoc
class _$WorkingMemoryItemCopyWithImpl<$Res>
    implements $WorkingMemoryItemCopyWith<$Res> {
  _$WorkingMemoryItemCopyWithImpl(this._self, this._then);

  final WorkingMemoryItem _self;
  final $Res Function(WorkingMemoryItem) _then;

/// Create a copy of WorkingMemoryItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? content = null,Object? type = null,Object? importance = null,Object? addedAt = null,Object? lastAccessedAt = null,Object? relevanceScore = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MemoryType,importance: null == importance ? _self.importance : importance // ignore: cast_nullable_to_non_nullable
as int,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastAccessedAt: null == lastAccessedAt ? _self.lastAccessedAt : lastAccessedAt // ignore: cast_nullable_to_non_nullable
as DateTime,relevanceScore: null == relevanceScore ? _self.relevanceScore : relevanceScore // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkingMemoryItem].
extension WorkingMemoryItemPatterns on WorkingMemoryItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkingMemoryItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkingMemoryItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkingMemoryItem value)  $default,){
final _that = this;
switch (_that) {
case _WorkingMemoryItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkingMemoryItem value)?  $default,){
final _that = this;
switch (_that) {
case _WorkingMemoryItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String content,  MemoryType type,  int importance,  DateTime addedAt,  DateTime lastAccessedAt,  double relevanceScore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkingMemoryItem() when $default != null:
return $default(_that.id,_that.content,_that.type,_that.importance,_that.addedAt,_that.lastAccessedAt,_that.relevanceScore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String content,  MemoryType type,  int importance,  DateTime addedAt,  DateTime lastAccessedAt,  double relevanceScore)  $default,) {final _that = this;
switch (_that) {
case _WorkingMemoryItem():
return $default(_that.id,_that.content,_that.type,_that.importance,_that.addedAt,_that.lastAccessedAt,_that.relevanceScore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String content,  MemoryType type,  int importance,  DateTime addedAt,  DateTime lastAccessedAt,  double relevanceScore)?  $default,) {final _that = this;
switch (_that) {
case _WorkingMemoryItem() when $default != null:
return $default(_that.id,_that.content,_that.type,_that.importance,_that.addedAt,_that.lastAccessedAt,_that.relevanceScore);case _:
  return null;

}
}

}

/// @nodoc


class _WorkingMemoryItem implements WorkingMemoryItem {
  const _WorkingMemoryItem({required this.id, required this.content, required this.type, this.importance = 50, required this.addedAt, required this.lastAccessedAt, this.relevanceScore = 1.0});
  

@override final  String id;
@override final  String content;
@override final  MemoryType type;
@override@JsonKey() final  int importance;
@override final  DateTime addedAt;
@override final  DateTime lastAccessedAt;
@override@JsonKey() final  double relevanceScore;

/// Create a copy of WorkingMemoryItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkingMemoryItemCopyWith<_WorkingMemoryItem> get copyWith => __$WorkingMemoryItemCopyWithImpl<_WorkingMemoryItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkingMemoryItem&&(identical(other.id, id) || other.id == id)&&(identical(other.content, content) || other.content == content)&&(identical(other.type, type) || other.type == type)&&(identical(other.importance, importance) || other.importance == importance)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt)&&(identical(other.lastAccessedAt, lastAccessedAt) || other.lastAccessedAt == lastAccessedAt)&&(identical(other.relevanceScore, relevanceScore) || other.relevanceScore == relevanceScore));
}


@override
int get hashCode => Object.hash(runtimeType,id,content,type,importance,addedAt,lastAccessedAt,relevanceScore);

@override
String toString() {
  return 'WorkingMemoryItem(id: $id, content: $content, type: $type, importance: $importance, addedAt: $addedAt, lastAccessedAt: $lastAccessedAt, relevanceScore: $relevanceScore)';
}


}

/// @nodoc
abstract mixin class _$WorkingMemoryItemCopyWith<$Res> implements $WorkingMemoryItemCopyWith<$Res> {
  factory _$WorkingMemoryItemCopyWith(_WorkingMemoryItem value, $Res Function(_WorkingMemoryItem) _then) = __$WorkingMemoryItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String content, MemoryType type, int importance, DateTime addedAt, DateTime lastAccessedAt, double relevanceScore
});




}
/// @nodoc
class __$WorkingMemoryItemCopyWithImpl<$Res>
    implements _$WorkingMemoryItemCopyWith<$Res> {
  __$WorkingMemoryItemCopyWithImpl(this._self, this._then);

  final _WorkingMemoryItem _self;
  final $Res Function(_WorkingMemoryItem) _then;

/// Create a copy of WorkingMemoryItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? content = null,Object? type = null,Object? importance = null,Object? addedAt = null,Object? lastAccessedAt = null,Object? relevanceScore = null,}) {
  return _then(_WorkingMemoryItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MemoryType,importance: null == importance ? _self.importance : importance // ignore: cast_nullable_to_non_nullable
as int,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastAccessedAt: null == lastAccessedAt ? _self.lastAccessedAt : lastAccessedAt // ignore: cast_nullable_to_non_nullable
as DateTime,relevanceScore: null == relevanceScore ? _self.relevanceScore : relevanceScore // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
