import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

part 'settings_repository.freezed.dart';

@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default('system') String themeMode,
    @Default('zh') String locale,
    @Default(true) bool notificationsEnabled,
    @Default(false) bool biometricEnabled,
    @Default(false) bool stealthMode,
    @Default(true) bool readReceipts,
    @Default(true) bool typingIndicators,
    String? fontSize,
    @Default(true) bool dataRetention,
    @Default(true) bool agentEnabled,
    @Default(false) bool lockEnabled,
    @Default('auto') String assistantLang,
    @Default('default_model') String imageModel,
    @Default('system') String sttEngine,
    @Default('Kyrin') String ttsVoice,
    @Default('hands_free') String voiceMode,
  }) = _AppSettings;
}

abstract class ISettingsRepository {
  Future<Either<Failure, AppSettings>> getSettings();
  Future<Either<Failure, void>> updateSettings(AppSettings settings);
  Future<Either<Failure, void>> updateThemeMode(String mode);
  Future<Either<Failure, void>> updateLocale(String locale);
  Future<Either<Failure, void>> updateNotifications(bool enabled);
  Future<Either<Failure, void>> updateBiometric(bool enabled);
  Future<Either<Failure, void>> updateStealthMode(bool enabled);
  Future<Either<Failure, void>> updateReadReceipts(bool enabled);
  Future<Either<Failure, void>> updateTypingIndicators(bool enabled);
  Future<Either<Failure, void>> updateDataRetention(bool enabled);
  Future<Either<Failure, void>> updateAgentEnabled(bool enabled);
  Future<Either<Failure, void>> updateLockEnabled(bool enabled);
  Future<Either<Failure, void>> updateAssistantLang(String lang);
  Future<Either<Failure, void>> updateImageModel(String model);
  Future<Either<Failure, void>> updateSttEngine(String engine);
  Future<Either<Failure, void>> updateTtsVoice(String voice);
  Future<Either<Failure, void>> updateVoiceMode(String mode);
}
