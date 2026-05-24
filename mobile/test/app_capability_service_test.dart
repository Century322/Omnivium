import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/app_capability_service.dart';

void main() {
  group('AppCapabilityService', () {
    test('instance is singleton', () {
      expect(
        AppCapabilityService.instance,
        same(AppCapabilityService.instance),
      );
    });

    test('invoke returns result when SDK not initialized', () async {
      final service = AppCapabilityService.instance;
      final result = await service.invoke(
        'agent.chat',
        params: {'message': 'hello'},
      );
      expect(result, isNotNull);
    });

    test('checkPermission returns value when SDK not initialized', () async {
      final service = AppCapabilityService.instance;
      final result = await service.checkPermission('agent.chat');
      expect(result, isA<bool>());
    });

    test('isAllowed returns value when SDK not initialized', () async {
      final service = AppCapabilityService.instance;
      final result = await service.isAllowed('agent.chat');
      expect(result, isA<bool>());
    });

    test('invoke with timeout parameter', () async {
      final service = AppCapabilityService.instance;
      final result = await service.invoke('agent.chat', timeoutMs: 5000);
      expect(result, isNotNull);
    });
  });
}
