import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'app_logger.dart';
import 'database_service.dart';
import 'dart:convert';

class PerformanceSpan {
  final String name;
  final DateTime startTime;
  DateTime? endTime;
  Map<String, dynamic>? data;

  PerformanceSpan({required this.name, required this.startTime, this.data});

  Duration get duration => endTime?.difference(startTime) ?? Duration.zero;
  bool get isFinished => endTime != null;

  void finish({Map<String, dynamic>? additionalData}) {
    endTime = DateTime.now();
    if (additionalData != null) {
      data = {...?data, ...additionalData};
    }
  }
}

class PerformanceMetric {
  final String name;
  final double value;
  final DateTime timestamp;
  final Map<String, dynamic>? tags;

  const PerformanceMetric({
    required this.name,
    required this.value,
    required this.timestamp,
    this.tags,
  });

  Map<String, dynamic> toJson() => {
    'name': name, 'value': value,
    'timestamp': timestamp.toIso8601String(), 'tags': tags,
  };
}

class PerformanceMonitorService {
  static final PerformanceMonitorService _instance = PerformanceMonitorService._();
  static PerformanceMonitorService get instance => _instance;
  PerformanceMonitorService._();

  static const _metricsCacheKey = 'perf_metrics';
  static const _maxMetrics = 500;

  final Map<String, PerformanceSpan> _activeSpans = {};
  final List<PerformanceMetric> _metrics = [];
  Timer? _flushTimer;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _loadCachedMetrics();

    _flushTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _flushMetrics();
    });
  }

  PerformanceSpan startSpan(String name, {Map<String, dynamic>? data}) {
    final span = PerformanceSpan(name: name, startTime: DateTime.now(), data: data);
    _activeSpans[name] = span;
    return span;
  }

  void finishSpan(String name, {Map<String, dynamic>? additionalData}) {
    final span = _activeSpans[name];
    if (span == null) return;

    span.finish(additionalData: additionalData);
    _activeSpans.remove(name);

    final durationMs = span.duration.inMilliseconds;
    recordMetric('span.$name.duration_ms', durationMs.toDouble(), tags: {
      'span_name': name,
      ...?additionalData,
    });

    if (kDebugMode) {
      AppLogger.instance.debug('Span $name completed in ${durationMs}ms');
    }

    try {
      final transaction = Sentry.startTransaction(name, 'task');
      transaction.finish(status: SpanStatus.ok());
    } catch (_) {}
  }

  void recordMetric(String name, double value, {Map<String, dynamic>? tags}) {
    final metric = PerformanceMetric(
      name: name,
      value: value,
      timestamp: DateTime.now(),
      tags: tags,
    );
    _metrics.add(metric);

    if (_metrics.length > _maxMetrics) {
      _metrics.removeRange(0, _metrics.length - _maxMetrics);
    }
  }

  Future<T> measure<T>(String name, Future<T> Function() operation, {Map<String, dynamic>? tags}) async {
    startSpan(name, data: tags);
    try {
      final result = await operation();
      finishSpan(name);
      return result;
    } catch (e) {
      finishSpan(name, additionalData: {'error': e.toString()});
      rethrow;
    }
  }

  T measureSync<T>(String name, T Function() operation, {Map<String, dynamic>? tags}) {
    final stopwatch = Stopwatch()..start();
    try {
      final result = operation();
      stopwatch.stop();
      recordMetric('sync.$name.duration_ms', stopwatch.elapsedMilliseconds.toDouble(), tags: tags);
      return result;
    } catch (e) {
      stopwatch.stop();
      recordMetric('sync.$name.duration_ms', stopwatch.elapsedMilliseconds.toDouble(), tags: {
        ...?tags, 'error': e.toString(),
      });
      rethrow;
    }
  }

  Map<String, dynamic> getSummary() {
    final spanMetrics = <String, List<double>>{};
    for (final metric in _metrics) {
      if (metric.name.startsWith('span.')) {
        spanMetrics.putIfAbsent(metric.name, () => []);
        spanMetrics[metric.name]!.add(metric.value);
      }
    }

    final summary = <String, dynamic>{};
    for (final entry in spanMetrics.entries) {
      final values = entry.value;
      summary[entry.key] = {
        'count': values.length,
        'avg': values.reduce((a, b) => a + b) / values.length,
        'min': values.reduce((a, b) => a < b ? a : b),
        'max': values.reduce((a, b) => a > b ? a : b),
        'p95': _percentile(values, 0.95),
      };
    }
    return summary;
  }

  double _percentile(List<double> sorted, double p) {
    if (sorted.isEmpty) return 0;
    final list = List<double>.from(sorted)..sort();
    final index = (list.length * p).ceil() - 1;
    return list[index.clamp(0, list.length - 1)];
  }

  Future<void> _loadCachedMetrics() async {
    try {
      final db = DatabaseService.instance;
      if (!db.isInitialized) return;
      final raw = db.getCache(_metricsCacheKey);
      if (raw == null) return;
      final list = jsonDecode(raw) as List;
      _metrics.clear();
      for (final item in list) {
        final m = item as Map<String, dynamic>;
        _metrics.add(PerformanceMetric(
          name: m['name'] as String,
          value: (m['value'] as num).toDouble(),
          timestamp: DateTime.parse(m['timestamp'] as String),
          tags: m['tags'] as Map<String, dynamic>?,
        ));
      }
    } catch (_) {}
  }

  Future<void> _flushMetrics() async {
    try {
      final db = DatabaseService.instance;
      if (!db.isInitialized) return;
      await db.putCache(_metricsCacheKey, jsonEncode(_metrics.map((m) => m.toJson()).toList()));
    } catch (_) {}
  }

  void dispose() {
    _flushTimer?.cancel();
    _flushMetricsSync();
  }

  void _flushMetricsSync() {
    try {
      final db = DatabaseService.instance;
      if (!db.isInitialized) return;
      db.putCache(_metricsCacheKey, jsonEncode(_metrics.map((m) => m.toJson()).toList()));
    } catch (_) {}
  }
}
