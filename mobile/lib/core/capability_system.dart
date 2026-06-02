import 'dart:convert';
import 'app_logger.dart';
import 'database_service.dart';
import 'omni_model.dart';
import 'action_executor.dart';

enum CapabilityCategory {
  information,
  communication,
  creation,
  modification,
  management,
  automation,
  media,
  commerce,
}

class Capability {
  final String id;
  final String name;
  final String description;
  final CapabilityCategory category;
  final Set<String> applicableObjectTypes;
  final Map<String, dynamic> paramSchema;
  final bool isDestructive;

  const Capability({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.applicableObjectTypes = const {},
    this.paramSchema = const {},
    this.isDestructive = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category.name,
    'applicableObjectTypes': applicableObjectTypes.toList(),
    'paramSchema': paramSchema,
    'isDestructive': isDestructive,
  };

  factory Capability.fromJson(Map<String, dynamic> json) => Capability(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    category: CapabilityCategory.values.firstWhere(
      (e) => e.name == json['category'],
      orElse: () => CapabilityCategory.information,
    ),
    applicableObjectTypes: (json['applicableObjectTypes'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toSet() ??
        {},
    paramSchema: (json['paramSchema'] as Map<String, dynamic>?) ?? {},
    isDestructive: json['isDestructive'] as bool? ?? false,
  );
}

class CapabilityBinding {
  final String capabilityId;
  final String providerName;
  final String actionId;
  final Set<String> objectTypes;
  final double priority;
  final Map<String, String> paramMapping;

  const CapabilityBinding({
    required this.capabilityId,
    required this.providerName,
    required this.actionId,
    this.objectTypes = const {},
    this.priority = 1.0,
    this.paramMapping = const {},
  });

  Map<String, dynamic> toJson() => {
    'capabilityId': capabilityId,
    'providerName': providerName,
    'actionId': actionId,
    'objectTypes': objectTypes.toList(),
    'priority': priority,
    'paramMapping': paramMapping,
  };

  factory CapabilityBinding.fromJson(Map<String, dynamic> json) =>
      CapabilityBinding(
        capabilityId: json['capabilityId'] as String,
        providerName: json['providerName'] as String,
        actionId: json['actionId'] as String,
        objectTypes: (json['objectTypes'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toSet() ??
            {},
        priority: (json['priority'] as num?)?.toDouble() ?? 1.0,
        paramMapping: (json['paramMapping'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as String)) ??
            {},
      );
}

class CapabilityUsageRecord {
  final String capabilityId;
  final String providerName;
  final bool success;
  final Duration duration;
  final DateTime timestamp;

  const CapabilityUsageRecord({
    required this.capabilityId,
    required this.providerName,
    required this.success,
    required this.duration,
    required this.timestamp,
  });
}

class CapabilityRegistry {
  final Map<String, Capability> _capabilities = {};
  final Map<String, List<CapabilityBinding>> _bindings = {};
  final Map<String, List<CapabilityUsageRecord>> _usageHistory = {};
  final DatabaseService _db;
  bool _isInitialized = false;

  static const _capabilitiesKey = 'capability_definitions';
  static const _bindingsKey = 'capability_bindings';
  static const _maxUsageHistory = 200;

  CapabilityRegistry(this._db);

  bool get isInitialized => _isInitialized;
  int get capabilityCount => _capabilities.length;
  int get bindingCount => _bindings.values.fold(0, (sum, list) => sum + list.length);

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final capJson = await _db.getCache(_capabilitiesKey);
      if (capJson != null) {
        final list = jsonDecode(capJson) as List<dynamic>;
        for (final e in list) {
          final cap = Capability.fromJson(e as Map<String, dynamic>);
          _capabilities[cap.id] = cap;
        }
      }
      final bindJson = await _db.getCache(_bindingsKey);
      if (bindJson != null) {
        final map = jsonDecode(bindJson) as Map<String, dynamic>;
        for (final entry in map.entries) {
          final list = (entry.value as List<dynamic>)
              .map((e) => CapabilityBinding.fromJson(e as Map<String, dynamic>))
              .toList();
          _bindings[entry.key] = list;
        }
      }
      _isInitialized = true;
      AppLogger.instance.info(
        'CapabilityRegistry initialized: ${_capabilities.length} capabilities, ${_bindings.values.fold(0, (sum, list) => sum + list.length)} bindings',
      );
    } catch (e, st) {
      AppLogger.instance.error('CapabilityRegistry init failed', error: e, stackTrace: st);
      _isInitialized = true;
    }
  }

  void registerCapability(Capability capability) {
    _capabilities[capability.id] = capability;
  }

  void registerBinding(CapabilityBinding binding) {
    _bindings.putIfAbsent(binding.capabilityId, () => []).add(binding);
  }

  Capability? getCapability(String id) => _capabilities[id];

  List<Capability> get allCapabilities => _capabilities.values.toList();

  List<Capability> getCapabilitiesForType(String objectType) => _capabilities.values
      .where((c) => c.applicableObjectTypes.isEmpty || c.applicableObjectTypes.contains(objectType))
      .toList();

  List<Capability> getCapabilitiesByCategory(CapabilityCategory category) =>
      _capabilities.values.where((c) => c.category == category).toList();

  List<CapabilityBinding> getBindings(String capabilityId) =>
      _bindings[capabilityId] ?? [];

  CapabilityBinding? resolveProvider(
    String capabilityId, {
    String? objectType,
    Map<String, dynamic>? context,
  }) {
    final bindings = _bindings[capabilityId];
    if (bindings == null || bindings.isEmpty) return null;

    var candidates = bindings.toList();

    if (objectType != null) {
      final typeSpecific = candidates
          .where((b) => b.objectTypes.isEmpty || b.objectTypes.contains(objectType))
          .toList();
      if (typeSpecific.isNotEmpty) {
        candidates = typeSpecific;
      }
    }

    candidates.sort((a, b) {
      final aScore = _scoreBinding(a, objectType, context);
      final bScore = _scoreBinding(b, objectType, context);
      return bScore.compareTo(aScore);
    });

    return candidates.first;
  }

  double _scoreBinding(
    CapabilityBinding binding,
    String? objectType,
    Map<String, dynamic>? context,
  ) {
    double score = binding.priority;

    if (objectType != null && binding.objectTypes.contains(objectType)) {
      score += 2.0;
    }

    final history = _usageHistory[binding.capabilityId]
            ?.where((r) => r.providerName == binding.providerName)
            .toList() ??
        [];
    if (history.isNotEmpty) {
      final recentSuccesses = history
          .where((r) => r.success && r.timestamp.isAfter(DateTime.now().subtract(const Duration(hours: 24))))
          .length;
      final recentFailures = history
          .where((r) => !r.success && r.timestamp.isAfter(DateTime.now().subtract(const Duration(hours: 24))))
          .length;
      score += (recentSuccesses - recentFailures) * 0.5;

      final avgDuration = history
          .where((r) => r.success)
          .map((r) => r.duration.inMilliseconds)
          .fold<int>(0, (a, b) => a + b) /
          (history.where((r) => r.success).length.toDouble().clamp(1, double.infinity));
      if (avgDuration < 1000) score += 0.5;
      if (avgDuration < 500) score += 0.5;
    }

    return score;
  }

  void recordUsage(CapabilityUsageRecord record) {
    _usageHistory.putIfAbsent(record.capabilityId, () => []).add(record);
    final list = _usageHistory[record.capabilityId]!;
    if (list.length > _maxUsageHistory) {
      _usageHistory[record.capabilityId] = list.sublist(list.length - _maxUsageHistory);
    }
  }

  String buildCapabilityContext({String? objectType, String? workspaceId}) {
    final buffer = StringBuffer();
    buffer.writeln('[Available Capabilities]');

    final capabilities = objectType != null
        ? getCapabilitiesForType(objectType)
        : allCapabilities;

    if (capabilities.isEmpty) {
      buffer.writeln('No capabilities available.');
      return buffer.toString();
    }

    final byCategory = <CapabilityCategory, List<Capability>>{};
    for (final cap in capabilities) {
      byCategory.putIfAbsent(cap.category, () => []).add(cap);
    }

    for (final entry in byCategory.entries) {
      buffer.writeln('\n${_categoryLabel(entry.key)}:');
      for (final cap in entry.value) {
        final bindings = getBindings(cap.id);
        final providerNames = bindings.map((b) => b.providerName).toList();
        final objectTypes = cap.applicableObjectTypes.isNotEmpty
            ? ' (${cap.applicableObjectTypes.join(', ')})'
            : '';
        buffer.writeln('  ${cap.name}$objectTypes: ${cap.description}');
        if (providerNames.isNotEmpty && providerNames.length <= 3) {
          buffer.writeln('    Providers: ${providerNames.join(', ')}');
        }
        if (cap.isDestructive) {
          buffer.writeln('    ⚠ Destructive');
        }
      }
    }

    buffer.writeln('\nUsage: Express intent as capability, e.g., "Search for X", "Share Y to Z", "Create project W"');
    buffer.writeln('The system will automatically select the best provider.');

    return buffer.toString();
  }

  String _categoryLabel(CapabilityCategory category) {
    switch (category) {
      case CapabilityCategory.information:
        return 'Information';
      case CapabilityCategory.communication:
        return 'Communication';
      case CapabilityCategory.creation:
        return 'Creation';
      case CapabilityCategory.modification:
        return 'Modification';
      case CapabilityCategory.management:
        return 'Management';
      case CapabilityCategory.automation:
        return 'Automation';
      case CapabilityCategory.media:
        return 'Media';
      case CapabilityCategory.commerce:
        return 'Commerce';
    }
  }

  Map<String, dynamic> getCapabilitySummary() {
    final byCategory = <String, int>{};
    for (final cap in _capabilities.values) {
      byCategory[cap.category.name] = (byCategory[cap.category.name] ?? 0) + 1;
    }
    return {
      'totalCapabilities': _capabilities.length,
      'totalBindings': _bindings.values.fold(0, (sum, list) => sum + list.length),
      'byCategory': byCategory,
    };
  }

  Future<void> persist() async {
    try {
      await _db.putCache(
        _capabilitiesKey,
        jsonEncode(_capabilities.values.map((e) => e.toJson()).toList()),
      );
      await _db.putCache(
        _bindingsKey,
        jsonEncode(_bindings.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()))),
      );
    } catch (e, st) {
      AppLogger.instance.error('CapabilityRegistry persist failed', error: e, stackTrace: st);
    }
  }

  Future<void> clear() async {
    _capabilities.clear();
    _bindings.clear();
    _usageHistory.clear();
    await persist();
  }
}

class CapabilityExecutor {
  final CapabilityRegistry _registry;
  final ActionExecutor _actionExecutor;

  CapabilityExecutor(this._registry, this._actionExecutor);

  Future<ActionResult> executeCapability(
    String capabilityId, {
    String? objectId,
    String? objectType,
    Map<String, dynamic> params = const {},
    Map<String, dynamic>? context,
  }) async {
    final binding = _registry.resolveProvider(
      capabilityId,
      objectType: objectType,
      context: context,
    );

    if (binding == null) {
      return ActionResult.failure(
        capabilityId,
        objectId ?? 'unknown',
        'No provider found for capability: $capabilityId',
      );
    }

    final resolvedParams = _resolveParams(params, binding.paramMapping);

    final registry = OmniObjectRegistry.instance;
    OmniObject? target;
    if (objectId != null) {
      target = registry.getObject(objectId);
    }
    if (target == null && objectType != null) {
      final objects = registry.getObjectsByType(
        OmniObjectType.values.firstWhere(
          (e) => e.name == objectType,
          orElse: () => OmniObjectType.message,
        ),
      );
      if (objects.isNotEmpty) target = objects.first;
    }

    if (target == null) {
      return ActionResult.failure(
        binding.actionId,
        objectId ?? 'unknown',
        'No target object found for capability: $capabilityId',
      );
    }

    final action = registry
        .getActionsForObject(target)
        .where((a) => a.id == binding.actionId)
        .firstOrNull;

    if (action == null) {
      return ActionResult.failure(
        binding.actionId,
        target.id,
        'Action ${binding.actionId} not found for object ${target.id}',
      );
    }

    final stopwatch = Stopwatch()..start();
    ActionResult result;
    try {
      result = await _actionExecutor.execute(action, target, resolvedParams);
    } catch (e) {
      result = ActionResult.failure(binding.actionId, target.id, e.toString());
    }
    stopwatch.stop();

    _registry.recordUsage(CapabilityUsageRecord(
      capabilityId: capabilityId,
      providerName: binding.providerName,
      success: result.success,
      duration: stopwatch.elapsed,
      timestamp: DateTime.now(),
    ));

    return result;
  }

  Map<String, dynamic> _resolveParams(
    Map<String, dynamic> params,
    Map<String, String> paramMapping,
  ) {
    if (paramMapping.isEmpty) return params;
    final resolved = <String, dynamic>{};
    for (final entry in params.entries) {
      final mappedKey = paramMapping[entry.key] ?? entry.key;
      resolved[mappedKey] = entry.value;
    }
    return resolved;
  }

  List<String> planCapabilities(String intent, {String? objectType}) {
    final capabilities = objectType != null
        ? _registry.getCapabilitiesForType(objectType)
        : _registry.allCapabilities;

    final lower = intent.toLowerCase();
    final matched = <String>[];

    for (final cap in capabilities) {
      if (_capabilityMatchesIntent(cap, lower)) {
        matched.add(cap.id);
      }
    }

    return matched;
  }

  bool _capabilityMatchesIntent(Capability cap, String lowerIntent) {
    if (lowerIntent.contains(cap.name.toLowerCase())) return true;
    if (lowerIntent.contains(cap.id.toLowerCase())) return true;
    final keywords = cap.description.toLowerCase().split(RegExp(r'[,，\s]+'));
    for (final kw in keywords) {
      if (kw.length >= 3 && lowerIntent.contains(kw)) return true;
    }
    return false;
  }
}
