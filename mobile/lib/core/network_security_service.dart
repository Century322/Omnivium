import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'app_logger.dart';
import 'api_proxy_service.dart';
import 'database_service.dart';
import 'network_security_stub.dart'
    if (dart.library.io) 'network_security_io.dart';

class NetworkSecurityService {
  static final NetworkSecurityService _instance = NetworkSecurityService._();
  static NetworkSecurityService get instance => _instance;
  NetworkSecurityService._();

  final Map<String, List<String>> _pinnedHashes = {};
  bool _pinningEnabled = false;
  bool get pinningEnabled => _pinningEnabled;
  bool _initialized = false;

  http.Client? _pinnedClient;

  static const _productionPins = <String, List<String>>{
    'omnivium-api-proxy.so1946875590.workers.dev': [
      'sha256/Ylh3sS2GoYUjSSDIpEP4sM8XHi4YxhP0FfXJHBKifgE=',
    ],
    'omnivium.app': [
      'sha256/Ylh3sS2GoYUjSSDIpEP4sM8XHi4YxhP0FfXJHBKifgE=',
    ],
  };

  static const _fallbackPins = <String, List<String>>{
    'omnivium-api-proxy.so1946875590.workers.dev': [
      'sha256/R+OeUMFdmDDYH7p3mQF7Y7J8K6d5s4s7T3vW2x1z9qE=',
    ],
  };

  static const _remotePinsCacheKey = 'remote_ssl_pins';

  void addPinnedHash(String host, String hash) {
    _pinnedHashes.putIfAbsent(host, () => []);
    if (!_pinnedHashes[host]!.contains(hash)) {
      _pinnedHashes[host]!.add(hash);
    }
  }

  void setPinnedHashes(Map<String, List<String>> hashes) {
    _pinnedHashes.clear();
    _pinnedHashes.addAll(hashes);
    if (_pinningEnabled && !kIsWeb) {
      _pinnedClient?.close();
      _pinnedClient = createPinnedClient(_pinnedHashes);
    }
  }

  Future<void> initWithDynamicPins() async {
    if (_initialized) return;
    _initialized = true;

    _pinnedHashes.addAll(_productionPins);
    for (final entry in _fallbackPins.entries) {
      _pinnedHashes.putIfAbsent(entry.key, () => []);
      for (final pin in entry.value) {
        if (!_pinnedHashes[entry.key]!.contains(pin)) {
          _pinnedHashes[entry.key]!.add(pin);
        }
      }
    }

    await _loadCachedRemotePins();
    await _fetchRemotePins();

    enablePinning();
  }

  Future<void> _loadCachedRemotePins() async {
    try {
      final db = DatabaseService.instance;
      if (!db.isInitialized) return;
      final raw = db.getCache(_remotePinsCacheKey);
      if (raw == null) return;
      final data = _parsePinsJson(raw);
      if (data != null) {
        for (final entry in data.entries) {
          _pinnedHashes.putIfAbsent(entry.key, () => []);
          for (final pin in entry.value) {
            if (!_pinnedHashes[entry.key]!.contains(pin)) {
              _pinnedHashes[entry.key]!.add(pin);
            }
          }
        }
      }
    } catch (e) {
      AppLogger.instance.warning('Failed to load cached remote pins', error: e);
    }
  }

  Future<void> _fetchRemotePins() async {
    try {
      final proxy = ApiProxyService.instance;
      if (!proxy.isConfigured) return;
      final uri = Uri.parse('${proxy.backendUrl}/config/ssl-pins');
      final response = await http.Client()
          .get(uri)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = _parsePinsJson(response.body);
        if (data != null && data.isNotEmpty) {
          for (final entry in data.entries) {
            _pinnedHashes.putIfAbsent(entry.key, () => []);
            for (final pin in entry.value) {
              if (!_pinnedHashes[entry.key]!.contains(pin)) {
                _pinnedHashes[entry.key]!.add(pin);
              }
            }
          }
          await _saveCachedRemotePins(data);
        }
      }
    } catch (e) {
      AppLogger.instance.info('Failed to fetch remote pins (using cached): $e');
    }
  }

  Map<String, List<String>>? _parsePinsJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final result = <String, List<String>>{};
      for (final entry in decoded.entries) {
        if (entry.value is List) {
          result[entry.key] = (entry.value as List).whereType<String>().toList();
        }
      }
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCachedRemotePins(Map<String, List<String>> pins) async {
    try {
      final db = DatabaseService.instance;
      if (!db.isInitialized) return;
      await db.putCache(_remotePinsCacheKey, jsonEncode(pins));
    } catch (e) {
      AppLogger.instance.warning('Failed to cache remote pins', error: e);
    }
  }

  void enablePinning() {
    if (kIsWeb) {
      _pinningEnabled = true;
      return;
    }
    _pinningEnabled = true;
    _pinnedClient = createPinnedClient(_pinnedHashes);
  }

  http.Client? _fallbackClient;

  http.Client get client {
    if (_pinningEnabled && _pinnedClient != null) {
      return _pinnedClient!;
    }
    _fallbackClient ??= http.Client();
    return _fallbackClient!;
  }

  Future<bool> verifyPinning(String domain) async {
    if (!_pinningEnabled) return true;
    final hostHashes = _pinnedHashes[domain];
    if (hostHashes == null || hostHashes.isEmpty) return true;

    final pinnedClient = _pinnedClient;
    if (pinnedClient == null) return false;

    try {
      final uri = Uri.https(domain, '/');
      final request = http.Request('HEAD', uri);
      await pinnedClient.send(request).timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> refreshPins() async {
    await _fetchRemotePins();
    if (_pinningEnabled && !kIsWeb) {
      _pinnedClient?.close();
      _pinnedClient = createPinnedClient(_pinnedHashes);
    }
  }
}
