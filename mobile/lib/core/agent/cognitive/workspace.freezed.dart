// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workspace.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MemoryTopic {

 String get id; String get subspaceId; String get name; DateTime get lastActiveAt;
/// Create a copy of MemoryTopic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemoryTopicCopyWith<MemoryTopic> get copyWith => _$MemoryTopicCopyWithImpl<MemoryTopic>(this as MemoryTopic, _$identity);

  /// Serializes this MemoryTopic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemoryTopic&&(identical(other.id, id) || other.id == id)&&(identical(other.subspaceId, subspaceId) || other.subspaceId == subspaceId)&&(identical(other.name, name) || other.name == name)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subspaceId,name,lastActiveAt);

@override
String toString() {
  return 'MemoryTopic(id: $id, subspaceId: $subspaceId, name: $name, lastActiveAt: $lastActiveAt)';
}


}

/// @nodoc
abstract mixin class $MemoryTopicCopyWith<$Res>  {
  factory $MemoryTopicCopyWith(MemoryTopic value, $Res Function(MemoryTopic) _then) = _$MemoryTopicCopyWithImpl;
@useResult
$Res call({
 String id, String subspaceId, String name, DateTime lastActiveAt
});




}
/// @nodoc
class _$MemoryTopicCopyWithImpl<$Res>
    implements $MemoryTopicCopyWith<$Res> {
  _$MemoryTopicCopyWithImpl(this._self, this._then);

  final MemoryTopic _self;
  final $Res Function(MemoryTopic) _then;

/// Create a copy of MemoryTopic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? subspaceId = null,Object? name = null,Object? lastActiveAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,subspaceId: null == subspaceId ? _self.subspaceId : subspaceId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,lastActiveAt: null == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MemoryTopic].
extension MemoryTopicPatterns on MemoryTopic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemoryTopic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemoryTopic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemoryTopic value)  $default,){
final _that = this;
switch (_that) {
case _MemoryTopic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemoryTopic value)?  $default,){
final _that = this;
switch (_that) {
case _MemoryTopic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String subspaceId,  String name,  DateTime lastActiveAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemoryTopic() when $default != null:
return $default(_that.id,_that.subspaceId,_that.name,_that.lastActiveAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String subspaceId,  String name,  DateTime lastActiveAt)  $default,) {final _that = this;
switch (_that) {
case _MemoryTopic():
return $default(_that.id,_that.subspaceId,_that.name,_that.lastActiveAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String subspaceId,  String name,  DateTime lastActiveAt)?  $default,) {final _that = this;
switch (_that) {
case _MemoryTopic() when $default != null:
return $default(_that.id,_that.subspaceId,_that.name,_that.lastActiveAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemoryTopic implements MemoryTopic {
  const _MemoryTopic({required this.id, required this.subspaceId, required this.name, required this.lastActiveAt});
  factory _MemoryTopic.fromJson(Map<String, dynamic> json) => _$MemoryTopicFromJson(json);

@override final  String id;
@override final  String subspaceId;
@override final  String name;
@override final  DateTime lastActiveAt;

/// Create a copy of MemoryTopic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemoryTopicCopyWith<_MemoryTopic> get copyWith => __$MemoryTopicCopyWithImpl<_MemoryTopic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemoryTopicToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemoryTopic&&(identical(other.id, id) || other.id == id)&&(identical(other.subspaceId, subspaceId) || other.subspaceId == subspaceId)&&(identical(other.name, name) || other.name == name)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subspaceId,name,lastActiveAt);

@override
String toString() {
  return 'MemoryTopic(id: $id, subspaceId: $subspaceId, name: $name, lastActiveAt: $lastActiveAt)';
}


}

/// @nodoc
abstract mixin class _$MemoryTopicCopyWith<$Res> implements $MemoryTopicCopyWith<$Res> {
  factory _$MemoryTopicCopyWith(_MemoryTopic value, $Res Function(_MemoryTopic) _then) = __$MemoryTopicCopyWithImpl;
@override @useResult
$Res call({
 String id, String subspaceId, String name, DateTime lastActiveAt
});




}
/// @nodoc
class __$MemoryTopicCopyWithImpl<$Res>
    implements _$MemoryTopicCopyWith<$Res> {
  __$MemoryTopicCopyWithImpl(this._self, this._then);

  final _MemoryTopic _self;
  final $Res Function(_MemoryTopic) _then;

/// Create a copy of MemoryTopic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? subspaceId = null,Object? name = null,Object? lastActiveAt = null,}) {
  return _then(_MemoryTopic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,subspaceId: null == subspaceId ? _self.subspaceId : subspaceId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,lastActiveAt: null == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$MemorySubspace {

 String get id; String get workspaceId; String get name; DateTime get lastActiveAt;
/// Create a copy of MemorySubspace
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemorySubspaceCopyWith<MemorySubspace> get copyWith => _$MemorySubspaceCopyWithImpl<MemorySubspace>(this as MemorySubspace, _$identity);

  /// Serializes this MemorySubspace to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemorySubspace&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.name, name) || other.name == name)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workspaceId,name,lastActiveAt);

@override
String toString() {
  return 'MemorySubspace(id: $id, workspaceId: $workspaceId, name: $name, lastActiveAt: $lastActiveAt)';
}


}

/// @nodoc
abstract mixin class $MemorySubspaceCopyWith<$Res>  {
  factory $MemorySubspaceCopyWith(MemorySubspace value, $Res Function(MemorySubspace) _then) = _$MemorySubspaceCopyWithImpl;
@useResult
$Res call({
 String id, String workspaceId, String name, DateTime lastActiveAt
});




}
/// @nodoc
class _$MemorySubspaceCopyWithImpl<$Res>
    implements $MemorySubspaceCopyWith<$Res> {
  _$MemorySubspaceCopyWithImpl(this._self, this._then);

  final MemorySubspace _self;
  final $Res Function(MemorySubspace) _then;

/// Create a copy of MemorySubspace
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workspaceId = null,Object? name = null,Object? lastActiveAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,lastActiveAt: null == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MemorySubspace].
extension MemorySubspacePatterns on MemorySubspace {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemorySubspace value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemorySubspace() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemorySubspace value)  $default,){
final _that = this;
switch (_that) {
case _MemorySubspace():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemorySubspace value)?  $default,){
final _that = this;
switch (_that) {
case _MemorySubspace() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String workspaceId,  String name,  DateTime lastActiveAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemorySubspace() when $default != null:
return $default(_that.id,_that.workspaceId,_that.name,_that.lastActiveAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String workspaceId,  String name,  DateTime lastActiveAt)  $default,) {final _that = this;
switch (_that) {
case _MemorySubspace():
return $default(_that.id,_that.workspaceId,_that.name,_that.lastActiveAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String workspaceId,  String name,  DateTime lastActiveAt)?  $default,) {final _that = this;
switch (_that) {
case _MemorySubspace() when $default != null:
return $default(_that.id,_that.workspaceId,_that.name,_that.lastActiveAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemorySubspace implements MemorySubspace {
  const _MemorySubspace({required this.id, required this.workspaceId, required this.name, required this.lastActiveAt});
  factory _MemorySubspace.fromJson(Map<String, dynamic> json) => _$MemorySubspaceFromJson(json);

@override final  String id;
@override final  String workspaceId;
@override final  String name;
@override final  DateTime lastActiveAt;

/// Create a copy of MemorySubspace
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemorySubspaceCopyWith<_MemorySubspace> get copyWith => __$MemorySubspaceCopyWithImpl<_MemorySubspace>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemorySubspaceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemorySubspace&&(identical(other.id, id) || other.id == id)&&(identical(other.workspaceId, workspaceId) || other.workspaceId == workspaceId)&&(identical(other.name, name) || other.name == name)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workspaceId,name,lastActiveAt);

@override
String toString() {
  return 'MemorySubspace(id: $id, workspaceId: $workspaceId, name: $name, lastActiveAt: $lastActiveAt)';
}


}

/// @nodoc
abstract mixin class _$MemorySubspaceCopyWith<$Res> implements $MemorySubspaceCopyWith<$Res> {
  factory _$MemorySubspaceCopyWith(_MemorySubspace value, $Res Function(_MemorySubspace) _then) = __$MemorySubspaceCopyWithImpl;
@override @useResult
$Res call({
 String id, String workspaceId, String name, DateTime lastActiveAt
});




}
/// @nodoc
class __$MemorySubspaceCopyWithImpl<$Res>
    implements _$MemorySubspaceCopyWith<$Res> {
  __$MemorySubspaceCopyWithImpl(this._self, this._then);

  final _MemorySubspace _self;
  final $Res Function(_MemorySubspace) _then;

/// Create a copy of MemorySubspace
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workspaceId = null,Object? name = null,Object? lastActiveAt = null,}) {
  return _then(_MemorySubspace(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspaceId: null == workspaceId ? _self.workspaceId : workspaceId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,lastActiveAt: null == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$MemoryWorkspace {

 String get id; String get name; MemoryDomain get domain; MemoryLifecycle get lifecycle; DateTime get lastActiveAt;
/// Create a copy of MemoryWorkspace
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemoryWorkspaceCopyWith<MemoryWorkspace> get copyWith => _$MemoryWorkspaceCopyWithImpl<MemoryWorkspace>(this as MemoryWorkspace, _$identity);

  /// Serializes this MemoryWorkspace to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemoryWorkspace&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.domain, domain) || other.domain == domain)&&(identical(other.lifecycle, lifecycle) || other.lifecycle == lifecycle)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,domain,lifecycle,lastActiveAt);

@override
String toString() {
  return 'MemoryWorkspace(id: $id, name: $name, domain: $domain, lifecycle: $lifecycle, lastActiveAt: $lastActiveAt)';
}


}

/// @nodoc
abstract mixin class $MemoryWorkspaceCopyWith<$Res>  {
  factory $MemoryWorkspaceCopyWith(MemoryWorkspace value, $Res Function(MemoryWorkspace) _then) = _$MemoryWorkspaceCopyWithImpl;
@useResult
$Res call({
 String id, String name, MemoryDomain domain, MemoryLifecycle lifecycle, DateTime lastActiveAt
});




}
/// @nodoc
class _$MemoryWorkspaceCopyWithImpl<$Res>
    implements $MemoryWorkspaceCopyWith<$Res> {
  _$MemoryWorkspaceCopyWithImpl(this._self, this._then);

  final MemoryWorkspace _self;
  final $Res Function(MemoryWorkspace) _then;

/// Create a copy of MemoryWorkspace
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? domain = null,Object? lifecycle = null,Object? lastActiveAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,domain: null == domain ? _self.domain : domain // ignore: cast_nullable_to_non_nullable
as MemoryDomain,lifecycle: null == lifecycle ? _self.lifecycle : lifecycle // ignore: cast_nullable_to_non_nullable
as MemoryLifecycle,lastActiveAt: null == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MemoryWorkspace].
extension MemoryWorkspacePatterns on MemoryWorkspace {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemoryWorkspace value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemoryWorkspace() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemoryWorkspace value)  $default,){
final _that = this;
switch (_that) {
case _MemoryWorkspace():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemoryWorkspace value)?  $default,){
final _that = this;
switch (_that) {
case _MemoryWorkspace() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  MemoryDomain domain,  MemoryLifecycle lifecycle,  DateTime lastActiveAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemoryWorkspace() when $default != null:
return $default(_that.id,_that.name,_that.domain,_that.lifecycle,_that.lastActiveAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  MemoryDomain domain,  MemoryLifecycle lifecycle,  DateTime lastActiveAt)  $default,) {final _that = this;
switch (_that) {
case _MemoryWorkspace():
return $default(_that.id,_that.name,_that.domain,_that.lifecycle,_that.lastActiveAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  MemoryDomain domain,  MemoryLifecycle lifecycle,  DateTime lastActiveAt)?  $default,) {final _that = this;
switch (_that) {
case _MemoryWorkspace() when $default != null:
return $default(_that.id,_that.name,_that.domain,_that.lifecycle,_that.lastActiveAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemoryWorkspace extends MemoryWorkspace {
  const _MemoryWorkspace({required this.id, required this.name, this.domain = MemoryDomain.project, this.lifecycle = MemoryLifecycle.active, required this.lastActiveAt}): super._();
  factory _MemoryWorkspace.fromJson(Map<String, dynamic> json) => _$MemoryWorkspaceFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  MemoryDomain domain;
@override@JsonKey() final  MemoryLifecycle lifecycle;
@override final  DateTime lastActiveAt;

/// Create a copy of MemoryWorkspace
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemoryWorkspaceCopyWith<_MemoryWorkspace> get copyWith => __$MemoryWorkspaceCopyWithImpl<_MemoryWorkspace>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemoryWorkspaceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemoryWorkspace&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.domain, domain) || other.domain == domain)&&(identical(other.lifecycle, lifecycle) || other.lifecycle == lifecycle)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,domain,lifecycle,lastActiveAt);

@override
String toString() {
  return 'MemoryWorkspace(id: $id, name: $name, domain: $domain, lifecycle: $lifecycle, lastActiveAt: $lastActiveAt)';
}


}

/// @nodoc
abstract mixin class _$MemoryWorkspaceCopyWith<$Res> implements $MemoryWorkspaceCopyWith<$Res> {
  factory _$MemoryWorkspaceCopyWith(_MemoryWorkspace value, $Res Function(_MemoryWorkspace) _then) = __$MemoryWorkspaceCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, MemoryDomain domain, MemoryLifecycle lifecycle, DateTime lastActiveAt
});




}
/// @nodoc
class __$MemoryWorkspaceCopyWithImpl<$Res>
    implements _$MemoryWorkspaceCopyWith<$Res> {
  __$MemoryWorkspaceCopyWithImpl(this._self, this._then);

  final _MemoryWorkspace _self;
  final $Res Function(_MemoryWorkspace) _then;

/// Create a copy of MemoryWorkspace
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? domain = null,Object? lifecycle = null,Object? lastActiveAt = null,}) {
  return _then(_MemoryWorkspace(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,domain: null == domain ? _self.domain : domain // ignore: cast_nullable_to_non_nullable
as MemoryDomain,lifecycle: null == lifecycle ? _self.lifecycle : lifecycle // ignore: cast_nullable_to_non_nullable
as MemoryLifecycle,lastActiveAt: null == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
