import 'dart:async';
import 'dart:convert';
import 'connectivity_service.dart';
import 'database_service.dart';
import 'app_logger.dart';

enum ConflictStrategy { serverWins, clientWins, merge }

class OfflineService {
  static final OfflineService _instance = OfflineService._();
  static OfflineService get instance => _instance;
  OfflineService._();

  static const _offlineQueueKey = 'offline_request_queue';
  static const _offlineCacheKey = 'offline_data_cache';
  static const int _maxRetryCount = 5;

  final List<_OfflineRequest> _queue = [];
  final Map<String, Future<void> Function(Map<String, dynamic>)> _handlers = {};
  final Map<String, ConflictStrategy> _conflictStrategies = {};
  StreamSubscription? _connectivitySub;
  bool _isOnline = true;

  bool get isOnline => _isOnline;
  int get pendingCount => _queue.length;

  void registerHandler(
    String key,
    Future<void> Function(Map<String, dynamic>) handler, {
    ConflictStrategy conflictStrategy = ConflictStrategy.serverWins,
  }) {
    _handlers[key] = handler;
    _conflictStrategies[key] = conflictStrategy;
  }

  void init() {
    _connectivitySub = ConnectivityService.instance.onConnectivityChanged.listen((online) {
      final wasOffline = !_isOnline;
      _isOnline = online;
      if (wasOffline && online) {
        _flushQueue();
      }
    });
    _loadQueue();
  }

  void dispose() {
    _connectivitySub?.cancel();
  }

  Future<T?> execute<T>({
    required String key,
    required Future<T> Function() onlineOperation,
    T Function()? offlineFallback,
    Map<String, dynamic>? requestData,
    Duration cacheTtl = const Duration(hours: 1),
  }) async {
    if (_isOnline) {
      try {
        final result = await onlineOperation();
        _cacheResult(key, result);
        return result;
      } catch (e) {
        AppLogger.instance.warning('Online operation failed, trying cache', error: e);
        final cached = _getCachedResult<T>(key, cacheTtl);
        if (cached != null) return cached;
        if (offlineFallback != null) return offlineFallback();
        rethrow;
      }
    } else {
      final cached = _getCachedResult<T>(key, cacheTtl);
      if (cached != null) return cached;
      if (offlineFallback != null) return offlineFallback();
      if (requestData != null) {
        _queue.add(_OfflineRequest(
          key: key,
          data: requestData,
          createdAt: DateTime.now(),
          version: _generateVersion(),
        ));
        _saveQueue();
      }
      return null;
    }
  }

  void enqueue(String key, Map<String, dynamic> data) {
    _queue.add(_OfflineRequest(
      key: key,
      data: data,
      createdAt: DateTime.now(),
      version: _generateVersion(),
    ));
    _saveQueue();
  }

  String _generateVersion() {
    return '${DateTime.now().millisecondsSinceEpoch}';
  }

  void _cacheResult<T>(String key, T result) {
    final cache = _loadCache();
    cache[key] = {
      'value': result is String ? result : jsonEncode(result),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'type': T.toString(),
    };
    _saveCache(cache);
  }

  T? _getCachedResult<T>(String key, Duration ttl) {
    final cache = _loadCache();
    final entry = cache[key];
    if (entry == null) return null;
    final ts = entry['timestamp'] as int? ?? 0;
    if (DateTime.now().millisecondsSinceEpoch - ts > ttl.inMilliseconds) return null;
    final value = entry['value'];
    if (value is T) return value;
    if (T == String) {
      if (value is String) return value as T;
      return null;
    }
    try {
      if (value is String) {
        final decoded = jsonDecode(value);
        if (decoded is T) return decoded;
      }
    } catch (_) {}
    return null;
  }

  Map<String, dynamic> _loadCache() {
    try {
      final db = DatabaseService.instance;
      final raw = db.data.get(_offlineCacheKey);
      if (raw == null) return {};
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  void _saveCache(Map<String, dynamic> cache) {
    try {
      final db = DatabaseService.instance;
      db.data.put(_offlineCacheKey, jsonEncode(cache));
    } catch (e) {
      AppLogger.instance.warning('Failed to save offline cache', error: e);
    }
  }

  Future<void> _flushQueue() async {
    if (_queue.isEmpty) return;
    final items = List<_OfflineRequest>.from(_queue);
    _queue.clear();
    await _saveQueueAsync();
    final failed = <_OfflineRequest>[];
    for (final item in items) {
      final handler = _handlers[item.key];
      if (handler == null) {
        AppLogger.instance.warning('No handler registered for offline request: ${item.key}');
        failed.add(item);
        continue;
      }
      try {
        await handler(item.data);
      } catch (e) {
        AppLogger.instance.warning('Failed to flush offline request: ${item.key}', error: e);
        failed.add(item);
      }
    }
    if (failed.isNotEmpty) {
      final retryable = failed.where((r) => r.retryCount < _maxRetryCount).toList();
      final exhausted = failed.where((r) => r.retryCount >= _maxRetryCount).toList();
      if (exhausted.isNotEmpty) {
        AppLogger.instance.warning('Dropped ${exhausted.length} offline requests after $_maxRetryCount retries');
      }
      for (final r in retryable) {
        r.retryCount++;
      }
      _queue.addAll(retryable);
      await _saveQueueAsync();
    }
  }

  void _loadQueue() {
    try {
      final db = DatabaseService.instance;
      final raw = db.data.get(_offlineQueueKey);
      if (raw == null) return;
      final list = jsonDecode(raw) as List<dynamic>;
      _queue.clear();
      _queue.addAll(list.map((e) => _OfflineRequest.fromJson(e as Map<String, dynamic>)));
    } catch (_) {}
  }

  void _saveQueue() {
    try {
      final db = DatabaseService.instance;
      db.data.put(_offlineQueueKey, jsonEncode(_queue.map((e) => e.toJson()).toList()));
    } catch (e) {
      AppLogger.instance.warning('Failed to save offline queue', error: e);
    }
  }

  Future<void> _saveQueueAsync() async {
    try {
      final db = DatabaseService.instance;
      await db.data.put(_offlineQueueKey, jsonEncode(_queue.map((e) => e.toJson()).toList()));
    } catch (e) {
      AppLogger.instance.warning('Failed to save offline queue', error: e);
    }
  }
}

class _OfflineRequest {
  final String key;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final String version;
  int retryCount;

  _OfflineRequest({
    required this.key,
    required this.data,
    required this.createdAt,
    required this.version,
    this.retryCount = 0,
  });

  factory _OfflineRequest.fromJson(Map<String, dynamic> json) => _OfflineRequest(
    key: json['key'] as String,
    data: json['data'] as Map<String, dynamic>,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : DateTime.now(),
    version: json['version'] as String? ?? '',
    retryCount: json['retry_count'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'key': key,
    'data': data,
    'created_at': createdAt.toIso8601String(),
    'version': version,
    'retry_count': retryCount,
  };
}
