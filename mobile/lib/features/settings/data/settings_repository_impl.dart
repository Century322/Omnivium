import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/errors/failures.dart';
import '../domain/settings_repository.dart';

class SettingsRepositoryImpl implements ISettingsRepository {
  AppSettings _cache = const AppSettings();

  @override
  Future<Either<Failure, AppSettings>> getSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cache = AppSettings(
        themeMode: prefs.getString('omnivium_theme_mode') ?? 'system',
        locale: prefs.getString('omnivium_locale') ?? 'zh',
        notificationsEnabled: prefs.getBool('omnivium_notifications') ?? true,
        biometricEnabled: prefs.getBool('omnivium_biometric') ?? false,
        stealthMode: prefs.getBool('omnivium_stealth_mode') ?? false,
        readReceipts: prefs.getBool('omnivium_read_receipts') ?? true,
        typingIndicators: prefs.getBool('omnivium_typing_indicators') ?? true,
        dataRetention: prefs.getBool('omnivium_data_retention') ?? true,
        agentEnabled: prefs.getBool('omnivium_agent_enabled') ?? true,
        lockEnabled: prefs.getBool('lock_enabled') ?? false,
        assistantLang: prefs.getString('omnivium_assistant_lang') ?? 'auto',
        imageModel: prefs.getString('omnivium_image_model') ?? 'default_model',
        sttEngine: prefs.getString('omnivium_stt_engine') ?? 'system',
        ttsVoice: prefs.getString('omnivium_tts_voice') ?? 'Kyrin',
        voiceMode: prefs.getString('omnivium_voice_mode') ?? 'hands_free');
      return Right(_cache);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateSettings(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('omnivium_theme_mode', settings.themeMode);
      await prefs.setString('omnivium_locale', settings.locale);
      await prefs.setBool('omnivium_notifications', settings.notificationsEnabled);
      await prefs.setBool('omnivium_biometric', settings.biometricEnabled);
      await prefs.setBool('omnivium_stealth_mode', settings.stealthMode);
      await prefs.setBool('omnivium_read_receipts', settings.readReceipts);
      await prefs.setBool('omnivium_typing_indicators', settings.typingIndicators);
      await prefs.setBool('omnivium_data_retention', settings.dataRetention);
      await prefs.setBool('omnivium_agent_enabled', settings.agentEnabled);
      await prefs.setBool('lock_enabled', settings.lockEnabled);
      await prefs.setString('omnivium_assistant_lang', settings.assistantLang);
      await prefs.setString('omnivium_image_model', settings.imageModel);
      await prefs.setString('omnivium_stt_engine', settings.sttEngine);
      await prefs.setString('omnivium_tts_voice', settings.ttsVoice);
      await prefs.setString('omnivium_voice_mode', settings.voiceMode);
      _cache = settings;
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateThemeMode(String mode) async {
    _cache = _cache.copyWith(themeMode: mode);
    return _savePref('omnivium_theme_mode', mode);
  }

  @override
  Future<Either<Failure, void>> updateLocale(String locale) async {
    _cache = _cache.copyWith(locale: locale);
    return _savePref('omnivium_locale', locale);
  }

  @override
  Future<Either<Failure, void>> updateNotifications(bool enabled) async {
    _cache = _cache.copyWith(notificationsEnabled: enabled);
    return _savePref('omnivium_notifications', enabled);
  }

  @override
  Future<Either<Failure, void>> updateBiometric(bool enabled) async {
    _cache = _cache.copyWith(biometricEnabled: enabled);
    return _savePref('omnivium_biometric', enabled);
  }

  @override
  Future<Either<Failure, void>> updateStealthMode(bool enabled) async {
    _cache = _cache.copyWith(stealthMode: enabled);
    return _savePref('omnivium_stealth_mode', enabled);
  }

  @override
  Future<Either<Failure, void>> updateReadReceipts(bool enabled) async {
    _cache = _cache.copyWith(readReceipts: enabled);
    return _savePref('omnivium_read_receipts', enabled);
  }

  @override
  Future<Either<Failure, void>> updateTypingIndicators(bool enabled) async {
    _cache = _cache.copyWith(typingIndicators: enabled);
    return _savePref('omnivium_typing_indicators', enabled);
  }

  @override
  Future<Either<Failure, void>> updateDataRetention(bool enabled) async {
    _cache = _cache.copyWith(dataRetention: enabled);
    return _savePref('omnivium_data_retention', enabled);
  }

  @override
  Future<Either<Failure, void>> updateAgentEnabled(bool enabled) async {
    _cache = _cache.copyWith(agentEnabled: enabled);
    return _savePref('omnivium_agent_enabled', enabled);
  }

  @override
  Future<Either<Failure, void>> updateLockEnabled(bool enabled) async {
    _cache = _cache.copyWith(lockEnabled: enabled);
    return _savePref('lock_enabled', enabled);
  }

  @override
  Future<Either<Failure, void>> updateAssistantLang(String lang) async {
    _cache = _cache.copyWith(assistantLang: lang);
    return _savePref('omnivium_assistant_lang', lang);
  }

  @override
  Future<Either<Failure, void>> updateImageModel(String model) async {
    _cache = _cache.copyWith(imageModel: model);
    return _savePref('omnivium_image_model', model);
  }

  @override
  Future<Either<Failure, void>> updateSttEngine(String engine) async {
    _cache = _cache.copyWith(sttEngine: engine);
    return _savePref('omnivium_stt_engine', engine);
  }

  @override
  Future<Either<Failure, void>> updateTtsVoice(String voice) async {
    _cache = _cache.copyWith(ttsVoice: voice);
    return _savePref('omnivium_tts_voice', voice);
  }

  @override
  Future<Either<Failure, void>> updateVoiceMode(String mode) async {
    _cache = _cache.copyWith(voiceMode: mode);
    return _savePref('omnivium_voice_mode', mode);
  }

  Future<Either<Failure, void>> _savePref(String key, Object value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is bool) await prefs.setBool(key, value);
      if (value is String) await prefs.setString(key, value);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}
