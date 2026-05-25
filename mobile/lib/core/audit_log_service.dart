import 'runtime/sdk/omnivium_sdk.dart';

class AuditLogEntry {
  final String id;
  final String type;
  final String operation;
  final String actor;
  final String target;
  final bool allowed;
  final int timestamp;
  final Map<String, dynamic> details;

  const AuditLogEntry({
    required this.id,
    required this.type,
    required this.operation,
    required this.actor,
    required this.target,
    required this.allowed,
    required this.timestamp,
    this.details = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'operation': operation,
    'actor': actor,
    'target': target,
    'allowed': allowed,
    'timestamp': timestamp,
    'details': details,
  };
}

class AuditLogService {
  static final AuditLogService _instance = AuditLogService._();
  static AuditLogService get instance => _instance;
  AuditLogService._();

  OmniviumSDK? get _sdk {
    final sdk = OmniviumSDK.instance;
    return sdk.isInitialized ? sdk : null;
  }

  List<AuditLogEntry> getRecentEntries({int limit = 50}) {
    final sdk = _sdk;
    if (sdk == null) return [];

    final journal = sdk.container.eventJournal;
    final entries = journal.entries;

    return entries
        .map(
          (e) => AuditLogEntry(
            id: e.sequence.toRadixString(16),
            type: e.type,
            operation:
                e.data['capability'] as String? ??
                e.data['action'] as String? ??
                e.type,
            actor: e.data['caller'] as String? ?? 'system',
            target: e.data['target'] as String? ?? '',
            allowed: e.data['allowed'] as bool? ?? true,
            timestamp: (e.timestamp is DateTime
                ? (e.timestamp as DateTime).millisecondsSinceEpoch
                : e.timestamp),
            details: e.data,
          ),
        )
        .take(limit)
        .toList();
  }

  Map<String, dynamic> getSummary() {
    final sdk = _sdk;
    if (sdk == null) return {'available': false};

    final journal = sdk.container.eventJournal;
    final metrics = sdk.container.metricsService;
    final traceService = sdk.container.traceService;
    final entries = journal.entries;
    final traces = traceService.recentTraces();

    return {
      'available': true,
      'totalEntries': entries.length,
      'metricsCount': metrics.counterCount,
      'pluginsActive': sdk.container.pluginRegistry.activeCount,
      'containerStatus': sdk.container.status.name,
      'traceCount': traces.length,
      'recentTraceDurations': traces
          .take(10)
          .map(
            (t) => {
              'traceId': t.traceId,
              'totalDurationMs': t.totalDurationMs,
              'spanCount': t.spans.length,
              'rootOperation': t.rootSpan?.operation ?? '',
            },
          )
          .toList(),
    };
  }

  List<AuditLogEntry> getCapabilityInvocations({int limit = 20}) {
    final sdk = _sdk;
    if (sdk == null) return [];

    final journal = sdk.container.eventJournal;
    return journal.entries
        .where(
          (e) =>
              e.type == 'capability.invoked' || e.type == 'capability.denied',
        )
        .map(
          (e) => AuditLogEntry(
            id: e.sequence.toRadixString(16),
            type: e.type,
            operation: e.data['capability'] as String? ?? 'unknown',
            actor: e.data['caller'] as String? ?? 'system',
            target: e.data['target'] as String? ?? '',
            allowed: e.type != 'capability.denied',
            timestamp: (e.timestamp is DateTime
                ? (e.timestamp as DateTime).millisecondsSinceEpoch
                : e.timestamp),
            details: e.data,
          ),
        )
        .take(limit)
        .toList();
  }
}
