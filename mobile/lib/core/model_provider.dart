import 'dart:convert';
import 'package:flutter/material.dart';
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
    tier: json['tier'] ?? 'smart',
  );
}

class ModelProvider extends ChangeNotifier {
  final AgentOrchestrator _orchestrator;
  final _secure = SecureStorageService.instance;
  bool _disposed = false;

  static const _modelsSecureKey = 'omnivium_models_secure';
  static const _activeModelKey = 'omnivium_active_model';

  final List<ModelConfig> _models = [];
  List<ModelConfig> get models => List.unmodifiable(_models);
  String? _activeModelId;
  String? get activeModelId => _activeModelId;
  ModelConfig? get activeModel =>
      _models.where((m) => m.id == _activeModelId).firstOrNull;
  String? _lastError;
  String? get lastError => _lastError;

  AgentOrchestrator get orchestrator => _orchestrator;

  ModelProvider({required AgentOrchestrator orchestrator})
    : _orchestrator = orchestrator;

  Future<void> loadModels() async {
    await _loadModelsFromBackend();
    if (_models.isEmpty) {
      await _loadModelsFromCache();
    }
    if (_activeModelId != null && _models.any((m) => m.id == _activeModelId)) {
      _activateModel(_activeModelId!);
    } else if (_models.isNotEmpty) {
      final fastModel = _models.where((m) => m.tier == 'fast').firstOrNull;
      _activateModel(fastModel?.id ?? _models.first.id);
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> refreshModels() async {
    await _loadModelsFromBackend();
    if (_activeModelId != null && !_models.any((m) => m.id == _activeModelId)) {
      if (_models.isNotEmpty) {
        _activateModel(_models.first.id);
      }
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> _loadModelsFromBackend() async {
    final proxy = ApiProxyService.instance;
    if (!proxy.isConfigured) return;
    _lastError = null;
    try {
      final uri = proxy.resolveModelsUrl();
      final response = await proxy.secureClient
          .get(
            uri,
            headers: <String, String>{
              ...proxy.buildAuthHeaders(),
              ...proxy.buildDeviceHeaders(),
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final list = body['models'] as List? ?? [];
        _models.clear();
        for (final item in list) {
          final m = item as Map<String, dynamic>;
          _models.add(
            ModelConfig(
              id: m['id'] as String,
              name: m['name'] as String,
              provider: m['provider'] as String,
              tier: m['tier'] as String? ?? 'smart',
            ),
          );
        }
        await _saveModels();
      } else {
        _lastError = 'HTTP ${response.statusCode}';
      }
    } catch (e, stackTrace) {
      _lastError = e.toString();
      AppLogger.instance.error(
        'Operation failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _loadModelsFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final secureRaw = await _secure.read(_modelsSecureKey);
    if (secureRaw != null) {
      try {
        final list = jsonDecode(secureRaw) as List;
        _models.clear();
        for (final item in list) {
          _models.add(ModelConfig.fromJson(item as Map<String, dynamic>));
        }
      } catch (e, stackTrace) {
        AppLogger.instance.error(
          'Operation failed',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
    _activeModelId = prefs.getString(_activeModelKey);
  }

  Future<void> _saveModels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_models.map((m) => m.toJson()).toList());
      await _secure.write(_modelsSecureKey, json);
      if (_activeModelId != null) {
        await prefs.setString(_activeModelKey, _activeModelId!);
      } else {
        await prefs.remove(_activeModelKey);
      }
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'Operation failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void switchModel(String id) {
    if (!_models.any((m) => m.id == id)) return;
    _activateModel(id);
    _saveModels();
    if (!_disposed) notifyListeners();
  }

  void _activateModel(String id) {
    final config = _models.where((m) => m.id == id).firstOrNull;
    if (config == null) return;
    _activeModelId = id;
    ChatService.instance.setModel(config.id);
    _orchestrator.configure(model: config.id);
    _registerSkills();
  }

  void _registerSkills() {
    final registry = _orchestrator.skillRegistry;
    registry.register(WebSearchSkill());
    final remoteSkills = RemoteConfigService.instance.getValue<List<dynamic>>(
      'skills',
    );
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
            endpoint: m['endpoint'] as String? ?? '',
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
