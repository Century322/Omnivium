import 'app_logger.dart';
import 'app_config.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:crypto/crypto.dart';
import 'network_security_service.dart';
import 'matrix/matrix_service.dart';
import 'encryption_service.dart';

class ApiProxyService {
  static final ApiProxyService _instance = ApiProxyService._();
  static ApiProxyService get instance => _instance;
  ApiProxyService._();

  static const defaultBackendUrl =
      'https://omnivium-api-proxy.so1946875590.workers.dev';
  static const _fallbackUrls = [
    'https://omnivium-api-proxy.so1946875590.workers.dev',
  ];

  String get _effectiveBaseUrl {
    final envUrl = AppConfig.apiBaseUrl;
    if (envUrl.isNotEmpty && envUrl != 'http://10.0.2.2:8787') return envUrl;
    return _fallbackUrls[_activeUrlIndex];
  }

  int _activeUrlIndex = 0;
  final Map<String, int> _failureCounts = {};

  String get backendUrl {
    final remote = _remoteConfig?['backend_url'] as String?;
    if (remote != null && remote.isNotEmpty) return remote;
    return _effectiveBaseUrl;
  }

  void _reportFailure(String url) {
    _failureCounts[url] = (_failureCounts[url] ?? 0) + 1;
    if (_failureCounts[url]! >= 3 && _fallbackUrls.length > 1) {
      final nextIndex = (_activeUrlIndex + 1) % _fallbackUrls.length;
      if (nextIndex != _activeUrlIndex) {
        _activeUrlIndex = nextIndex;
        _circuitBreaker.reset();
      }
    }
  }

  void _reportSuccess(String url) {
    _failureCounts.remove(url);
  }

  Map<String, dynamic>? _remoteConfig;
  Map<String, List<String>>? _availableModels;

  final _circuitBreaker = _CircuitBreaker(
    failureThreshold: 5,
    recoveryTimeout: const Duration(seconds: 30),
    halfOpenMaxRequests: 2,
  );
  final _responseCache = _ResponseCache(defaultTtl: const Duration(minutes: 5));

  bool get isConfigured {
    final matrix = MatrixService.instance;
    return matrix.isLoggedIn;
  }

  Map<String, dynamic>? get remoteConfig => _remoteConfig;
  Map<String, List<String>>? get availableModels => _availableModels;

  Future<void> init() async {
    await _fetchRemoteConfig();
  }

  Uri resolveApiUrl(String provider, {String? proxyPath}) {
    final path = proxyPath ?? '/ai/$provider/chat/completions';
    return Uri.parse('$backendUrl$path');
  }

  Uri resolveChatUrl() {
    return Uri.parse('$backendUrl/ai/chat');
  }

  Uri resolveModelsUrl() {
    return Uri.parse('$backendUrl/ai/models');
  }

  Uri resolveClassifyUrl() {
    return Uri.parse('$backendUrl/ai/classify');
  }

  Map<String, String> buildAuthHeaders({String? body}) {
    final headers = <String, String>{};
    final matrix = MatrixService.instance;
    final token = matrix.client?.accessToken;
    if (matrix.isLoggedIn && token != null) {
      headers['Authorization'] = 'Bearer $token';
      headers['X-Auth-Source'] = 'matrix';
      headers['X-User-Id'] = matrix.userId ?? '';
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    headers['X-Timestamp'] = timestamp;
    if (body != null && body.isNotEmpty && token != null) {
      final signingInput = '$timestamp:${sha256.convert(utf8.encode(body))}';
      final key = utf8.encode(token);
      final hmacSig = Hmac(sha256, key).convert(utf8.encode(signingInput));
      headers['X-Request-Signature'] = base64.encode(hmacSig.bytes);
    }
    return headers;
  }

  Map<String, String> buildDeviceHeaders() {
    return {
      'X-Device-Id': _deviceId,
      'X-App-Version': _appVersion,
      'X-Platform': defaultTargetPlatform.name,
    };
  }

  http.Client get secureClient {
    return _BreadcrumbClient(
      NetworkSecurityService.instance.client,
      _circuitBreaker,
    );
  }

  Future<bool> checkBackendHealth() async {
    try {
      final uri = Uri.parse('$backendUrl/health');
      final response = await secureClient
          .get(uri)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] == 'ok';
      }
      return false;
    } catch (e, stackTrace) {
      AppLogger.instance.warning(
        'Operation failed',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<Map<String, dynamic>> checkAppStatus() async {
    final cacheKey = 'status_$_deviceId';
    final cached = _responseCache.get(cacheKey);
    if (cached != null) return cached;

    try {
      final uri = Uri.parse('$backendUrl/status');
      final response = await secureClient
          .get(uri, headers: buildDeviceHeaders())
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        _responseCache.put(cacheKey, result, ttl: const Duration(minutes: 10));
        return result;
      }
      return {};
    } catch (e, stackTrace) {
      AppLogger.instance.warning(
        'Operation failed',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  Future<void> _fetchRemoteConfig() async {
    if (!isConfigured) return;
    try {
      final uri = Uri.parse('$backendUrl/config');
      final response = await secureClient
          .get(uri, headers: {...buildAuthHeaders(), ...buildDeviceHeaders()})
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        _remoteConfig = body['config'] as Map<String, dynamic>?;
      }
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'Operation failed',
        error: e,
        stackTrace: stackTrace,
      );
    }

    try {
      final uri = Uri.parse('$backendUrl/models');
      final response = await secureClient
          .get(uri, headers: {...buildAuthHeaders(), ...buildDeviceHeaders()})
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final raw = body['models'] as Map<String, dynamic>?;
        if (raw != null) {
          _availableModels = raw.map(
            (k, v) => MapEntry(k, List<String>.from(v)),
          );
        }
      }
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'Operation failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> registerDevice({
    required String deviceId,
    required String fcmToken,
    String platform = 'unknown',
    String appVersion = '1.0.0',
    String? userId,
  }) async {
    try {
      final uri = Uri.parse('$backendUrl/device/register');
      final response = await secureClient
          .post(
            uri,
            headers: {...buildAuthHeaders(), ...buildDeviceHeaders()},
            body: jsonEncode({
              'device_id': deviceId,
              'platform': platform,
              'fcm_token': fcmToken,
              'app_version': appVersion,
              'user_id': userId,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e, stackTrace) {
      AppLogger.instance.warning(
        'Operation failed',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<Map<String, dynamic>> proxyRequest({
    required String path,
    required Map<String, dynamic> body,
    String method = 'POST',
  }) async {
    final uri = Uri.parse('$backendUrl$path');
    final encodedBody = jsonEncode(body);
    final enc = EncryptionService.instance;
    final payload = enc.isReady ? enc.encrypt(encodedBody) : encodedBody;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...buildAuthHeaders(body: encodedBody),
      ...buildDeviceHeaders(),
    };
    if (enc.isReady) headers['X-Encrypted'] = '1';

    http.Response response;
    try {
      switch (method.toUpperCase()) {
        case 'POST':
          response = await secureClient
              .post(uri, headers: headers, body: payload)
              .timeout(const Duration(seconds: 30));
          break;
        case 'PUT':
          response = await secureClient
              .put(uri, headers: headers, body: payload)
              .timeout(const Duration(seconds: 30));
          break;
        case 'DELETE':
          response = await secureClient
              .delete(uri, headers: headers, body: payload)
              .timeout(const Duration(seconds: 30));
          break;
        default:
          response = await secureClient
              .post(uri, headers: headers, body: payload)
              .timeout(const Duration(seconds: 30));
      }
    } catch (e) {
      AppLogger.instance.error(
        'Proxy request timeout or network error',
        error: e,
      );
      rethrow;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      _reportSuccess(uri.toString());
      final responseBody = response.headers['x-encrypted'] == '1' && enc.isReady
          ? enc.decrypt(response.body) ?? response.body
          : response.body;
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } else {
      _reportFailure(uri.toString());
      throw Exception(
        'Proxy request failed: ${response.statusCode} ${response.body}',
      );
    }
  }

  String _deviceId = '';
  String _appVersion = '1.0.0';

  void setDeviceInfo({required String deviceId, required String appVersion}) {
    _deviceId = deviceId;
    _appVersion = appVersion;
  }
}

enum _CircuitState { closed, open, halfOpen }

class _CircuitBreaker {
  _CircuitState _state = _CircuitState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  int _halfOpenSuccessCount = 0;

  final int failureThreshold;
  final Duration recoveryTimeout;
  final int halfOpenMaxRequests;

  _CircuitBreaker({
    required this.failureThreshold,
    required this.recoveryTimeout,
    required this.halfOpenMaxRequests,
  });

  _CircuitState get state => _state;
  bool get isOpen => _state == _CircuitState.open;
  bool get isClosed => _state == _CircuitState.closed;
  bool get isHalfOpen => _state == _CircuitState.halfOpen;

  bool allowRequest() {
    switch (_state) {
      case _CircuitState.closed:
        return true;
      case _CircuitState.open:
        if (_lastFailureTime != null &&
            DateTime.now().difference(_lastFailureTime!) > recoveryTimeout) {
          _state = _CircuitState.halfOpen;
          _halfOpenSuccessCount = 0;
          return true;
        }
        return false;
      case _CircuitState.halfOpen:
        return _halfOpenSuccessCount < halfOpenMaxRequests;
    }
  }

  void recordSuccess() {
    if (_state == _CircuitState.halfOpen) {
      _halfOpenSuccessCount++;
      if (_halfOpenSuccessCount >= halfOpenMaxRequests) {
        _state = _CircuitState.closed;
        _failureCount = 0;
      }
    } else {
      _failureCount = 0;
    }
  }

  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    if (_state == _CircuitState.halfOpen) {
      _state = _CircuitState.open;
    } else if (_failureCount >= failureThreshold) {
      _state = _CircuitState.open;
    }
  }

  void reset() {
    _state = _CircuitState.closed;
    _failureCount = 0;
    _lastFailureTime = null;
    _halfOpenSuccessCount = 0;
  }
}

class _ResponseCache {
  final Map<String, _CacheEntry> _cache = {};
  final Duration defaultTtl;

  _ResponseCache({required this.defaultTtl});

  Map<String, dynamic>? get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiry)) {
      _cache.remove(key);
      return null;
    }
    return entry.data;
  }

  void put(String key, Map<String, dynamic> data, {Duration? ttl}) {
    _cache[key] = _CacheEntry(
      data: data,
      expiry: DateTime.now().add(ttl ?? defaultTtl),
    );
    if (_cache.length > 100) {
      _evictExpired();
    }
  }

  void invalidate(String key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }

  void _evictExpired() {
    final now = DateTime.now();
    _cache.removeWhere((_, entry) => now.isAfter(entry.expiry));
  }
}

class _CacheEntry {
  final Map<String, dynamic> data;
  final DateTime expiry;
  const _CacheEntry({required this.data, required this.expiry});
}

class _BreadcrumbClient extends http.BaseClient {
  final http.Client _inner;
  final _CircuitBreaker _circuit;
  static const int _maxRetries = 3;
  static const Duration _baseDelay = Duration(milliseconds: 500);
  static const Set<int> _nonRetryableStatusCodes = {501, 505, 506, 507};
  _BreadcrumbClient(this._inner, this._circuit);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!_circuit.allowRequest()) {
      throw Exception('Circuit breaker is open - service unavailable');
    }

    final sw = Stopwatch()..start();
    Object? lastError;

    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          final delay = _baseDelay * pow(2, attempt - 1);
          final jitter = Duration(milliseconds: Random().nextInt(200));
          await Future.delayed(delay + jitter);
          AppLogger.instance.info('Retry attempt $attempt for ${request.url}');
        }

        final retryRequest = _copyRequest(request);
        final response = await _inner
            .send(retryRequest)
            .timeout(const Duration(seconds: 30));
        sw.stop();
        Sentry.addBreadcrumb(
          Breadcrumb(
            category: 'http',
            type: 'http',
            data: {
              'url': request.url.toString(),
              'method': request.method,
              'status_code': response.statusCode,
              'duration_ms': sw.elapsedMilliseconds,
              'attempt': attempt,
            },
            level: response.statusCode < 400
                ? SentryLevel.info
                : SentryLevel.warning,
          ),
        );

        if (response.statusCode >= 500) {
          _circuit.recordFailure();
        } else {
          _circuit.recordSuccess();
        }

        if (response.statusCode < 500 ||
            _nonRetryableStatusCodes.contains(response.statusCode) ||
            attempt == _maxRetries) {
          return response;
        }
        continue;
      } catch (e) {
        lastError = e;
        sw.stop();
        _circuit.recordFailure();
        if (attempt == _maxRetries) {
          Sentry.addBreadcrumb(
            Breadcrumb(
              category: 'http',
              type: 'http',
              data: {
                'url': request.url.toString(),
                'method': request.method,
                'error': e.toString(),
                'duration_ms': sw.elapsedMilliseconds,
                'attempt': attempt,
              },
              level: SentryLevel.error,
            ),
          );
          rethrow;
        }
      }
    }
    throw lastError ?? Exception('Request failed after retries');
  }

  http.BaseRequest _copyRequest(http.BaseRequest original) {
    final copy = http.Request(original.method, original.url);
    copy.headers.addAll(original.headers);
    if (original is http.Request && original.bodyBytes.isNotEmpty) {
      copy.bodyBytes = original.bodyBytes;
    }
    copy.followRedirects = original.followRedirects;
    copy.maxRedirects = original.maxRedirects;
    copy.persistentConnection = original.persistentConnection;
    return copy;
  }
}
