import 'dart:convert';
import 'app_logger.dart';
import 'api_proxy_service.dart';
import 'database_service.dart';

class ABTestVariant {
  final String id;
  final String name;
  final double weight;
  final Map<String, dynamic>? payload;

  const ABTestVariant({
    required this.id,
    required this.name,
    this.weight = 1.0,
    this.payload,
  });

  factory ABTestVariant.fromJson(Map<String, dynamic> json) => ABTestVariant(
    id: json['id'] as String,
    name: json['name'] as String,
    weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
    payload: json['payload'] as Map<String, dynamic>?,
  );
}

class ABTestExperiment {
  final String id;
  final String name;
  final List<ABTestVariant> variants;
  final bool isActive;

  const ABTestExperiment({
    required this.id,
    required this.name,
    required this.variants,
    this.isActive = true,
  });

  factory ABTestExperiment.fromJson(Map<String, dynamic> json) => ABTestExperiment(
    id: json['id'] as String,
    name: json['name'] as String,
    isActive: json['is_active'] as bool? ?? true,
    variants: (json['variants'] as List?)
        ?.map((v) => ABTestVariant.fromJson(v as Map<String, dynamic>))
        .toList() ?? [],
  );
}

class ABTestService {
  static final ABTestService _instance = ABTestService._();
  static ABTestService get instance => _instance;
  ABTestService._();

  static const _cacheKey = 'ab_test_assignments';
  static const _experimentsCacheKey = 'ab_test_experiments';

  final Map<String, String> _assignments = {};
  final Map<String, ABTestExperiment> _experiments = {};
  String? _userId;

  Future<void> init() async {
    await _loadCachedAssignments();
    await _loadCachedExperiments();
    await _fetchExperiments();
  }

  void setUserId(String? userId) {
    if (_userId != userId) {
      _userId = userId;
      _assignments.clear();
      _loadCachedAssignments();
    }
  }

  Future<void> setUserIdAsync(String? userId) async {
    if (_userId != userId) {
      _userId = userId;
      _assignments.clear();
      await _loadCachedAssignments();
    }
  }

  String getVariant(String experimentId, {String? defaultVariant}) {
    final experiment = _experiments[experimentId];
    if (experiment == null || !experiment.isActive) {
      return defaultVariant ?? 'control';
    }

    if (_assignments.containsKey(experimentId)) {
      return _assignments[experimentId]!;
    }

    final variant = _assignVariant(experiment);
    _assignments[experimentId] = variant.id;
    _saveCachedAssignments();
    _reportAssignment(experimentId, variant.id);
    return variant.id;
  }

  T? getVariantPayload<T>(String experimentId, String key, {T? defaultValue}) {
    final variantId = getVariant(experimentId);
    final experiment = _experiments[experimentId];
    if (experiment == null) return defaultValue;

    final variant = experiment.variants.where((v) => v.id == variantId).firstOrNull;
    if (variant?.payload == null) return defaultValue;

    final value = variant!.payload![key];
    if (value is T) return value;
    return defaultValue;
  }

  bool isFeatureEnabled(String featureKey, {bool defaultValue = false}) {
    return getVariantPayload<bool>(featureKey, 'enabled', defaultValue: defaultValue) ?? defaultValue;
  }

  ABTestVariant _assignVariant(ABTestExperiment experiment) {
    final bucketKey = '${_userId}_${experiment.id}';
    final hash = bucketKey.hashCode;
    final normalizedHash = (hash & 0x7FFFFFFF) % 10000 / 10000.0;

    final totalWeight = experiment.variants.fold(0.0, (sum, v) => sum + v.weight);
    var cumulative = 0.0;

    for (final variant in experiment.variants) {
      cumulative += variant.weight;
      if (normalizedHash * totalWeight <= cumulative) return variant;
    }

    return experiment.variants.first;
  }

  Future<void> _fetchExperiments() async {
    try {
      final proxy = ApiProxyService.instance;
      if (!proxy.isConfigured) return;

      final uri = Uri.parse('${proxy.backendUrl}/config/ab-tests');
      final response = await proxy.secureClient.get(uri, headers: {
        ...proxy.buildAuthHeaders(),
        ...proxy.buildDeviceHeaders(),
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final experiments = body['experiments'] as List? ?? [];

        _experiments.clear();
        for (final exp in experiments) {
          final experiment = ABTestExperiment.fromJson(exp as Map<String, dynamic>);
          _experiments[experiment.id] = experiment;
        }

        await _saveCachedExperiments();
      }
    } catch (e) {
      AppLogger.instance.info('Failed to fetch A/B test experiments: $e');
    }
  }

  void _reportAssignment(String experimentId, String variantId) {
    try {
      final proxy = ApiProxyService.instance;
      if (!proxy.isConfigured) return;

      proxy.proxyRequest(
        path: '/analytics/ab-assignment',
        body: {
          'experiment_id': experimentId,
          'variant_id': variantId,
          'user_id': _userId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ).catchError((_) => <String, dynamic>{});
    } catch (_) {}
  }

  Future<void> _loadCachedAssignments() async {
    try {
      final db = DatabaseService.instance;
      if (!db.isInitialized) return;
      final raw = db.getCache(_cacheKey);
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _assignments.addAll(data.map((k, v) => MapEntry(k, v.toString())));
    } catch (_) {}
  }

  Future<void> _saveCachedAssignments() async {
    try {
      final db = DatabaseService.instance;
      if (!db.isInitialized) return;
      await db.putCache(_cacheKey, jsonEncode(_assignments));
    } catch (_) {}
  }

  Future<void> _loadCachedExperiments() async {
    try {
      final db = DatabaseService.instance;
      if (!db.isInitialized) return;
      final raw = db.getCache(_experimentsCacheKey);
      if (raw == null) return;
      final data = jsonDecode(raw) as List;
      _experiments.clear();
      for (final item in data) {
        final experiment = ABTestExperiment.fromJson(item as Map<String, dynamic>);
        _experiments[experiment.id] = experiment;
      }
    } catch (_) {}
  }

  Future<void> _saveCachedExperiments() async {
    try {
      final db = DatabaseService.instance;
      if (!db.isInitialized) return;
      final data = _experiments.values.map((e) => {
        'id': e.id, 'name': e.name, 'is_active': e.isActive,
        'variants': e.variants.map((v) => {
          'id': v.id, 'name': v.name, 'weight': v.weight,
          'payload': v.payload,
        }).toList(),
      }).toList();
      await db.putCache(_experimentsCacheKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<void> refresh() async {
    await _fetchExperiments();
  }
}
