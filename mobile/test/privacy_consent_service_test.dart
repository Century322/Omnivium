import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/privacy_consent_service.dart';
import 'helpers/test_helpers.dart';

void main() {
  setUp(() async {
    await setupTestEnv();
    await initSecureStorage();
  });

  group('PrivacyConsentService', () {
    test('hasConsented returns false initially', () async {
      final service = PrivacyConsentService();
      expect(await service.hasConsented(), isFalse);
    });

    test('grantConsent sets consented to true', () async {
      final service = PrivacyConsentService();
      await service.grantConsent();
      expect(await service.hasConsented(), isTrue);
    });

    test('revokeConsent sets consented to false', () async {
      final service = PrivacyConsentService();
      await service.grantConsent();
      await service.revokeConsent();
      expect(await service.hasConsented(), isFalse);
    });

    test('grantConsent persists across instances', () async {
      final service1 = PrivacyConsentService();
      await service1.grantConsent();
      final service2 = PrivacyConsentService();
      expect(await service2.hasConsented(), isTrue);
    });

    test('revokeConsent persists across instances', () async {
      final service1 = PrivacyConsentService();
      await service1.grantConsent();
      await service1.revokeConsent();
      final service2 = PrivacyConsentService();
      expect(await service2.hasConsented(), isFalse);
    });
  });
}
