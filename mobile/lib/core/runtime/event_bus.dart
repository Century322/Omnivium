import 'dart:async';
import 'vocabulary/runtime_event.dart';
import 'vocabulary/runtime_identity.dart';
import 'vocabulary/runtime_metadata.dart';
import 'vocabulary/runtime_route.dart';
import 'kernel/runtime_clock.dart';
import 'kernel/runtime_config.dart';
import '../app_logger.dart';

class EventSubscription {
  final String id;
  final String eventType;
  final EventPermission requiredPermission;
  final PropagationScope maxScope;
  final Future<void> Function(RuntimeEvent event) handler;
  final int priority;
  bool _active = true;

  EventSubscription({
    required this.id,
    required this.eventType,
    this.requiredPermission = EventPermission.observe,
    this.maxScope = PropagationScope.local,
    required this.handler,
    this.priority = 0,
  });

  bool get isActive => _active;

  void cancel() {
    _active = false;
  }
}

class DeadLetterEntry {
  final RuntimeEvent event;
  final String reason;
  final int timestamp;

  const DeadLetterEntry({
    required this.event,
    required this.reason,
    required this.timestamp,
  });
}

class _PrioritizedEvent {
  final RuntimeEvent event;
  final int priority;

  const _PrioritizedEvent(this.event, this.priority);
}

class EventBus {
  final RuntimeClock _clock;
  final RuntimeConfig _config;
  final Map<String, List<EventSubscription>> _subscriptions = {};
  final List<DeadLetterEntry> _deadLetters = [];
  final List<_PrioritizedEvent> _eventQueue = [];
  bool _processing = false;
  int _eventsProcessed = 0;
  int _eventsDropped = 0;
  int _deadLetterCount = 0;

  EventBus({required RuntimeClock clock, required RuntimeConfig config})
    : _clock = clock,
      _config = config;

  int get subscriptionCount =>
      _subscriptions.values.fold(0, (sum, list) => sum + list.length);
  int get eventsProcessed => _eventsProcessed;
  int get eventsDropped => _eventsDropped;
  int get deadLetterCount => _deadLetterCount;
  int get pendingCount => _eventQueue.length;

  EventSubscription subscribe(
    String eventType,
    Future<void> Function(RuntimeEvent event) handler, {
    EventPermission permission = EventPermission.observe,
    PropagationScope maxScope = PropagationScope.local,
    int priority = 0,
  }) {
    final sub = EventSubscription(
      id: 'sub_${_clock.now()}_${eventType.hashCode.abs()}',
      eventType: eventType,
      requiredPermission: permission,
      maxScope: maxScope,
      handler: handler,
      priority: priority);

    _subscriptions.putIfAbsent(eventType, () => []);
    _subscriptions[eventType]!.add(sub);
    _subscriptions[eventType]!.sort((a, b) => b.priority.compareTo(a.priority));

    return sub;
  }

  void unsubscribe(String subscriptionId) {
    for (final list in _subscriptions.values) {
      list.removeWhere((sub) => sub.id == subscriptionId);
    }
  }

  void unsubscribeAll(String eventType) {
    _subscriptions.remove(eventType);
  }

  void publish(
    String eventType,
    dynamic payload, {
    required RuntimeIdentity source,
    EventPhase phase = EventPhase.during,
    EventPermission permission = EventPermission.observe,
    PropagationScope scope = PropagationScope.local,
    String? traceId,
  }) {
    final event = RuntimeEvent(
      id: 'evt_${_clock.now()}',
      type: eventType,
      source: RuntimeRoute.local(
        capability: eventType,
        pluginId: source.identity),
      phase: phase,
      payload: payload,
      metadata: RuntimeMetadata(
        traceId: traceId ?? 'trace_${_clock.now()}',
        spanId: 'span_${_clock.monotonicMs()}'),
      permission: permission,
      scope: scope,
      timestamp: _clock.now());

    if (_eventQueue.length >= _config.maxEventBusCapacity) {
      _eventsDropped++;
      AppLogger.instance.warning(
        'EventBus capacity reached, dropping event "$eventType"');
      _addToDeadLetter(event, 'capacity_exceeded');
      return;
    }

    _eventQueue.add(_PrioritizedEvent(event, _eventPriority(event)));
    _eventQueue.sort((a, b) => b.priority.compareTo(a.priority));
    _processQueue();
  }

  List<DeadLetterEntry> getDeadLetters({int limit = 100}) {
    return _deadLetters.take(limit).toList();
  }

  void clearDeadLetters() {
    _deadLetters.clear();
    _deadLetterCount = 0;
  }

  void _addToDeadLetter(RuntimeEvent event, String reason) {
    _deadLetters.add(
      DeadLetterEntry(event: event, reason: reason, timestamp: _clock.now()));
    _deadLetterCount++;
  }

  int _eventPriority(RuntimeEvent event) {
    switch (event.permission) {
      case EventPermission.mutate:
        return 100;
      case EventPermission.intercept:
        return 50;
      case EventPermission.observe:
        return 0;
    }
  }

  Future<void> _processQueue() async {
    if (_processing || _eventQueue.isEmpty) return;
    _processing = true;

    while (_eventQueue.isNotEmpty) {
      final prioritized = _eventQueue.removeAt(0);
      await _dispatch(prioritized.event);
      _eventsProcessed++;
    }

    _processing = false;
  }

  Future<void> _dispatch(RuntimeEvent event) async {
    final subs = _subscriptions[event.type] ?? [];

    for (final sub in subs) {
      if (!sub.isActive) continue;
      if (!_scopeAllows(sub.maxScope, event.scope)) continue;
      if (!_permissionAllows(sub.requiredPermission, event.permission))
        continue;

      try {
        await sub
            .handler(event)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                AppLogger.instance.warning(
                  'EventBus handler timed out for "${event.type}"');
                _addToDeadLetter(event, 'handler_timeout');
              });
      } catch (e) {
        AppLogger.instance.error(
          'EventBus handler error for "${event.type}": $e');
        _addToDeadLetter(event, 'handler_error: $e');
      }
    }
  }

  bool _scopeAllows(PropagationScope subMaxScope, PropagationScope eventScope) {
    return eventScope.index <= subMaxScope.index;
  }

  bool _permissionAllows(
    EventPermission subPermission,
    EventPermission eventPermission) {
    if (subPermission == EventPermission.mutate) return true;
    if (subPermission == EventPermission.intercept &&
        eventPermission != EventPermission.mutate)
      return true;
    if (subPermission == EventPermission.observe &&
        eventPermission == EventPermission.observe)
      return true;
    return false;
  }
}
