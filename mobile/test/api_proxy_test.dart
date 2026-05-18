import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/api_proxy_service.dart';

void main() {
  group('ApiProxyService', () {
    test('default backend URL is set', () {
      expect(ApiProxyService.defaultBackendUrl, isNotEmpty);
      expect(ApiProxyService.defaultBackendUrl, startsWith('https://'));
    });

    test('backendUrl returns defaultBackendUrl', () {
      final service = ApiProxyService.instance;
      expect(service.backendUrl, equals(ApiProxyService.defaultBackendUrl));
    });

    test('buildAuthHeaders returns map', () {
      final service = ApiProxyService.instance;
      final headers = service.buildAuthHeaders();
      expect(headers, isA<Map<String, String>>());
    });

    test('buildDeviceHeaders returns device info', () {
      final service = ApiProxyService.instance;
      final headers = service.buildDeviceHeaders();
      expect(headers.containsKey('X-Device-Id'), true);
      expect(headers.containsKey('X-App-Version'), true);
      expect(headers.containsKey('X-Platform'), true);
    });

    test('resolveApiUrl returns backend URL with provider', () {
      final service = ApiProxyService.instance;
      final url = service.resolveApiUrl('openai');
      expect(url.toString(), contains('openai'));
      expect(url.toString(), startsWith(ApiProxyService.defaultBackendUrl));
    });

    test('resolveChatUrl returns /ai/chat endpoint', () {
      final service = ApiProxyService.instance;
      final url = service.resolveChatUrl();
      expect(url.toString(), contains('/ai/chat'));
    });

    test('resolveClassifyUrl returns /ai/classify endpoint', () {
      final service = ApiProxyService.instance;
      final url = service.resolveClassifyUrl();
      expect(url.toString(), contains('/ai/classify'));
    });
  });
}
