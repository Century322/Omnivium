// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'agent_entities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AgentModel {

 String get id; String get name; String get provider; String get tier; bool get isActive;
/// Create a copy of AgentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentModelCopyWith<AgentModel> get copyWith => _$AgentModelCopyWithImpl<AgentModel>(this as AgentModel, _$identity);

  /// Serializes this AgentModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,provider,tier,isActive);

@override
String toString() {
  return 'AgentModel(id: $id, name: $name, provider: $provider, tier: $tier, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $AgentModelCopyWith<$Res>  {
  factory $AgentModelCopyWith(AgentModel value, $Res Function(AgentModel) _then) = _$AgentModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String provider, String tier, bool isActive
});




}
/// @nodoc
class _$AgentModelCopyWithImpl<$Res>
    implements $AgentModelCopyWith<$Res> {
  _$AgentModelCopyWithImpl(this._self, this._then);

  final AgentModel _self;
  final $Res Function(AgentModel) _then;

/// Create a copy of AgentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? provider = null,Object? tier = null,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentModel].
extension AgentModelPatterns on AgentModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentModel value)  $default,){
final _that = this;
switch (_that) {
case _AgentModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentModel value)?  $default,){
final _that = this;
switch (_that) {
case _AgentModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String provider,  String tier,  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentModel() when $default != null:
return $default(_that.id,_that.name,_that.provider,_that.tier,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String provider,  String tier,  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _AgentModel():
return $default(_that.id,_that.name,_that.provider,_that.tier,_that.isActive);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String provider,  String tier,  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _AgentModel() when $default != null:
return $default(_that.id,_that.name,_that.provider,_that.tier,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentModel implements AgentModel {
  const _AgentModel({required this.id, required this.name, required this.provider, required this.tier, this.isActive = false});
  factory _AgentModel.fromJson(Map<String, dynamic> json) => _$AgentModelFromJson(json);

@override final  String id;
@override final  String name;
@override final  String provider;
@override final  String tier;
@override@JsonKey() final  bool isActive;

/// Create a copy of AgentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentModelCopyWith<_AgentModel> get copyWith => __$AgentModelCopyWithImpl<_AgentModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,provider,tier,isActive);

@override
String toString() {
  return 'AgentModel(id: $id, name: $name, provider: $provider, tier: $tier, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$AgentModelCopyWith<$Res> implements $AgentModelCopyWith<$Res> {
  factory _$AgentModelCopyWith(_AgentModel value, $Res Function(_AgentModel) _then) = __$AgentModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String provider, String tier, bool isActive
});




}
/// @nodoc
class __$AgentModelCopyWithImpl<$Res>
    implements _$AgentModelCopyWith<$Res> {
  __$AgentModelCopyWithImpl(this._self, this._then);

  final _AgentModel _self;
  final $Res Function(_AgentModel) _then;

/// Create a copy of AgentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? provider = null,Object? tier = null,Object? isActive = null,}) {
  return _then(_AgentModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$AgentSkill {

 String get id; String get name; String get description; bool get enabled;
/// Create a copy of AgentSkill
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentSkillCopyWith<AgentSkill> get copyWith => _$AgentSkillCopyWithImpl<AgentSkill>(this as AgentSkill, _$identity);

  /// Serializes this AgentSkill to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentSkill&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,enabled);

@override
String toString() {
  return 'AgentSkill(id: $id, name: $name, description: $description, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class $AgentSkillCopyWith<$Res>  {
  factory $AgentSkillCopyWith(AgentSkill value, $Res Function(AgentSkill) _then) = _$AgentSkillCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, bool enabled
});




}
/// @nodoc
class _$AgentSkillCopyWithImpl<$Res>
    implements $AgentSkillCopyWith<$Res> {
  _$AgentSkillCopyWithImpl(this._self, this._then);

  final AgentSkill _self;
  final $Res Function(AgentSkill) _then;

/// Create a copy of AgentSkill
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? enabled = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentSkill].
extension AgentSkillPatterns on AgentSkill {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentSkill value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentSkill() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentSkill value)  $default,){
final _that = this;
switch (_that) {
case _AgentSkill():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentSkill value)?  $default,){
final _that = this;
switch (_that) {
case _AgentSkill() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  bool enabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentSkill() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.enabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  bool enabled)  $default,) {final _that = this;
switch (_that) {
case _AgentSkill():
return $default(_that.id,_that.name,_that.description,_that.enabled);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  bool enabled)?  $default,) {final _that = this;
switch (_that) {
case _AgentSkill() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.enabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentSkill implements AgentSkill {
  const _AgentSkill({required this.id, required this.name, required this.description, this.enabled = true});
  factory _AgentSkill.fromJson(Map<String, dynamic> json) => _$AgentSkillFromJson(json);

@override final  String id;
@override final  String name;
@override final  String description;
@override@JsonKey() final  bool enabled;

/// Create a copy of AgentSkill
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentSkillCopyWith<_AgentSkill> get copyWith => __$AgentSkillCopyWithImpl<_AgentSkill>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentSkillToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentSkill&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,enabled);

@override
String toString() {
  return 'AgentSkill(id: $id, name: $name, description: $description, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class _$AgentSkillCopyWith<$Res> implements $AgentSkillCopyWith<$Res> {
  factory _$AgentSkillCopyWith(_AgentSkill value, $Res Function(_AgentSkill) _then) = __$AgentSkillCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, bool enabled
});




}
/// @nodoc
class __$AgentSkillCopyWithImpl<$Res>
    implements _$AgentSkillCopyWith<$Res> {
  __$AgentSkillCopyWithImpl(this._self, this._then);

  final _AgentSkill _self;
  final $Res Function(_AgentSkill) _then;

/// Create a copy of AgentSkill
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? enabled = null,}) {
  return _then(_AgentSkill(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
