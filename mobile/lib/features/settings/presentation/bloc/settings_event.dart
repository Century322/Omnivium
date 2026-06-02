import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class SettingsLoadRequested extends SettingsEvent {
  const SettingsLoadRequested();
}

class SettingsThemeChanged extends SettingsEvent {
  final String mode;
  const SettingsThemeChanged(this.mode);
  @override
  List<Object?> get props => [mode];
}

class SettingsLocaleChanged extends SettingsEvent {
  final String locale;
  const SettingsLocaleChanged(this.locale);
  @override
  List<Object?> get props => [locale];
}

class SettingsNotificationsChanged extends SettingsEvent {
  final bool enabled;
  const SettingsNotificationsChanged(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class SettingsBiometricChanged extends SettingsEvent {
  final bool enabled;
  const SettingsBiometricChanged(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class SettingsStealthChanged extends SettingsEvent {
  final bool enabled;
  const SettingsStealthChanged(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class SettingsReadReceiptsChanged extends SettingsEvent {
  final bool enabled;
  const SettingsReadReceiptsChanged(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class SettingsTypingIndicatorsChanged extends SettingsEvent {
  final bool enabled;
  const SettingsTypingIndicatorsChanged(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class SettingsDataRetentionChanged extends SettingsEvent {
  final bool enabled;
  const SettingsDataRetentionChanged(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class SettingsAgentEnabledChanged extends SettingsEvent {
  final bool enabled;
  const SettingsAgentEnabledChanged(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class SettingsLockEnabledChanged extends SettingsEvent {
  final bool enabled;
  const SettingsLockEnabledChanged(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class SettingsAssistantLangChanged extends SettingsEvent {
  final String lang;
  const SettingsAssistantLangChanged(this.lang);
  @override
  List<Object?> get props => [lang];
}

class SettingsImageModelChanged extends SettingsEvent {
  final String model;
  const SettingsImageModelChanged(this.model);
  @override
  List<Object?> get props => [model];
}

class SettingsSttEngineChanged extends SettingsEvent {
  final String engine;
  const SettingsSttEngineChanged(this.engine);
  @override
  List<Object?> get props => [engine];
}

class SettingsTtsVoiceChanged extends SettingsEvent {
  final String voice;
  const SettingsTtsVoiceChanged(this.voice);
  @override
  List<Object?> get props => [voice];
}

class SettingsVoiceModeChanged extends SettingsEvent {
  final String mode;
  const SettingsVoiceModeChanged(this.mode);
  @override
  List<Object?> get props => [mode];
}
