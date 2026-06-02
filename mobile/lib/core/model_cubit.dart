import 'di/app_di.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger.dart';
import 'remote_config_service.dart';
import 'api_proxy_service.dart';
import 'providers/ai_provider.dart';
import 'agent/agent_orchestrator.dart';
import '../modules/search/web_search_skill.dart';
import 'skills/skill.dart';
import 'secure_storage_service.dart';

class ModelConfig {
  final String id;
  final String name;
  final String provider;
  final String tier;
  const ModelConfig({
    required this.id,
    required this.name,
    required this.provider,
    this.tier = 'smart',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'provider': provider,
    'tier': tier,
  };

  factory ModelConfig.fromJson(Map<String, dynamic> json) => ModelConfig(
    id: json['id'],
    name: json['name'],
    provider: json['provider'] ?? '',
    tier: json['tier'] ?? 'smart');
}

class ModelState {
  final List<ModelConfig> models;
  final String? activeModelId;
  final String? lastError;

  const ModelState({
    this.models = const [],
    this.activeModelId,
    this.lastError,
  });

  ModelConfig? get activeModel =>
      models.where((m) => m.id == activeModelId).firstOrNull;

  ModelState copyWith({
    List<ModelConfig>? models,
    String? activeModelId,
    String? lastError,
  }) {
    return ModelState(
      models: models ?? this.models,
      activeModelId: activeModelId ?? this.activeModelId,
      lastError: lastError ?? this.lastError);
  }
}

class ModelCubit extends Cubit<ModelState> {
  ModelCubit({required AgentOrchestrator orchestrator})
    : _orchestrator = orchestrator,
      super(const ModelState());

  final AgentOrchestrator _orchestrator;
  final _secure = getIt<SecureStorageService>();

  static const _modelsSecureKey = 'omnivium_models_secure';
  static const _activeModelKey = 'omnivium_active_model';

  List<ModelConfig> get models => state.models;
  String? get activeModelId => state.activeModelId;
  ModelConfig? get activeModel => state.activeModel;
  String? get lastError => state.lastError;
  AgentOrchestrator get orchestrator => _orchestrator;

  Future<void> loadModels() async {
    await _loadModelsFromBackend();
    if (state.models.isEmpty) {
      await _loadModelsFromCache();
    }
    final activeId = state.activeModelId;
    if (activeId != null && state.models.any((m) => m.id == activeId)) {
      _activateModel(activeId);
    } else if (state.models.isNotEmpty) {
      final fastModel = state.models.where((m) => m.tier == 'fast').firstOrNull;
      _activateModel(fastModel?.id ?? state.models.first.id);
    }
    emit(state);
  }

  Future<void> refreshModels() async {
    await _loadModelsFromBackend();
    if (state.activeModelId != null &&
        !state.models.any((m) => m.id == state.activeModelId)) {
      if (state.models.isNotEmpty) {
        _activateModel(state.models.first.id);
      }
    }
    emit(state);
  }

  Future<void> _loadModelsFromBackend() async {
    final proxy = getIt<ApiProxyService>();
    if (!proxy.isConfigured) {
      emit(state.copyWith(lastError: 'Waiting for sign-in…'));
      return;
    }
    emit(state.copyWith(lastError: null));
    try {
      final uri = proxy.resolveModelsUrl();
      final response = await proxy.secureClient
          .get(
            uri,
            headers: <String, String>{
              ...proxy.buildAuthHeaders(),
              ...proxy.buildDeviceHeaders(),
            })
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final list = body['models'] as List<dynamic>? ?? [];
        final models = <ModelConfig>[];
        for (final item in list) {
          final m = item as Map<String, dynamic>;
          models.add(
            ModelConfig(
              id: m['id'] as String,
              name: m['name'] as String,
              provider: m['provider'] as String,
              tier: m['tier'] as String? ?? 'smart'));
        }
        emit(state.copyWith(models: models));
        await _saveModels();
      } else {
        emit(state.copyWith(lastError: 'HTTP ${response.statusCode}'));
      }
    } catch (e, stackTrace) {
      emit(state.copyWith(lastError: e.toString()));
      AppLogger.instance.error(
        'Model load from backend failed',
        error: e,
        stackTrace: stackTrace);
      _scheduleModelRetry();
    }
  }

  Timer? _modelRetryTimer;
  int _modelRetryCount = 0;
  static const _maxModelRetries = 3;

  void _scheduleModelRetry() {
    if (_modelRetryCount >= _maxModelRetries) return;
    _modelRetryTimer?.cancel();
    final delay = Duration(seconds: 5 * (_modelRetryCount + 1));
    _modelRetryCount++;
    _modelRetryTimer = Timer(delay, () async {
      await _loadModelsFromBackend();
      if (state.lastError == null) {
        _modelRetryCount = 0;
        emit(state);
      }
    });
  }

  Future<void> _loadModelsFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final secureRaw = await _secure.read(_modelsSecureKey);
    if (secureRaw != null) {
      try {
        final list = jsonDecode(secureRaw) as List<dynamic>;
        final models = <ModelConfig>[];
        for (final item in list) {
          models.add(ModelConfig.fromJson(item as Map<String, dynamic>));
        }
        emit(state.copyWith(models: models));
      } catch (e, stackTrace) {
        AppLogger.instance.error('App error', error: e, stackTrace: stackTrace);
      }
    }
    final activeId = prefs.getString(_activeModelKey);
    if (activeId != null) {
      emit(state.copyWith(activeModelId: activeId));
    }
  }

  Future<void> _saveModels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(state.models.map((m) => m.toJson()).toList());
      await _secure.write(_modelsSecureKey, json);
      final saveId = state.activeModelId;
      if (saveId != null) {
        await prefs.setString(_activeModelKey, saveId);
      } else {
        await prefs.remove(_activeModelKey);
      }
    } catch (e, stackTrace) {
      AppLogger.instance.error('App error', error: e, stackTrace: stackTrace);
    }
  }

  void switchModel(String id) {
    if (!state.models.any((m) => m.id == id)) return;
    _activateModel(id);
    _saveModels();
    emit(state);
  }

  void _activateModel(String id) {
    final config = state.models.where((m) => m.id == id).firstOrNull;
    if (config == null) return;
    emit(state.copyWith(activeModelId: id));
    getIt<ChatService>().setModel(config.id);
    _orchestrator.configure(model: config.id);
    _registerSkills();
  }

  void _registerSkills() {
    final registry = _orchestrator.skillRegistry;
    registry.register(WebSearchSkill());
    final remoteSkills = getIt<RemoteConfigService>().getValue<List<dynamic>>(
      'skills');
    if (remoteSkills != null) {
      for (final s in remoteSkills) {
        final m = s as Map<String, dynamic>;
        final id = m['id'] as String? ?? '';
        if (id == 'web_search') continue;
        registry.register(
          RemoteSkill(
            id: id,
            name: m['name'] as String? ?? id,
            description: m['description'] as String? ?? '',
            endpoint: m['endpoint'] as String? ?? ''));
      }
    }
  }

  @override
  Future<void> close() {
    _modelRetryTimer?.cancel();
    return super.close();
  }
}
