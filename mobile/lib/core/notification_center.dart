import 'dart:async';
import 'runtime/sdk/omnivium_sdk.dart';
import 'runtime/vocabulary/runtime_identity.dart';

typedef EventCallback = void Function(Map<String, dynamic>? data);

class NotificationCenter {
  static final NotificationCenter _instance = NotificationCenter._();
  static NotificationCenter get instance => _instance;
  NotificationCenter._();

  final Map<Event, List<_Observer>> _observers = {};
  final Map<Event, _DebounceConfig> _debounceConfigs = {};

  static void observe(Event event, EventCallback callback, {int id = 0}) {
    final observers = instance._observers.putIfAbsent(event, () => []);
    observers.removeWhere((o) => o.id == id && o.callback == callback);
    observers.add(_Observer(id: id, callback: callback));
  }

  static void observeOnce(Event event, EventCallback callback) {
    void wrapper(Map<String, dynamic>? data) {
      removeObserver(event, callback: wrapper);
      callback(data);
    }

    observe(event, wrapper);
  }

  static void removeObserver(
    Event event, {
    int id = 0,
    EventCallback? callback,
  }) {
    final observers = instance._observers[event];
    if (observers == null) return;
    if (callback != null) {
      observers.removeWhere((o) => o.id == id && o.callback == callback);
    } else {
      observers.removeWhere((o) => o.id == id);
    }
  }

  static void post(Event event, {Map<String, dynamic>? data}) {
    final config = instance._debounceConfigs[event];
    if (config != null) {
      config.lastData = data;
      config.timer?.cancel();
      config.timer = Timer(config.duration, () {
        _notify(event, config.lastData);
      });
    } else {
      _notify(event, data);
    }
  }

  static void postImmediate(Event event, {Map<String, dynamic>? data}) {
    _notify(event, data);
  }

  static void setDebounce(Event event, Duration duration) {
    instance._debounceConfigs[event] = _DebounceConfig(duration: duration);
  }

  static void _notify(Event event, Map<String, dynamic>? data) {
    final observers = instance._observers[event];
    if (observers != null) {
      for (final observer in List<_Observer>.from(observers)) {
        try {
          observer.callback(data);
        } catch (_) {}
      }
    }
    _forwardToEventBus(event, data);
  }

  static void _forwardToEventBus(Event event, Map<String, dynamic>? data) {
    final sdk = OmniviumSDK.instance;
    if (!sdk.isInitialized) return;
    try {
      sdk.container.eventBus.publish(
        'app.${event.name}',
        data ?? {},
        source: RuntimeIdentity.forPlugin('NotificationCenter'),
      );
    } catch (_) {}
  }
}

class _Observer {
  final int id;
  final EventCallback callback;
  _Observer({required this.id, required this.callback});
}

class _DebounceConfig {
  final Duration duration;
  Timer? timer;
  Map<String, dynamic>? lastData;
  _DebounceConfig({required this.duration});
}

enum Event {
  sessionChanged,
  sessionCreated,
  sessionDeleted,
  activeSessionChanged,
  messageReceived,
  messageSent,
  messageUpdated,
  chatTyping,
  contactUpdated,
  contactOnline,
  contactOffline,
  modelChanged,
  streamingStarted,
  streamingChunk,
  streamingCompleted,
  streamingError,
  agentStateChanged,
  agentThinking,
  agentSkillInvoked,
  networkStatusChanged,
  connectivityChanged,
  pushNotificationReceived,
  notificationTapped,
  themeChanged,
  localeChanged,
  settingsUpdated,
  noteUpdated,
  noteDeleted,
  quickCommandUpdated,
  memoryUpdated,
  loginSuccess,
  logout,
  appPaused,
  appResumed,
  encryptionReady,
  syncCompleted,
  syncFailed,
  rateLimited,
  securityAlert,
  capabilityConfirm,
  pushNotification,
}
