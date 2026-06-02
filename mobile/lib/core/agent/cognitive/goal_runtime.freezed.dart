// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'goal_runtime.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GoalNode {

 String get id; String get title; GoalStatus get status; String? get parentGoalId; String? get workspaceId; int get priority; DateTime get createdAt; DateTime? get completedAt; List<String> get successConditions; List<String> get failureConditions; DateTime? get deadline; int get progress; List<String> get dependencies; List<String> get blockers; List<String> get relatedEntityIds; Map<String, dynamic> get metadata;
/// Create a copy of GoalNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GoalNodeCopyWith<GoalNode> get copyWith => _$GoalNodeCopyWithImpl<GoalNode>(this as GoalNode, _$identity);

  /// Serializes this GoalNode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GoalNode&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.parentGoalId, parentGoalId) || other.parentGoalId == parentGoalId)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&const DeepCollectionEquality().equals(other.successConditions, successConditions)&&const DeepCollectionEquality().equals(other.failureConditions, failureConditions)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.progress, progress) || other.progress == progress)&&const DeepCollectionEquality().equals(other.dependencies, dependencies)&&const DeepCollectionEquality().equals(other.blockers, blockers)&&const DeepCollectionEquality().equals(other.relatedEntityIds, relatedEntityIds)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,status,parentGoalId,workspaceId,priority,createdAt,completedAt,const DeepCollectionEquality().hash(successConditions),const DeepCollectionEquality().hash(failureConditions),deadline,progress,const DeepCollectionEquality().hash(dependencies),const DeepCollectionEquality().hash(blockers),const DeepCollectionEquality().hash(relatedEntityIds),const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'GoalNode(id: $id, title: $title, status: $status, parentGoalId: $parentGoalId, workspaceId: $workspaceId, priority: $priority, createdAt: $createdAt, completedAt: $completedAt, successConditions: $successConditions, failureConditions: $failureConditions, deadline: $deadline, progress: $progress, dependencies: $dependencies, blockers: $blockers, relatedEntityIds: $relatedEntityIds, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $GoalNodeCopyWith<$Res>  {
  factory $GoalNodeCopyWith(GoalNode value, $Res Function(GoalNode) _then) = _$GoalNodeCopyWithImpl;
@useResult
$Res call({
 String id, String title, GoalStatus status, String? parentGoalId, String? workspaceId, int priority, DateTime createdAt, DateTime? completedAt, List<String> successConditions, List<String> failureConditions, DateTime? deadline, int progress, List<String> dependencies, List<String> blockers, List<String> relatedEntityIds, Map<String, dynamic> metadata
});




}
/// @nodoc
class _$GoalNodeCopyWithImpl<$Res>
    implements $GoalNodeCopyWith<$Res> {
  _$GoalNodeCopyWithImpl(this._self, this._then);

  final GoalNode _self;
  final $Res Function(GoalNode) _then;

/// Create a copy of GoalNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? status = null,Object? parentGoalId = freezed,Object? workspaceId = freezed,Object? priority = null,Object? createdAt = null,Object? completedAt = freezed,Object? successConditions = null,Object? failureConditions = null,Object? deadline = freezed,Object? progress = null,Object? dependencies = null,Object? blockers = null,Object? relatedEntityIds = null,Object? metadata = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GoalStatus,parentGoalId: freezed == parentGoalId ? _self.parentGoalId : parentGoalId // ignore: cast_nullable_to_non_nullable
as String?,workspaceId: freezed == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,successConditions: null == successConditions ? _self.successConditions : successConditions // ignore: cast_nullable_to_non_nullable
as List<String>,failureConditions: null == failureConditions ? _self.failureConditions : failureConditions // ignore: cast_nullable_to_non_nullable
as List<String>,deadline: freezed == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime?,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as int,dependencies: null == dependencies ? _self.dependencies : dependencies // ignore: cast_nullable_to_non_nullable
as List<String>,blockers: null == blockers ? _self.blockers : blockers // ignore: cast_nullable_to_non_nullable
as List<String>,relatedEntityIds: null == relatedEntityIds ? _self.relatedEntityIds : relatedEntityIds // ignore: cast_nullable_to_non_nullable
as List<String>,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [GoalNode].
extension GoalNodePatterns on GoalNode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GoalNode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GoalNode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GoalNode value)  $default,){
final _that = this;
switch (_that) {
case _GoalNode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GoalNode value)?  $default,){
final _that = this;
switch (_that) {
case _GoalNode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  GoalStatus status,  String? parentGoalId,  String? workspaceId,  int priority,  DateTime createdAt,  DateTime? completedAt,  List<String> successConditions,  List<String> failureConditions,  DateTime? deadline,  int progress,  List<String> dependencies,  List<String> blockers,  List<String> relatedEntityIds,  Map<String, dynamic> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GoalNode() when $default != null:
return $default(_that.id,_that.title,_that.status,_that.parentGoalId,_that.workspaceId,_that.priority,_that.createdAt,_that.completedAt,_that.successConditions,_that.failureConditions,_that.deadline,_that.progress,_that.dependencies,_that.blockers,_that.relatedEntityIds,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  GoalStatus status,  String? parentGoalId,  String? workspaceId,  int priority,  DateTime createdAt,  DateTime? completedAt,  List<String> successConditions,  List<String> failureConditions,  DateTime? deadline,  int progress,  List<String> dependencies,  List<String> blockers,  List<String> relatedEntityIds,  Map<String, dynamic> metadata)  $default,) {final _that = this;
switch (_that) {
case _GoalNode():
return $default(_that.id,_that.title,_that.status,_that.parentGoalId,_that.workspaceId,_that.priority,_that.createdAt,_that.completedAt,_that.successConditions,_that.failureConditions,_that.deadline,_that.progress,_that.dependencies,_that.blockers,_that.relatedEntityIds,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  GoalStatus status,  String? parentGoalId,  String? workspaceId,  int priority,  DateTime createdAt,  DateTime? completedAt,  List<String> successConditions,  List<String> failureConditions,  DateTime? deadline,  int progress,  List<String> dependencies,  List<String> blockers,  List<String> relatedEntityIds,  Map<String, dynamic> metadata)?  $default,) {final _that = this;
switch (_that) {
case _GoalNode() when $default != null:
return $default(_that.id,_that.title,_that.status,_that.parentGoalId,_that.workspaceId,_that.priority,_that.createdAt,_that.completedAt,_that.successConditions,_that.failureConditions,_that.deadline,_that.progress,_that.dependencies,_that.blockers,_that.relatedEntityIds,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GoalNode extends GoalNode {
  const _GoalNode({required this.id, required this.title, this.status = GoalStatus.planned, this.parentGoalId, this.workspaceId, this.priority = 50, required this.createdAt, this.completedAt, final  List<String> successConditions = const <String>[], final  List<String> failureConditions = const <String>[], this.deadline, this.progress = 0, final  List<String> dependencies = const <String>[], final  List<String> blockers = const <String>[], final  List<String> relatedEntityIds = const <String>[], final  Map<String, dynamic> metadata = const <String, dynamic>{}}): _successConditions = successConditions,_failureConditions = failureConditions,_dependencies = dependencies,_blockers = blockers,_relatedEntityIds = relatedEntityIds,_metadata = metadata,super._();
  factory _GoalNode.fromJson(Map<String, dynamic> json) => _$GoalNodeFromJson(json);

@override final  String id;
@override final  String title;
@override@JsonKey() final  GoalStatus status;
@override final  String? parentGoalId;
@override final  String? workspaceId;
@override@JsonKey() final  int priority;
@override final  DateTime createdAt;
@override final  DateTime? completedAt;
 final  List<String> _successConditions;
@override@JsonKey() List<String> get successConditions {
  if (_successConditions is EqualUnmodifiableListView) return _successConditions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_successConditions);
}

 final  List<String> _failureConditions;
@override@JsonKey() List<String> get failureConditions {
  if (_failureConditions is EqualUnmodifiableListView) return _failureConditions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_failureConditions);
}

@override final  DateTime? deadline;
@override@JsonKey() final  int progress;
 final  List<String> _dependencies;
@override@JsonKey() List<String> get dependencies {
  if (_dependencies is EqualUnmodifiableListView) return _dependencies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dependencies);
}

 final  List<String> _blockers;
@override@JsonKey() List<String> get blockers {
  if (_blockers is EqualUnmodifiableListView) return _blockers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_blockers);
}

 final  List<String> _relatedEntityIds;
@override@JsonKey() List<String> get relatedEntityIds {
  if (_relatedEntityIds is EqualUnmodifiableListView) return _relatedEntityIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_relatedEntityIds);
}

 final  Map<String, dynamic> _metadata;
@override@JsonKey() Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}


/// Create a copy of GoalNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GoalNodeCopyWith<_GoalNode> get copyWith => __$GoalNodeCopyWithImpl<_GoalNode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GoalNodeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GoalNode&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.parentGoalId, parentGoalId) || other.parentGoalId == parentGoalId)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&const DeepCollectionEquality().equals(other._successConditions, _successConditions)&&const DeepCollectionEquality().equals(other._failureConditions, _failureConditions)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.progress, progress) || other.progress == progress)&&const DeepCollectionEquality().equals(other._dependencies, _dependencies)&&const DeepCollectionEquality().equals(other._blockers, _blockers)&&const DeepCollectionEquality().equals(other._relatedEntityIds, _relatedEntityIds)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,status,parentGoalId,workspaceId,priority,createdAt,completedAt,const DeepCollectionEquality().hash(_successConditions),const DeepCollectionEquality().hash(_failureConditions),deadline,progress,const DeepCollectionEquality().hash(_dependencies),const DeepCollectionEquality().hash(_blockers),const DeepCollectionEquality().hash(_relatedEntityIds),const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'GoalNode(id: $id, title: $title, status: $status, parentGoalId: $parentGoalId, workspaceId: $workspaceId, priority: $priority, createdAt: $createdAt, completedAt: $completedAt, successConditions: $successConditions, failureConditions: $failureConditions, deadline: $deadline, progress: $progress, dependencies: $dependencies, blockers: $blockers, relatedEntityIds: $relatedEntityIds, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$GoalNodeCopyWith<$Res> implements $GoalNodeCopyWith<$Res> {
  factory _$GoalNodeCopyWith(_GoalNode value, $Res Function(_GoalNode) _then) = __$GoalNodeCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, GoalStatus status, String? parentGoalId, String? workspaceId, int priority, DateTime createdAt, DateTime? completedAt, List<String> successConditions, List<String> failureConditions, DateTime? deadline, int progress, List<String> dependencies, List<String> blockers, List<String> relatedEntityIds, Map<String, dynamic> metadata
});




}
/// @nodoc
class __$GoalNodeCopyWithImpl<$Res>
    implements _$GoalNodeCopyWith<$Res> {
  __$GoalNodeCopyWithImpl(this._self, this._then);

  final _GoalNode _self;
  final $Res Function(_GoalNode) _then;

/// Create a copy of GoalNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? status = null,Object? parentGoalId = freezed,Object? workspaceId = freezed,Object? priority = null,Object? createdAt = null,Object? completedAt = freezed,Object? successConditions = null,Object? failureConditions = null,Object? deadline = freezed,Object? progress = null,Object? dependencies = null,Object? blockers = null,Object? relatedEntityIds = null,Object? metadata = null,}) {
  return _then(_GoalNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GoalStatus,parentGoalId: freezed == parentGoalId ? _self.parentGoalId : parentGoalId // ignore: cast_nullable_to_non_nullable
as String?,workspaceId: freezed == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,successConditions: null == successConditions ? _self._successConditions : successConditions // ignore: cast_nullable_to_non_nullable
as List<String>,failureConditions: null == failureConditions ? _self._failureConditions : failureConditions // ignore: cast_nullable_to_non_nullable
as List<String>,deadline: freezed == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime?,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as int,dependencies: null == dependencies ? _self._dependencies : dependencies // ignore: cast_nullable_to_non_nullable
as List<String>,blockers: null == blockers ? _self._blockers : blockers // ignore: cast_nullable_to_non_nullable
as List<String>,relatedEntityIds: null == relatedEntityIds ? _self._relatedEntityIds : relatedEntityIds // ignore: cast_nullable_to_non_nullable
as List<String>,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
