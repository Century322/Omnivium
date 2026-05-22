class RuntimeSpan {
  final String spanId;
  final String? parentSpanId;
  final String traceId;
  final String operation;
  final String pluginId;
  final String capabilityId;
  final int startTimeMs;
  int? endTimeMs;
  String status;
  final Map<String, String> tags;

  RuntimeSpan({
    required this.spanId,
    this.parentSpanId,
    required this.traceId,
    required this.operation,
    this.pluginId = '',
    this.capabilityId = '',
    required this.startTimeMs,
    this.endTimeMs,
    this.status = 'ok',
    this.tags = const {},
  });

  int get durationMs => endTimeMs != null ? endTimeMs! - startTimeMs : 0;

  void finish({String? status, int? endTimeMs}) {
    this.endTimeMs = endTimeMs ?? DateTime.now().millisecondsSinceEpoch;
    if (status != null) this.status = status;
  }

  Map<String, dynamic> toJson() => {
    'spanId': spanId,
    'parentSpanId': parentSpanId,
    'traceId': traceId,
    'operation': operation,
    'pluginId': pluginId,
    'capabilityId': capabilityId,
    'startTimeMs': startTimeMs,
    'endTimeMs': endTimeMs,
    'durationMs': durationMs,
    'status': status,
    'tags': tags,
  };
}

class RuntimeTrace {
  final String traceId;
  final List<RuntimeSpan> spans;
  final int createdAt;

  RuntimeTrace({
    required this.traceId,
    List<RuntimeSpan>? spans,
    required this.createdAt,
  }) : spans = spans ?? [];

  void addSpan(RuntimeSpan span) => spans.add(span);

  RuntimeSpan? get rootSpan =>
      spans.where((s) => s.parentSpanId == null).firstOrNull;

  List<RuntimeSpan> childrenOf(String spanId) =>
      spans.where((s) => s.parentSpanId == spanId).toList();

  int get totalDurationMs {
    if (spans.isEmpty) return 0;
    final endTimes = spans
        .where((s) => s.endTimeMs != null)
        .map((s) => s.endTimeMs!);
    if (endTimes.isEmpty) return 0;
    return endTimes.reduce((a, b) => a > b ? a : b) - spans.first.startTimeMs;
  }
}

class TraceService {
  final Map<String, RuntimeTrace> _traces = {};
  int _spanCounter = 0;

  RuntimeTrace startTrace({String? traceId}) {
    final id =
        traceId ??
        'trace_${DateTime.now().millisecondsSinceEpoch}_${_spanCounter++}';
    final trace = RuntimeTrace(
      traceId: id,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    _traces[id] = trace;
    return trace;
  }

  RuntimeSpan startSpan({
    required String traceId,
    String? parentSpanId,
    required String operation,
    String pluginId = '',
    String capabilityId = '',
    Map<String, String> tags = const {},
  }) {
    final span = RuntimeSpan(
      spanId: 'span_${_spanCounter++}',
      parentSpanId: parentSpanId,
      traceId: traceId,
      operation: operation,
      pluginId: pluginId,
      capabilityId: capabilityId,
      startTimeMs: DateTime.now().millisecondsSinceEpoch,
      tags: tags,
    );

    final trace = _traces[traceId];
    if (trace != null) {
      trace.addSpan(span);
    }

    return span;
  }

  RuntimeTrace? getTrace(String traceId) => _traces[traceId];

  void finishSpan(RuntimeSpan span, {String? status}) {
    span.finish(status: status);
  }

  List<RuntimeTrace> recentTraces({int limit = 100}) {
    final sorted = _traces.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }

  void clear() => _traces.clear();
}
