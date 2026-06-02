// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_repository.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppSettings {

 String get themeMode; String get locale; bool get notificationsEnabled; bool get biometricEnabled; bool get stealthMode; bool get readReceipts; bool get typingIndicators; String? get fontSize; bool get dataRetention; bool get agentEnabled; bool get lockEnabled; String get assistantLang; String get imageModel; String get sttEngine; String get ttsVoice; String get voiceMode;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.notificationsEnabled, notificationsEnabled) || other.notificationsEnabled == notificationsEnabled)&&(identical(other.biometricEnabled, biometricEnabled) || other.biometricEnabled == biometricEnabled)&&(identical(other.stealthMode, stealthMode) || other.stealthMode == stealthMode)&&(identical(other.readReceipts, readReceipts) || other.readReceipts == readReceipts)&&(identical(other.typingIndicators, typingIndicators) || other.typingIndicators == typingIndicators)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.dataRetention, dataRetention) || other.dataRetention == dataRetention)&&(identical(other.agentEnabled, agentEnabled) || other.agentEnabled == agentEnabled)&&(identical(other.lockEnabled, lockEnabled) || other.lockEnabled == lockEnabled)&&(identical(other.assistantLang, assistantLang) || other.assistantLang == assistantLang)&&(identical(other.imageModel, imageModel) || other.imageModel == imageModel)&&(identical(other.sttEngine, sttEngine) || other.sttEngine == sttEngine)&&(identical(other.ttsVoice, ttsVoice) || other.ttsVoice == ttsVoice)&&(identical(other.voiceMode, voiceMode) || other.voiceMode == voiceMode));
}


@override
int get hashCode => Object.hash(runtimeType,themeMode,locale,notificationsEnabled,biometricEnabled,stealthMode,readReceipts,typingIndicators,fontSize,dataRetention,agentEnabled,lockEnabled,assistantLang,imageModel,sttEngine,ttsVoice,voiceMode);

@override
String toString() {
  return 'AppSettings(themeMode: $themeMode, locale: $locale, notificationsEnabled: $notificationsEnabled, biometricEnabled: $biometricEnabled, stealthMode: $stealthMode, readReceipts: $readReceipts, typingIndicators: $typingIndicators, fontSize: $fontSize, dataRetention: $dataRetention, agentEnabled: $agentEnabled, lockEnabled: $lockEnabled, assistantLang: $assistantLang, imageModel: $imageModel, sttEngine: $sttEngine, ttsVoice: $ttsVoice, voiceMode: $voiceMode)';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 String themeMode, String locale, bool notificationsEnabled, bool biometricEnabled, bool stealthMode, bool readReceipts, bool typingIndicators, String? fontSize, bool dataRetention, bool agentEnabled, bool lockEnabled, String assistantLang, String imageModel, String sttEngine, String ttsVoice, String voiceMode
});




}
/// @nodoc
class _$AppSettingsCopyWithImpl<$Res>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? themeMode = null,Object? locale = null,Object? notificationsEnabled = null,Object? biometricEnabled = null,Object? stealthMode = null,Object? readReceipts = null,Object? typingIndicators = null,Object? fontSize = freezed,Object? dataRetention = null,Object? agentEnabled = null,Object? lockEnabled = null,Object? assistantLang = null,Object? imageModel = null,Object? sttEngine = null,Object? ttsVoice = null,Object? voiceMode = null,}) {
  return _then(_self.copyWith(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as String,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,notificationsEnabled: null == notificationsEnabled ? _self.notificationsEnabled : notificationsEnabled // ignore: cast_nullable_to_non_nullable
as bool,biometricEnabled: null == biometricEnabled ? _self.biometricEnabled : biometricEnabled // ignore: cast_nullable_to_non_nullable
as bool,stealthMode: null == stealthMode ? _self.stealthMode : stealthMode // ignore: cast_nullable_to_non_nullable
as bool,readReceipts: null == readReceipts ? _self.readReceipts : readReceipts // ignore: cast_nullable_to_non_nullable
as bool,typingIndicators: null == typingIndicators ? _self.typingIndicators : typingIndicators // ignore: cast_nullable_to_non_nullable
as bool,fontSize: freezed == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as String?,dataRetention: null == dataRetention ? _self.dataRetention : dataRetention // ignore: cast_nullable_to_non_nullable
as bool,agentEnabled: null == agentEnabled ? _self.agentEnabled : agentEnabled // ignore: cast_nullable_to_non_nullable
as bool,lockEnabled: null == lockEnabled ? _self.lockEnabled : lockEnabled // ignore: cast_nullable_to_non_nullable
as bool,assistantLang: null == assistantLang ? _self.assistantLang : assistantLang // ignore: cast_nullable_to_non_nullable
as String,imageModel: null == imageModel ? _self.imageModel : imageModel // ignore: cast_nullable_to_non_nullable
as String,sttEngine: null == sttEngine ? _self.sttEngine : sttEngine // ignore: cast_nullable_to_non_nullable
as String,ttsVoice: null == ttsVoice ? _self.ttsVoice : ttsVoice // ignore: cast_nullable_to_non_nullable
as String,voiceMode: null == voiceMode ? _self.voiceMode : voiceMode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AppSettings].
extension AppSettingsPatterns on AppSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSettings value)  $default,){
final _that = this;
switch (_that) {
case _AppSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String themeMode,  String locale,  bool notificationsEnabled,  bool biometricEnabled,  bool stealthMode,  bool readReceipts,  bool typingIndicators,  String? fontSize,  bool dataRetention,  bool agentEnabled,  bool lockEnabled,  String assistantLang,  String imageModel,  String sttEngine,  String ttsVoice,  String voiceMode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.themeMode,_that.locale,_that.notificationsEnabled,_that.biometricEnabled,_that.stealthMode,_that.readReceipts,_that.typingIndicators,_that.fontSize,_that.dataRetention,_that.agentEnabled,_that.lockEnabled,_that.assistantLang,_that.imageModel,_that.sttEngine,_that.ttsVoice,_that.voiceMode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String themeMode,  String locale,  bool notificationsEnabled,  bool biometricEnabled,  bool stealthMode,  bool readReceipts,  bool typingIndicators,  String? fontSize,  bool dataRetention,  bool agentEnabled,  bool lockEnabled,  String assistantLang,  String imageModel,  String sttEngine,  String ttsVoice,  String voiceMode)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.themeMode,_that.locale,_that.notificationsEnabled,_that.biometricEnabled,_that.stealthMode,_that.readReceipts,_that.typingIndicators,_that.fontSize,_that.dataRetention,_that.agentEnabled,_that.lockEnabled,_that.assistantLang,_that.imageModel,_that.sttEngine,_that.ttsVoice,_that.voiceMode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String themeMode,  String locale,  bool notificationsEnabled,  bool biometricEnabled,  bool stealthMode,  bool readReceipts,  bool typingIndicators,  String? fontSize,  bool dataRetention,  bool agentEnabled,  bool lockEnabled,  String assistantLang,  String imageModel,  String sttEngine,  String ttsVoice,  String voiceMode)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.themeMode,_that.locale,_that.notificationsEnabled,_that.biometricEnabled,_that.stealthMode,_that.readReceipts,_that.typingIndicators,_that.fontSize,_that.dataRetention,_that.agentEnabled,_that.lockEnabled,_that.assistantLang,_that.imageModel,_that.sttEngine,_that.ttsVoice,_that.voiceMode);case _:
  return null;

}
}

}

/// @nodoc


class _AppSettings implements AppSettings {
  const _AppSettings({this.themeMode = 'system', this.locale = 'zh', this.notificationsEnabled = true, this.biometricEnabled = false, this.stealthMode = false, this.readReceipts = true, this.typingIndicators = true, this.fontSize, this.dataRetention = true, this.agentEnabled = true, this.lockEnabled = false, this.assistantLang = 'auto', this.imageModel = 'default_model', this.sttEngine = 'system', this.ttsVoice = 'Kyrin', this.voiceMode = 'hands_free'});
  

@override@JsonKey() final  String themeMode;
@override@JsonKey() final  String locale;
@override@JsonKey() final  bool notificationsEnabled;
@override@JsonKey() final  bool biometricEnabled;
@override@JsonKey() final  bool stealthMode;
@override@JsonKey() final  bool readReceipts;
@override@JsonKey() final  bool typingIndicators;
@override final  String? fontSize;
@override@JsonKey() final  bool dataRetention;
@override@JsonKey() final  bool agentEnabled;
@override@JsonKey() final  bool lockEnabled;
@override@JsonKey() final  String assistantLang;
@override@JsonKey() final  String imageModel;
@override@JsonKey() final  String sttEngine;
@override@JsonKey() final  String ttsVoice;
@override@JsonKey() final  String voiceMode;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsCopyWith<_AppSettings> get copyWith => __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.notificationsEnabled, notificationsEnabled) || other.notificationsEnabled == notificationsEnabled)&&(identical(other.biometricEnabled, biometricEnabled) || other.biometricEnabled == biometricEnabled)&&(identical(other.stealthMode, stealthMode) || other.stealthMode == stealthMode)&&(identical(other.readReceipts, readReceipts) || other.readReceipts == readReceipts)&&(identical(other.typingIndicators, typingIndicators) || other.typingIndicators == typingIndicators)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.dataRetention, dataRetention) || other.dataRetention == dataRetention)&&(identical(other.agentEnabled, agentEnabled) || other.agentEnabled == agentEnabled)&&(identical(other.lockEnabled, lockEnabled) || other.lockEnabled == lockEnabled)&&(identical(other.assistantLang, assistantLang) || other.assistantLang == assistantLang)&&(identical(other.imageModel, imageModel) || other.imageModel == imageModel)&&(identical(other.sttEngine, sttEngine) || other.sttEngine == sttEngine)&&(identical(other.ttsVoice, ttsVoice) || other.ttsVoice == ttsVoice)&&(identical(other.voiceMode, voiceMode) || other.voiceMode == voiceMode));
}


@override
int get hashCode => Object.hash(runtimeType,themeMode,locale,notificationsEnabled,biometricEnabled,stealthMode,readReceipts,typingIndicators,fontSize,dataRetention,agentEnabled,lockEnabled,assistantLang,imageModel,sttEngine,ttsVoice,voiceMode);

@override
String toString() {
  return 'AppSettings(themeMode: $themeMode, locale: $locale, notificationsEnabled: $notificationsEnabled, biometricEnabled: $biometricEnabled, stealthMode: $stealthMode, readReceipts: $readReceipts, typingIndicators: $typingIndicators, fontSize: $fontSize, dataRetention: $dataRetention, agentEnabled: $agentEnabled, lockEnabled: $lockEnabled, assistantLang: $assistantLang, imageModel: $imageModel, sttEngine: $sttEngine, ttsVoice: $ttsVoice, voiceMode: $voiceMode)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 String themeMode, String locale, bool notificationsEnabled, bool biometricEnabled, bool stealthMode, bool readReceipts, bool typingIndicators, String? fontSize, bool dataRetention, bool agentEnabled, bool lockEnabled, String assistantLang, String imageModel, String sttEngine, String ttsVoice, String voiceMode
});




}
/// @nodoc
class __$AppSettingsCopyWithImpl<$Res>
    implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? themeMode = null,Object? locale = null,Object? notificationsEnabled = null,Object? biometricEnabled = null,Object? stealthMode = null,Object? readReceipts = null,Object? typingIndicators = null,Object? fontSize = freezed,Object? dataRetention = null,Object? agentEnabled = null,Object? lockEnabled = null,Object? assistantLang = null,Object? imageModel = null,Object? sttEngine = null,Object? ttsVoice = null,Object? voiceMode = null,}) {
  return _then(_AppSettings(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as String,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,notificationsEnabled: null == notificationsEnabled ? _self.notificationsEnabled : notificationsEnabled // ignore: cast_nullable_to_non_nullable
as bool,biometricEnabled: null == biometricEnabled ? _self.biometricEnabled : biometricEnabled // ignore: cast_nullable_to_non_nullable
as bool,stealthMode: null == stealthMode ? _self.stealthMode : stealthMode // ignore: cast_nullable_to_non_nullable
as bool,readReceipts: null == readReceipts ? _self.readReceipts : readReceipts // ignore: cast_nullable_to_non_nullable
as bool,typingIndicators: null == typingIndicators ? _self.typingIndicators : typingIndicators // ignore: cast_nullable_to_non_nullable
as bool,fontSize: freezed == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as String?,dataRetention: null == dataRetention ? _self.dataRetention : dataRetention // ignore: cast_nullable_to_non_nullable
as bool,agentEnabled: null == agentEnabled ? _self.agentEnabled : agentEnabled // ignore: cast_nullable_to_non_nullable
as bool,lockEnabled: null == lockEnabled ? _self.lockEnabled : lockEnabled // ignore: cast_nullable_to_non_nullable
as bool,assistantLang: null == assistantLang ? _self.assistantLang : assistantLang // ignore: cast_nullable_to_non_nullable
as String,imageModel: null == imageModel ? _self.imageModel : imageModel // ignore: cast_nullable_to_non_nullable
as String,sttEngine: null == sttEngine ? _self.sttEngine : sttEngine // ignore: cast_nullable_to_non_nullable
as String,ttsVoice: null == ttsVoice ? _self.ttsVoice : ttsVoice // ignore: cast_nullable_to_non_nullable
as String,voiceMode: null == voiceMode ? _self.voiceMode : voiceMode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
