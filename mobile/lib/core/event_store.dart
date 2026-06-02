import 'dart:convert';
import 'app_logger.dart';
import 'database_service.dart';

enum DomainEventType {
  projectCreated,
  projectArchived,
  taskAssigned,
  taskCompleted,
  agentCreated,
  agentDestroyed,
  agentTaskCompleted,
  fileUploaded,
  fileDeleted,
  noteCreated,
  noteEdited,
  noteCompleted,
  messageSent,
  messageForwarded,
  postShared,
  planCreated,
  planStepCompleted,
  planCompleted,
  chainStarted,
  chainStepCompleted,
  chainCompleted,
  capabilityInvoked,
  workspaceActivated,
  stateChanged,
}

class DomainEvent {
  final String id;
  final DomainEventType type;
  final String aggregateId;
  final String aggregateType;
  final Map<String, dynamic> payload;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final int version;

  const DomainEvent({
    required this.id,
    required this.type,
    required this.aggregateId,
    required this.aggregateType,
    this.payload = const {},
    this.metadata = const {},
    required this.timestamp,
    this.version = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'aggregateId': aggregateId,
    'aggregateType': aggregateType,
    'payload': payload,
    'metadata': metadata,
    'timestamp': timestamp.toIso8601String(),
    'version': version,
  };

  factory DomainEvent.fromJson(Map<String, dynamic> json) => DomainEvent(
    id: json['id'] as String,
    type: DomainEventType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => DomainEventType.stateChanged,
    ),
    aggregateId: json['aggregateId'] as String,
    aggregateType: json['aggregateType'] as String,
    payload: (json['payload'] as Map<String, dynamic>?) ?? {},
    metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
    timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    version: json['version'] as int? ?? 0,
  );
}

class EventStore {
  final DatabaseService _db;
  bool _isInitialized = false;

  static const _eventsKey = 'domain_events';
  static const _maxEvents = 1000;

  List<DomainEvent> _events = [];
  final Map<String, int> _aggregateVersions = {};

  EventStore(this._db);

  bool get isInitialized => _isInitialized;
  int get eventCount => _events.length;
  int get aggregateCount => _aggregateVersions.length;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final json = await _db.getCache(_eventsKey);
      if (json != null) {
        final list = jsonDecode(json) as List<dynamic>;
        _events = list
            .map((e) => DomainEvent.fromJson(e as Map<String, dynamic>))
            .toList();
        for (final event in _events) {
          _aggregateVersions[event.aggregateId] = event.version;
        }
      }
      _isInitialized = true;
      AppLogger.instance.info('EventStore initialized: ${_events.length} events');
    } catch (e, st) {
      AppLogger.instance.error('EventStore init failed', error: e, stackTrace: st);
      _isInitialized = true;
    }
  }

  Future<void> append(DomainEvent event) async {
    _events.add(event);
    _aggregateVersions[event.aggregateId] = event.version;

    if (_events.length > _maxEvents) {
      _events = _events.sublist(_events.length - _maxEvents);
    }

    await _persist();
  }

  Future<void> appendMany(List<DomainEvent> events) async {
    _events.addAll(events);
    for (final event in events) {
      _aggregateVersions[event.aggregateId] = event.version;
    }

    if (_events.length > _maxEvents) {
      _events = _events.sublist(_events.length - _maxEvents);
    }

    await _persist();
  }

  List<DomainEvent> getEventsForAggregate(String aggregateId) =>
      _events.where((e) => e.aggregateId == aggregateId).toList();

  List<DomainEvent> getEventsByType(DomainEventType type) =>
      _events.where((e) => e.type == type).toList();

  List<DomainEvent> getEventsSince(DateTime since) =>
      _events.where((e) => e.timestamp.isAfter(since)).toList();

  List<DomainEvent> getRecentEvents({int limit = 50}) =>
      _events.reversed.take(limit).toList().reversed.toList();

  int getVersion(String aggregateId) => _aggregateVersions[aggregateId] ?? 0;

  Map<String, dynamic> reconstructState(String aggregateId) {
    final aggregateEvents = getEventsForAggregate(aggregateId);
    if (aggregateEvents.isEmpty) return {};

    final state = <String, dynamic>{};
    for (final event in aggregateEvents) {
      state['id'] = event.aggregateId;
      state['type'] = event.aggregateType;
      state.addAll(event.payload);
    }
    state['currentVersion'] = aggregateEvents.last.version;
    return state;
  }

  Map<String, dynamic> reconstructStateAt(String aggregateId, DateTime pointInTime) {
    final aggregateEvents = _events
        .where((e) => e.aggregateId == aggregateId && !e.timestamp.isAfter(pointInTime))
        .toList();

    if (aggregateEvents.isEmpty) return {};

    final state = <String, dynamic>{};
    for (final event in aggregateEvents) {
      state['id'] = event.aggregateId;
      state['type'] = event.aggregateType;
      state.addAll(event.payload);
    }
    state['versionAt'] = aggregateEvents.last.version;
    return state;
  }

  DomainEvent createEvent({
    required DomainEventType type,
    required String aggregateId,
    required String aggregateType,
    Map<String, dynamic> payload = const {},
    Map<String, dynamic> metadata = const {},
  }) {
    final version = (_aggregateVersions[aggregateId] ?? 0) + 1;
    _aggregateVersions[aggregateId] = version;

    return DomainEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}_${aggregateId.hashCode.abs()}_$version',
      type: type,
      aggregateId: aggregateId,
      aggregateType: aggregateType,
      payload: payload,
      metadata: metadata,
      timestamp: DateTime.now(),
      version: version,
    );
  }

  String buildEventContext({int limit = 20}) {
    final buffer = StringBuffer();
    buffer.writeln('[Event Log]');

    final recent = getRecentEvents(limit: limit);
    if (recent.isEmpty) {
      buffer.writeln('No events recorded.');
      return buffer.toString();
    }

    final byType = <DomainEventType, int>{};
    for (final event in recent) {
      byType[event.type] = (byType[event.type] ?? 0) + 1;
    }

    buffer.writeln('Recent: ${recent.length} events');
    for (final entry in byType.entries) {
      buffer.writeln('  ${entry.key.name}: ${entry.value}');
    }

    buffer.writeln('\nLast events:');
    for (final event in recent.take(10)) {
      final age = DateTime.now().difference(event.timestamp);
      final ageStr = age.inMinutes < 60
          ? '${age.inMinutes}m ago'
          : age.inHours < 24
              ? '${age.inHours}h ago'
              : '${age.inDays}d ago';
      buffer.writeln('  ${event.type.name} → ${event.aggregateType}:${event.aggregateId} [$ageStr]');
    }

    return buffer.toString();
  }

  Future<void> _persist() async {
    try {
      await _db.putCache(
        _eventsKey,
        jsonEncode(_events.map((e) => e.toJson()).toList()),
      );
    } catch (e, st) {
      AppLogger.instance.error('EventStore persist failed', error: e, stackTrace: st);
    }
  }

  Future<void> clear() async {
    _events.clear();
    _aggregateVersions.clear();
    await _persist();
  }
}
