import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/settings_repository.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final ISettingsRepository _repository;

  SettingsBloc(this._repository) : super(const SettingsInitial()) {
    on<SettingsLoadRequested>(_onLoad);
    on<SettingsThemeChanged>(_onThemeChange);
    on<SettingsLocaleChanged>(_onLocaleChange);
    on<SettingsNotificationsChanged>(_onNotificationsChange);
    on<SettingsBiometricChanged>(_onBiometricChange);
    on<SettingsStealthChanged>(_onStealthChange);
    on<SettingsReadReceiptsChanged>(_onReadReceiptsChange);
    on<SettingsTypingIndicatorsChanged>(_onTypingIndicatorsChange);
    on<SettingsDataRetentionChanged>(_onDataRetentionChange);
    on<SettingsAgentEnabledChanged>(_onAgentEnabledChange);
    on<SettingsLockEnabledChanged>(_onLockEnabledChange);
    on<SettingsAssistantLangChanged>(_onAssistantLangChange);
    on<SettingsImageModelChanged>(_onImageModelChange);
    on<SettingsSttEngineChanged>(_onSttEngineChange);
    on<SettingsTtsVoiceChanged>(_onTtsVoiceChange);
    on<SettingsVoiceModeChanged>(_onVoiceModeChange);
  }

  Future<void> _reload(Emitter<SettingsState> emit) async {
    final result = await _repository.getSettings();
    result.fold(
      (failure) => emit(SettingsError(failure.message)),
      (settings) => emit(SettingsLoaded(settings)));
  }

  Future<void> _onLoad(SettingsLoadRequested event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    await _reload(emit);
  }

  Future<void> _onThemeChange(SettingsThemeChanged event, Emitter<SettingsState> emit) async {
    await _repository.updateThemeMode(event.mode);
    await _reload(emit);
  }

  Future<void> _onLocaleChange(SettingsLocaleChanged event, Emitter<SettingsState> emit) async {
    await _repository.updateLocale(event.locale);
    await _reload(emit);
  }

  Future<void> _onNotificationsChange(SettingsNotificationsChanged event, Emitter<SettingsState> emit) async {
    await _repository.updateNotifications(event.enabled);
    await _reload(emit);
  }

  Future<void> _onBiometricChange(SettingsBiometricChanged event, Emitter<SettingsState> emit) async {
    await _repository.updateBiometric(event.enabled);
    await _reload(emit);
  }

  Future<void> _onStealthChange(SettingsStealthChanged event, Emitter<SettingsState> emit) async {
    await _repository.updateStealthMode(event.enabled);
    await _reload(emit);
  }

  Future<void> _onReadReceiptsChange(SettingsReadReceiptsChanged event, Emitter<SettingsState> emit) async {
    await _repository.updateReadReceipts(event.enabled);
    await _reload(emit);
  }

  Future<void> _onTypingIndicatorsChange(SettingsTypingIndicatorsChanged event, Emitter<SettingsState> emit) async {
    await _repository.updateTypingIndicators(event.enabled);
    await _reload(emit);
  }

  Future<void> _onDataRetentionChange(SettingsDataRetentionChanged event, Emitter<SettingsState> emit) async {
    await _repository.updateDataRetention(event.enabled);
    await _reload(emit);
  }

  Future<void> _onAgentEnabledChange(SettingsAgentEnabledChanged event, Emitter<SettingsState> emit) async {
    await _repository.updateAgentEnabled(event.enabled);
    await _reload(emit);
  }

  Future<void> _onLockEnabledChange(SettingsLockEnabledChanged event, Emitter<SettingsState> emit) async {
    await _repository.updateLockEnabled(event.enabled);
    await _reload(emit);
  }

  Future<void> _onAssistantLangChange(SettingsAssistantLangChanged event, Emitter<SettingsState> emit) async {
    await _repository.updateAssistantLang(event.lang);
    await _reload(emit);
  }

  Future<void> _onImageModelChange(SettingsImageModelChanged event, Emitter<SettingsState> emit) async {
    await _repository.updateImageModel(event.model);
    await _reload(emit);
  }

  Future<void> _onSttEngineChange(SettingsSttEngineChanged event, Emitter<SettingsState> emit) async {
    await _repository.updateSttEngine(event.engine);
    await _reload(emit);
  }

  Future<void> _onTtsVoiceChange(SettingsTtsVoiceChanged event, Emitter<SettingsState> emit) async {
    await _repository.updateTtsVoice(event.voice);
    await _reload(emit);
  }

  Future<void> _onVoiceModeChange(SettingsVoiceModeChanged event, Emitter<SettingsState> emit) async {
    await _repository.updateVoiceMode(event.mode);
    await _reload(emit);
  }
}
