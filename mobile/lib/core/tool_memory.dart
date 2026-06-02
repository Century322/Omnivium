import 'dart:convert';
import 'database_service.dart';
import 'app_logger.dart';

class ToolUsageRecord {
  final String toolId;
  final String capabilityId;
  final bool success;
  final int durationMs;
  final DateTime timestamp;
  final String? error;
  final Map<String, dynamic> context;

  const ToolUsageRecord({
    required this.toolId,
    required this.capabilityId,
    required this.success,
    this.durationMs = 0,
    required this.timestamp,
    this.error,
    this.context = const {},
  });

  Map<String, dynamic> toJson() => {
    'toolId': toolId,
    'capabilityId': capabilityId,
    'success': success,
    'durationMs': durationMs,
    'timestamp': timestamp.toIso8601String(),
    if (error != null) 'error': error,
    'context': context,
  };

  factory ToolUsageRecord.fromJson(Map<String, dynamic> json) => ToolUsageRecord(
    toolId: json['toolId'] as String,
    capabilityId: json['capabilityId'] as String? ?? '',
    success: json['success'] as bool? ?? false,
    durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
    timestamp: DateTime.parse(json['timestamp'] as String),
    error: json['error'] as String?,
    context: (json['context'] as Map<String, dynamic>?) ?? {},
  );
}

class ToolStats {
  final String toolId;
  final int totalUses;
  final int successCount;
  final int failureCount;
  final double successRate;
  final double avgDurationMs;
  final DateTime? lastUsed;

  const ToolStats({
    required this.toolId,
    this.totalUses = 0,
    this.successCount = 0,
    this.failureCount = 0,
    this.successRate = 0,
    this.avgDurationMs = 0,
    this.lastUsed,
  });

  double get score {
    if (totalUses == 0) return 50;
    final successWeight = successRate * 40;
    final frequencyWeight = (totalUses.clamp(0, 100) / 100) * 30;
    final recencyWeight = lastUsed != null
        ? (DateTime.now().difference(lastUsed!).inDays.clamp(0, 30) / 30) * 30
        : 0;
    return (100 - recencyWeight) * 0.3 + successWeight * 0.5 + frequencyWeight * 0.2;
  }

  Map<String, dynamic> toJson() => {
    'toolId': toolId,
    'totalUses': totalUses,
    'successCount': successCount,
    'failureCount': failureCount,
    'successRate': successRate,
    'avgDurationMs': avgDurationMs,
    if (lastUsed != null) 'lastUsed': lastUsed!.toIso8601String(),
    'score': score,
  };
}

class ToolMemory {
  static const _usageKey = 'tool_usage_history';

  final DatabaseService _db;
  List<ToolUsageRecord> _history = [];
  bool _initialized = false;
  bool get isInitialized => _initialized;

  ToolMemory(this._db);

  Future<void> init() async {
    if (_initialized) return;
    try {
      final json = await _db.getCache(_usageKey);
      if (json != null) {
        final list = jsonDecode(json) as List<dynamic>;
        _history = list.map((e) => ToolUsageRecord.fromJson(e as Map<String, dynamic>)).toList();
        if (_history.length > 500) {
          _history = _history.sublist(_history.length - 500);
        }
      }
      _initialized = true;
    } catch (e, st) {
      AppLogger.instance.error('ToolMemory init failed', error: e, stackTrace: st);
    }
  }

  Future<void> _persist() async {
    try {
      await _db.putCache(_usageKey, jsonEncode(_history.map((r) => r.toJson()).toList()));
    } catch (e, st) {
      AppLogger.instance.error('ToolMemory persist failed', error: e, stackTrace: st);
    }
  }

  Future<void> record(ToolUsageRecord record) async {
    _history.add(record);
    if (_history.length > 500) {
      _history = _history.sublist(_history.length - 500);
    }
    await _persist();
  }

  ToolStats getStats(String toolId) {
    final records = _history.where((r) => r.toolId == toolId).toList();
    if (records.isEmpty) return ToolStats(toolId: toolId);

    final successRecords = records.where((r) => r.success).toList();
    final totalDuration = records.fold<int>(0, (sum, r) => sum + r.durationMs);

    return ToolStats(
      toolId: toolId,
      totalUses: records.length,
      successCount: successRecords.length,
      failureCount: records.length - successRecords.length,
      successRate: successRecords.length / records.length * 100,
      avgDurationMs: records.isEmpty ? 0 : totalDuration / records.length,
      lastUsed: records.last.timestamp,
    );
  }

  List<ToolStats> getAllStats() {
    final toolIds = _history.map((r) => r.toolId).toSet();
    return toolIds.map((id) => getStats(id)).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
  }

  List<ToolStats> getStatsForDomain(String domain) {
    final domainRecords = _history.where((r) =>
        (r.context['domain'] as String?) == domain).toList();
    final toolIds = domainRecords.map((r) => r.toolId).toSet();
    return toolIds.map((id) {
      final records = domainRecords.where((r) => r.toolId == id).toList();
      final successRecords = records.where((r) => r.success).toList();
      final totalDuration = records.fold<int>(0, (sum, r) => sum + r.durationMs);
      return ToolStats(
        toolId: id,
        totalUses: records.length,
        successCount: successRecords.length,
        failureCount: records.length - successRecords.length,
        successRate: records.isEmpty ? 0 : successRecords.length / records.length * 100,
        avgDurationMs: records.isEmpty ? 0 : totalDuration / records.length,
        lastUsed: records.last.timestamp,
      );
    }).toList()..sort((a, b) => b.score.compareTo(a.score));
  }

  List<String> rankToolsForContext(String context, {int limit = 5}) {
    final allStats = getAllStats();
    final contextLower = context.toLowerCase();

    final matching = <ToolStats>[];
    final other = <ToolStats>[];

    for (final stat in allStats) {
      final records = _history.where((r) => r.toolId == stat.toolId);
      final hasContextMatch = records.any((r) {
        final ctx = r.context;
        return ctx.values.any((v) =>
            v.toString().toLowerCase().contains(contextLower));
      });
      if (hasContextMatch) {
        matching.add(stat);
      } else {
        other.add(stat);
      }
    }

    matching.sort((a, b) => b.score.compareTo(a.score));
    other.sort((a, b) => b.score.compareTo(a.score));

    final ranked = [...matching, ...other];
    return ranked.take(limit).map((s) => s.toolId).toList();
  }

  String buildToolMemoryContext({int limit = 5}) {
    final stats = getAllStats();
    if (stats.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('[Tool Memory]');
    for (final stat in stats.take(limit)) {
      buffer.writeln(
        '- ${stat.toolId}: used ${stat.totalUses}x, '
        'success ${stat.successRate.toStringAsFixed(0)}%, '
        'score ${stat.score.toStringAsFixed(0)}'
      );
    }
    return buffer.toString();
  }
}
