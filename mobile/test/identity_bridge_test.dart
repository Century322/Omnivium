import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/identity_bridge.dart';
import 'helpers/test_helpers.dart';

void main() {
  bool storageReady = false;

  setUp(() async {
    await setupTestEnv();
    storageReady = await initSecureStorage();
  });

  group('IdentityBridge', () {
    test('instance is singleton', () {
      expect(IdentityBridge.instance, same(IdentityBridge.instance));
    });

    test('identity is null before authentication', () {
      final bridge = IdentityBridge.instance;
      expect(bridge.identity, isNull);
    });

    test('supabaseUserId is null before authentication', () {
      final bridge = IdentityBridge.instance;
      expect(bridge.supabaseUserId, isNull);
    });

    test('matrixUserId is null before authentication', () {
      final bridge = IdentityBridge.instance;
      expect(bridge.matrixUserId, isNull);
    });

    test('isBound is false before authentication', () {
      final bridge = IdentityBridge.instance;
      expect(bridge.isBound, isFalse);
    });

    test('onLogout does not throw', () async {
      final bridge = IdentityBridge.instance;
      await bridge.onLogout();
      expect(bridge.isBound, isFalse);
    });

    test('requireIdentity returns null before authentication', () {
      final bridge = IdentityBridge.instance;
      expect(bridge.requireIdentity(), isNull);
    });

    test('authHeaders returns map', () {
      final bridge = IdentityBridge.instance;
      expect(bridge.authHeaders(), isA<Map<String, String>>());
    });
  });
}
