// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'runtime_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RuntimeMetadata {

 String get schema; int get version; String get traceId; String get spanId; Map<String, String> get tags;
/// Create a copy of RuntimeMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RuntimeMetadataCopyWith<RuntimeMetadata> get copyWith => _$RuntimeMetadataCopyWithImpl<RuntimeMetadata>(this as RuntimeMetadata, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RuntimeMetadata&&(identical(other.schema, schema) || other.schema == schema)&&(identical(other.version, version) || other.version == version)&&(identical(other.traceId, traceId) || other.traceId == traceId)&&(identical(other.spanId, spanId) || other.spanId == spanId)&&const DeepCollectionEquality().equals(other.tags, tags));
}


@override
int get hashCode => Object.hash(runtimeType,schema,version,traceId,spanId,const DeepCollectionEquality().hash(tags));

@override
String toString() {
  return 'RuntimeMetadata(schema: $schema, version: $version, traceId: $traceId, spanId: $spanId, tags: $tags)';
}


}

/// @nodoc
abstract mixin class $RuntimeMetadataCopyWith<$Res>  {
  factory $RuntimeMetadataCopyWith(RuntimeMetadata value, $Res Function(RuntimeMetadata) _then) = _$RuntimeMetadataCopyWithImpl;
@useResult
$Res call({
 String schema, int version, String traceId, String spanId, Map<String, String> tags
});




}
/// @nodoc
class _$RuntimeMetadataCopyWithImpl<$Res>
    implements $RuntimeMetadataCopyWith<$Res> {
  _$RuntimeMetadataCopyWithImpl(this._self, this._then);

  final RuntimeMetadata _self;
  final $Res Function(RuntimeMetadata) _then;

/// Create a copy of RuntimeMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schema = null,Object? version = null,Object? traceId = null,Object? spanId = null,Object? tags = null,}) {
  return _then(_self.copyWith(
schema: null == schema ? _self.schema : schema // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,traceId: null == traceId ? _self.traceId : traceId // ignore: cast_nullable_to_non_nullable
as String,spanId: null == spanId ? _self.spanId : spanId // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [RuntimeMetadata].
extension RuntimeMetadataPatterns on RuntimeMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RuntimeMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RuntimeMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RuntimeMetadata value)  $default,){
final _that = this;
switch (_that) {
case _RuntimeMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RuntimeMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _RuntimeMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String schema,  int version,  String traceId,  String spanId,  Map<String, String> tags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RuntimeMetadata() when $default != null:
return $default(_that.schema,_that.version,_that.traceId,_that.spanId,_that.tags);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String schema,  int version,  String traceId,  String spanId,  Map<String, String> tags)  $default,) {final _that = this;
switch (_that) {
case _RuntimeMetadata():
return $default(_that.schema,_that.version,_that.traceId,_that.spanId,_that.tags);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String schema,  int version,  String traceId,  String spanId,  Map<String, String> tags)?  $default,) {final _that = this;
switch (_that) {
case _RuntimeMetadata() when $default != null:
return $default(_that.schema,_that.version,_that.traceId,_that.spanId,_that.tags);case _:
  return null;

}
}

}

/// @nodoc


class _RuntimeMetadata extends RuntimeMetadata {
  const _RuntimeMetadata({this.schema = 'omnivium.runtime.v1', this.version = 1, required this.traceId, required this.spanId, final  Map<String, String> tags = const <String, String>{}}): _tags = tags,super._();
  

@override@JsonKey() final  String schema;
@override@JsonKey() final  int version;
@override final  String traceId;
@override final  String spanId;
 final  Map<String, String> _tags;
@override@JsonKey() Map<String, String> get tags {
  if (_tags is EqualUnmodifiableMapView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_tags);
}


/// Create a copy of RuntimeMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RuntimeMetadataCopyWith<_RuntimeMetadata> get copyWith => __$RuntimeMetadataCopyWithImpl<_RuntimeMetadata>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RuntimeMetadata&&(identical(other.schema, schema) || other.schema == schema)&&(identical(other.version, version) || other.version == version)&&(identical(other.traceId, traceId) || other.traceId == traceId)&&(identical(other.spanId, spanId) || other.spanId == spanId)&&const DeepCollectionEquality().equals(other._tags, _tags));
}


@override
int get hashCode => Object.hash(runtimeType,schema,version,traceId,spanId,const DeepCollectionEquality().hash(_tags));

@override
String toString() {
  return 'RuntimeMetadata(schema: $schema, version: $version, traceId: $traceId, spanId: $spanId, tags: $tags)';
}


}

/// @nodoc
abstract mixin class _$RuntimeMetadataCopyWith<$Res> implements $RuntimeMetadataCopyWith<$Res> {
  factory _$RuntimeMetadataCopyWith(_RuntimeMetadata value, $Res Function(_RuntimeMetadata) _then) = __$RuntimeMetadataCopyWithImpl;
@override @useResult
$Res call({
 String schema, int version, String traceId, String spanId, Map<String, String> tags
});




}
/// @nodoc
class __$RuntimeMetadataCopyWithImpl<$Res>
    implements _$RuntimeMetadataCopyWith<$Res> {
  __$RuntimeMetadataCopyWithImpl(this._self, this._then);

  final _RuntimeMetadata _self;
  final $Res Function(_RuntimeMetadata) _then;

/// Create a copy of RuntimeMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schema = null,Object? version = null,Object? traceId = null,Object? spanId = null,Object? tags = null,}) {
  return _then(_RuntimeMetadata(
schema: null == schema ? _self.schema : schema // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,traceId: null == traceId ? _self.traceId : traceId // ignore: cast_nullable_to_non_nullable
as String,spanId: null == spanId ? _self.spanId : spanId // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on
