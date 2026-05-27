import 'app_logger.dart';
import 'dart:convert';
import 'api_proxy_service.dart';
import 'database_service.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._();
  static RemoteConfigService get instance => _instance;
  RemoteConfigService._();

  static const _cacheKey = 'remote_config_cache';
  static const _uiSchemaKey = 'remote_ui_schemas';
  static const _cacheTtl = Duration(hours: 1);

  Map<String, dynamic> _config = {};
  Map<String, Map<String, dynamic>> _uiSchemas = {};
  DateTime? _lastFetch;

  Map<String, dynamic> get config => _config;
  Map<String, Map<String, dynamic>> get uiSchemas => _uiSchemas;

  bool get _isCacheStale {
    final lastFetch = _lastFetch;
    return lastFetch == null || DateTime.now().difference(lastFetch) > _cacheTtl;
  }

  bool getFeatureFlag(String key, {bool defaultValue = false}) {
    final features = _config['features'] as Map<String, dynamic>?;
    if (features == null) return defaultValue;
    return features[key] as bool? ?? defaultValue;
  }

  T? getValue<T>(String key, {T? defaultValue}) {
    final value = _config[key];
    if (value is T) return value;
    return defaultValue;
  }

  int getInt(String key, {int defaultValue = 0}) {
    return getValue<int>(key, defaultValue: defaultValue) ?? defaultValue;
  }

  double getDouble(String key, {double defaultValue = 0.0}) {
    return getValue<double>(key, defaultValue: defaultValue) ?? defaultValue;
  }

  int get maxMemories => getInt('max_memories', defaultValue: 500);
  int get maxCacheSize => getInt('max_cache_size', defaultValue: 1000);
  int get maxInputLength => getInt('max_input_length', defaultValue: 32000);
  int get maxNotifications => getInt('max_notifications', defaultValue: 100);
  double get memorySimilarityThreshold =>
      getDouble('memory_similarity_threshold', defaultValue: 0.3);
  int get maxMemoryResults => getInt('max_memory_results', defaultValue: 5);

  Map<String, dynamic>? getUISchema(String screenId) {
    return _uiSchemas[screenId];
  }

  Future<void> init() async {
    await _loadFromCache();
    if (_isCacheStale) {
      await fetch();
    }
  }

  Future<void> fetch() async {
    final proxy = ApiProxyService.instance;
    if (!proxy.isConfigured) return;

    try {
      final uri = Uri.parse('${proxy.backendUrl}/config');
      final response = await proxy.secureClient
          .get(
            uri,
            headers: {
              ...proxy.buildAuthHeaders(),
              ...proxy.buildDeviceHeaders(),
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        _config = body['config'] as Map<String, dynamic>? ?? {};
        _lastFetch = DateTime.now();
        await _saveToCache();
      }
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'App error',
        error: e,
        stackTrace: stackTrace,
      );
    }

    try {
      final uri = Uri.parse('${proxy.backendUrl}/ui/schemas');
      final response = await proxy.secureClient
          .get(
            uri,
            headers: {
              ...proxy.buildAuthHeaders(),
              ...proxy.buildDeviceHeaders(),
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final schemas = body['schemas'] as Map<String, dynamic>? ?? {};
        _uiSchemas = schemas.map(
          (k, v) => MapEntry(k, v as Map<String, dynamic>),
        );
        await _saveSchemasToCache();
      }
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'App error',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _loadFromCache() async {
    final db = DatabaseService.instance;
    final raw = db.getCache(_cacheKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _config = data['config'] as Map<String, dynamic>? ?? {};
        final schemasRaw = data['schemas'] as Map<String, dynamic>?;
        if (schemasRaw != null) {
          _uiSchemas = schemasRaw.map(
            (k, v) => MapEntry(k, v as Map<String, dynamic>),
          );
        }
      } catch (e, stackTrace) {
        AppLogger.instance.error(
          'App error',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    final schemaRaw = db.getCache(_uiSchemaKey);
    if (schemaRaw != null) {
      try {
        final data = jsonDecode(schemaRaw) as Map<String, dynamic>;
        _uiSchemas = data.map((k, v) => MapEntry(k, v as Map<String, dynamic>));
      } catch (e, stackTrace) {
        AppLogger.instance.error(
          'App error',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<void> _saveToCache() async {
    final db = DatabaseService.instance;
    await db.putCache(
      _cacheKey,
      jsonEncode({
        'config': _config,
        'schemas': _uiSchemas,
        'lastFetch': _lastFetch?.toIso8601String(),
      }),
    );
  }

  Future<void> _saveSchemasToCache() async {
    final db = DatabaseService.instance;
    await db.putCache(_uiSchemaKey, jsonEncode(_uiSchemas));
  }

  bool shouldRefresh() {
    final lastFetch = _lastFetch;
    if (lastFetch == null) return true;
    return DateTime.now().difference(lastFetch) > const Duration(hours: 1);
  }
}
