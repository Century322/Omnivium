import 'hybrid_logical_clock.dart';

class DistributedSpan {
  final String spanId;
  final String? parentSpanId;
  final String traceId;
  final String operation;
  final String nodeId;
  final String pluginId;
  final String capabilityId;
  final int startTimeHlc;
  final int? endTimeHlc;
  final String status;
  final Map<String, String> tags;
  final String? remoteParentSpanId;
  final String? remoteNodeId;

  const DistributedSpan({
    required this.spanId,
    this.parentSpanId,
    required this.traceId,
    required this.operation,
    required this.nodeId,
    this.pluginId = '',
    this.capabilityId = '',
    required this.startTimeHlc,
    this.endTimeHlc,
    this.status = 'ok',
    this.tags = const {},
    this.remoteParentSpanId,
    this.remoteNodeId,
  });

  int get durationHlc {
    final end = endTimeHlc;
    return end != null ? end - startTimeHlc : 0;
  }

  bool get isRemote => remoteNodeId != null;

  bool get isCrossNode => remoteParentSpanId != null;

  Map<String, dynamic> toJson() => {
    'spanId': spanId,
    'parentSpanId': parentSpanId,
    'traceId': traceId,
    'operation': operation,
    'nodeId': nodeId,
    'pluginId': pluginId,
    'capabilityId': capabilityId,
    'startTimeHlc': startTimeHlc,
    'endTimeHlc': endTimeHlc,
    'durationHlc': durationHlc,
    'status': status,
    'tags': tags,
    'remoteParentSpanId': remoteParentSpanId,
    'remoteNodeId': remoteNodeId,
  };

  factory DistributedSpan.fromJson(
    Map<String, dynamic> json) => DistributedSpan(
    spanId: json['spanId'] as String,
    parentSpanId: json['parentSpanId'] as String?,
    traceId: json['traceId'] as String,
    operation: json['operation'] as String,
    nodeId: json['nodeId'] as String,
    pluginId: json['pluginId'] as String? ?? '',
    capabilityId: json['capabilityId'] as String? ?? '',
    startTimeHlc: json['startTimeHlc'] as int,
    endTimeHlc: json['endTimeHlc'] as int?,
    status: json['status'] as String? ?? 'ok',
    tags: (json['tags'] as Map<String, dynamic>?)?.cast<String, String>() ?? {},
    remoteParentSpanId: json['remoteParentSpanId'] as String?,
    remoteNodeId: json['remoteNodeId'] as String?);
}

class DistributedTrace {
  final String traceId;
  final String rootNodeId;
  final List<DistributedSpan> spans;
  final int createdAt;
  final Map<String, String> tags;

  DistributedTrace({
    required this.traceId,
    required this.rootNodeId,
    List<DistributedSpan>? spans,
    required this.createdAt,
    this.tags = const {},
  }) : spans = spans ?? [];

  void addSpan(DistributedSpan span) => spans.add(span);

  DistributedSpan? get rootSpan => spans
      .where((s) => s.parentSpanId == null && s.remoteParentSpanId == null)
      .firstOrNull;

  List<DistributedSpan> spansOnNode(String nodeId) =>
      spans.where((s) => s.nodeId == nodeId).toList();

  List<String> get involvedNodes => spans.map((s) => s.nodeId).toSet().toList();

  List<DistributedSpan> crossNodeSpans() =>
      spans.where((s) => s.isCrossNode).toList();

  Map<String, dynamic> toJson() => {
    'traceId': traceId,
    'rootNodeId': rootNodeId,
    'spans': spans.map((s) => s.toJson()).toList(),
    'createdAt': createdAt,
    'tags': tags,
    'involvedNodes': involvedNodes,
  };
}

class TracePropagationContext {
  final String traceId;
  final String parentSpanId;
  final String originNodeId;
  final int hlcTime;
  final Map<String, String> baggage;

  const TracePropagationContext({
    required this.traceId,
    required this.parentSpanId,
    required this.originNodeId,
    required this.hlcTime,
    this.baggage = const {},
  });

  Map<String, String> toHeaders() => {
    'x-trace-id': traceId,
    'x-parent-span-id': parentSpanId,
    'x-origin-node': originNodeId,
    'x-hlc-time': hlcTime.toString(),
    ...baggage.map((k, v) => MapEntry('x-baggage-$k', v)),
  };

  factory TracePropagationContext.fromHeaders(Map<String, String> headers) =>
      TracePropagationContext(
        traceId: headers['x-trace-id'] ?? '',
        parentSpanId: headers['x-parent-span-id'] ?? '',
        originNodeId: headers['x-origin-node'] ?? '',
        hlcTime: int.tryParse(headers['x-hlc-time'] ?? '0') ?? 0,
        baggage: Map.fromEntries(
          headers.entries
              .where((e) => e.key.startsWith('x-baggage-'))
              .map((e) => MapEntry(e.key.substring(10), e.value))));
}

class DistributedTraceService {
  final String _localNodeId;
  final HybridLogicalClock _clock;
  final Map<String, DistributedTrace> _traces = {};
  int _spanCounter = 0;

  DistributedTraceService({
    required String localNodeId,
    required HybridLogicalClock clock,
  }) : _localNodeId = localNodeId,
       _clock = clock;

  String get localNodeId => _localNodeId;

  DistributedTrace startTrace({
    String? traceId,
    Map<String, String> tags = const {},
  }) {
    final now = _clock.tick();
    final id = traceId ?? 'dtrace_${now.physicalTime}_${_spanCounter++}';
    final trace = DistributedTrace(
      traceId: id,
      rootNodeId: _localNodeId,
      createdAt: now.physicalTime,
      tags: tags);
    _traces[id] = trace;
    return trace;
  }

  DistributedSpan startSpan({
    required String traceId,
    String? parentSpanId,
    required String operation,
    String pluginId = '',
    String capabilityId = '',
    String? remoteParentSpanId,
    String? remoteNodeId,
    Map<String, String> tags = const {},
  }) {
    final now = _clock.tick();
    final span = DistributedSpan(
      spanId: 'dspan_${_spanCounter++}',
      parentSpanId: parentSpanId,
      traceId: traceId,
      operation: operation,
      nodeId: _localNodeId,
      pluginId: pluginId,
      capabilityId: capabilityId,
      startTimeHlc: now.physicalTime,
      tags: tags,
      remoteParentSpanId: remoteParentSpanId,
      remoteNodeId: remoteNodeId);

    final trace = _traces[traceId];
    if (trace != null) {
      trace.addSpan(span);
    }

    return span;
  }

  void finishSpan(DistributedSpan span, {String? status}) {
    final now = _clock.tick();
    span = DistributedSpan(
      spanId: span.spanId,
      parentSpanId: span.parentSpanId,
      traceId: span.traceId,
      operation: span.operation,
      nodeId: span.nodeId,
      pluginId: span.pluginId,
      capabilityId: span.capabilityId,
      startTimeHlc: span.startTimeHlc,
      endTimeHlc: now.physicalTime,
      status: status ?? span.status,
      tags: span.tags,
      remoteParentSpanId: span.remoteParentSpanId,
      remoteNodeId: span.remoteNodeId);

    final trace = _traces[span.traceId];
    if (trace != null) {
      final idx = trace.spans.indexWhere((s) => s.spanId == span.spanId);
      if (idx >= 0) {
        trace.spans[idx] = span;
      }
    }
  }

  DistributedSpan startRemoteSpan(
    TracePropagationContext context, {
    required String operation,
  }) {
    return startSpan(
      traceId: context.traceId,
      remoteParentSpanId: context.parentSpanId,
      remoteNodeId: context.originNodeId,
      operation: operation,
      tags: {'propagated': 'true'});
  }

  TracePropagationContext propagateContext(DistributedSpan span) {
    return TracePropagationContext(
      traceId: span.traceId,
      parentSpanId: span.spanId,
      originNodeId: _localNodeId,
      hlcTime: _clock.now.physicalTime);
  }

  DistributedTrace? getTrace(String traceId) => _traces[traceId];

  List<DistributedTrace> recentTraces({int limit = 100}) {
    final sorted = _traces.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }

  void receiveRemoteSpans(String traceId, List<DistributedSpan> remoteSpans) {
    var trace = _traces[traceId];
    if (trace == null) {
      trace = DistributedTrace(
        traceId: traceId,
        rootNodeId: remoteSpans.firstOrNull?.nodeId ?? 'unknown',
        createdAt: _clock.tick().physicalTime);
      _traces[traceId] = trace;
    }

    for (final span in remoteSpans) {
      if (!trace.spans.any((s) => s.spanId == span.spanId)) {
        trace.addSpan(span);
      }
    }
  }

  void clear() => _traces.clear();
}
