// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'agent_reminder_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Reminder {

 String get id; ReminderType get type; String get title; String get description; ReminderFrequency get frequency; DateTime get createdAt; DateTime? get nextTriggerAt; ReminderStatus get status; Map<String, dynamic> get metadata; String? get matrixRoomId; String? get aiPrompt; String? get skillId; Map<String, dynamic>? get skillParams;
/// Create a copy of Reminder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReminderCopyWith<Reminder> get copyWith => _$ReminderCopyWithImpl<Reminder>(this as Reminder, _$identity);

  /// Serializes this Reminder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Reminder&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.nextTriggerAt, nextTriggerAt) || other.nextTriggerAt == nextTriggerAt)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.matrixRoomId, matrixRoomId) || other.matrixRoomId == matrixRoomId)&&(identical(other.aiPrompt, aiPrompt) || other.aiPrompt == aiPrompt)&&(identical(other.skillId, skillId) || other.skillId == skillId)&&const DeepCollectionEquality().equals(other.skillParams, skillParams));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,title,description,frequency,createdAt,nextTriggerAt,status,const DeepCollectionEquality().hash(metadata),matrixRoomId,aiPrompt,skillId,const DeepCollectionEquality().hash(skillParams));

@override
String toString() {
  return 'Reminder(id: $id, type: $type, title: $title, description: $description, frequency: $frequency, createdAt: $createdAt, nextTriggerAt: $nextTriggerAt, status: $status, metadata: $metadata, matrixRoomId: $matrixRoomId, aiPrompt: $aiPrompt, skillId: $skillId, skillParams: $skillParams)';
}


}

/// @nodoc
abstract mixin class $ReminderCopyWith<$Res>  {
  factory $ReminderCopyWith(Reminder value, $Res Function(Reminder) _then) = _$ReminderCopyWithImpl;
@useResult
$Res call({
 String id, ReminderType type, String title, String description, ReminderFrequency frequency, DateTime createdAt, DateTime? nextTriggerAt, ReminderStatus status, Map<String, dynamic> metadata, String? matrixRoomId, String? aiPrompt, String? skillId, Map<String, dynamic>? skillParams
});




}
/// @nodoc
class _$ReminderCopyWithImpl<$Res>
    implements $ReminderCopyWith<$Res> {
  _$ReminderCopyWithImpl(this._self, this._then);

  final Reminder _self;
  final $Res Function(Reminder) _then;

/// Create a copy of Reminder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? title = null,Object? description = null,Object? frequency = null,Object? createdAt = null,Object? nextTriggerAt = freezed,Object? status = null,Object? metadata = null,Object? matrixRoomId = freezed,Object? aiPrompt = freezed,Object? skillId = freezed,Object? skillParams = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ReminderType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as ReminderFrequency,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,nextTriggerAt: freezed == nextTriggerAt ? _self.nextTriggerAt : nextTriggerAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReminderStatus,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,matrixRoomId: freezed == matrixRoomId ? _self.matrixRoomId : matrixRoomId // ignore: cast_nullable_to_non_nullable
as String?,aiPrompt: freezed == aiPrompt ? _self.aiPrompt : aiPrompt // ignore: cast_nullable_to_non_nullable
as String?,skillId: freezed == skillId ? _self.skillId : skillId // ignore: cast_nullable_to_non_nullable
as String?,skillParams: freezed == skillParams ? _self.skillParams : skillParams // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [Reminder].
extension ReminderPatterns on Reminder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Reminder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Reminder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Reminder value)  $default,){
final _that = this;
switch (_that) {
case _Reminder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Reminder value)?  $default,){
final _that = this;
switch (_that) {
case _Reminder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ReminderType type,  String title,  String description,  ReminderFrequency frequency,  DateTime createdAt,  DateTime? nextTriggerAt,  ReminderStatus status,  Map<String, dynamic> metadata,  String? matrixRoomId,  String? aiPrompt,  String? skillId,  Map<String, dynamic>? skillParams)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Reminder() when $default != null:
return $default(_that.id,_that.type,_that.title,_that.description,_that.frequency,_that.createdAt,_that.nextTriggerAt,_that.status,_that.metadata,_that.matrixRoomId,_that.aiPrompt,_that.skillId,_that.skillParams);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ReminderType type,  String title,  String description,  ReminderFrequency frequency,  DateTime createdAt,  DateTime? nextTriggerAt,  ReminderStatus status,  Map<String, dynamic> metadata,  String? matrixRoomId,  String? aiPrompt,  String? skillId,  Map<String, dynamic>? skillParams)  $default,) {final _that = this;
switch (_that) {
case _Reminder():
return $default(_that.id,_that.type,_that.title,_that.description,_that.frequency,_that.createdAt,_that.nextTriggerAt,_that.status,_that.metadata,_that.matrixRoomId,_that.aiPrompt,_that.skillId,_that.skillParams);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ReminderType type,  String title,  String description,  ReminderFrequency frequency,  DateTime createdAt,  DateTime? nextTriggerAt,  ReminderStatus status,  Map<String, dynamic> metadata,  String? matrixRoomId,  String? aiPrompt,  String? skillId,  Map<String, dynamic>? skillParams)?  $default,) {final _that = this;
switch (_that) {
case _Reminder() when $default != null:
return $default(_that.id,_that.type,_that.title,_that.description,_that.frequency,_that.createdAt,_that.nextTriggerAt,_that.status,_that.metadata,_that.matrixRoomId,_that.aiPrompt,_that.skillId,_that.skillParams);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Reminder extends Reminder {
  const _Reminder({required this.id, required this.type, required this.title, required this.description, required this.frequency, required this.createdAt, this.nextTriggerAt, this.status = ReminderStatus.active, final  Map<String, dynamic> metadata = const <String, dynamic>{}, this.matrixRoomId, this.aiPrompt, this.skillId, final  Map<String, dynamic>? skillParams}): _metadata = metadata,_skillParams = skillParams,super._();
  factory _Reminder.fromJson(Map<String, dynamic> json) => _$ReminderFromJson(json);

@override final  String id;
@override final  ReminderType type;
@override final  String title;
@override final  String description;
@override final  ReminderFrequency frequency;
@override final  DateTime createdAt;
@override final  DateTime? nextTriggerAt;
@override@JsonKey() final  ReminderStatus status;
 final  Map<String, dynamic> _metadata;
@override@JsonKey() Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}

@override final  String? matrixRoomId;
@override final  String? aiPrompt;
@override final  String? skillId;
 final  Map<String, dynamic>? _skillParams;
@override Map<String, dynamic>? get skillParams {
  final value = _skillParams;
  if (value == null) return null;
  if (_skillParams is EqualUnmodifiableMapView) return _skillParams;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of Reminder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReminderCopyWith<_Reminder> get copyWith => __$ReminderCopyWithImpl<_Reminder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReminderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Reminder&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.nextTriggerAt, nextTriggerAt) || other.nextTriggerAt == nextTriggerAt)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.matrixRoomId, matrixRoomId) || other.matrixRoomId == matrixRoomId)&&(identical(other.aiPrompt, aiPrompt) || other.aiPrompt == aiPrompt)&&(identical(other.skillId, skillId) || other.skillId == skillId)&&const DeepCollectionEquality().equals(other._skillParams, _skillParams));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,title,description,frequency,createdAt,nextTriggerAt,status,const DeepCollectionEquality().hash(_metadata),matrixRoomId,aiPrompt,skillId,const DeepCollectionEquality().hash(_skillParams));

@override
String toString() {
  return 'Reminder(id: $id, type: $type, title: $title, description: $description, frequency: $frequency, createdAt: $createdAt, nextTriggerAt: $nextTriggerAt, status: $status, metadata: $metadata, matrixRoomId: $matrixRoomId, aiPrompt: $aiPrompt, skillId: $skillId, skillParams: $skillParams)';
}


}

/// @nodoc
abstract mixin class _$ReminderCopyWith<$Res> implements $ReminderCopyWith<$Res> {
  factory _$ReminderCopyWith(_Reminder value, $Res Function(_Reminder) _then) = __$ReminderCopyWithImpl;
@override @useResult
$Res call({
 String id, ReminderType type, String title, String description, ReminderFrequency frequency, DateTime createdAt, DateTime? nextTriggerAt, ReminderStatus status, Map<String, dynamic> metadata, String? matrixRoomId, String? aiPrompt, String? skillId, Map<String, dynamic>? skillParams
});




}
/// @nodoc
class __$ReminderCopyWithImpl<$Res>
    implements _$ReminderCopyWith<$Res> {
  __$ReminderCopyWithImpl(this._self, this._then);

  final _Reminder _self;
  final $Res Function(_Reminder) _then;

/// Create a copy of Reminder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? title = null,Object? description = null,Object? frequency = null,Object? createdAt = null,Object? nextTriggerAt = freezed,Object? status = null,Object? metadata = null,Object? matrixRoomId = freezed,Object? aiPrompt = freezed,Object? skillId = freezed,Object? skillParams = freezed,}) {
  return _then(_Reminder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ReminderType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as ReminderFrequency,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,nextTriggerAt: freezed == nextTriggerAt ? _self.nextTriggerAt : nextTriggerAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReminderStatus,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,matrixRoomId: freezed == matrixRoomId ? _self.matrixRoomId : matrixRoomId // ignore: cast_nullable_to_non_nullable
as String?,aiPrompt: freezed == aiPrompt ? _self.aiPrompt : aiPrompt // ignore: cast_nullable_to_non_nullable
as String?,skillId: freezed == skillId ? _self.skillId : skillId // ignore: cast_nullable_to_non_nullable
as String?,skillParams: freezed == skillParams ? _self._skillParams : skillParams // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
