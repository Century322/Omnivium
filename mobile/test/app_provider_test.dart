import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/app_provider.dart';
import 'package:omnivium/core/navigation_provider.dart';

void main() {
  group('AppProvider', () {
    late AppProvider provider;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      provider = AppProvider();
    });

    test('creates all sub-providers', () {
      expect(provider.navigation, isNotNull);
      expect(provider.model, isNotNull);
      expect(provider.session, isNotNull);
      expect(provider.matrix, isNotNull);
      expect(provider.orchestrator, isNotNull);
      expect(provider.notification, isNotNull);
      expect(provider.quickCommands, isNotNull);
      expect(provider.notes, isNotNull);
    });

    test('navigation is NavigationProvider', () {
      expect(provider.navigation, isA<NavigationProvider>());
    });

    test('remoteConfig is not null', () {
      expect(provider.remoteConfig, isNotNull);
    });

    test('getFeatureFlag returns default value', () {
      expect(provider.getFeatureFlag('nonexistent', defaultValue: true), true);
      expect(
        provider.getFeatureFlag('nonexistent', defaultValue: false),
        false,
      );
    });

    test('dispose does not throw', () {
      expect(() => provider.dispose(), returnsNormally);
    });

    test('sub-providers are consistent references', () {
      final nav1 = provider.navigation;
      final nav2 = provider.navigation;
      expect(identical(nav1, nav2), true);
    });

    test('model and session share same orchestrator', () {
      expect(
        identical(provider.model.orchestrator, provider.orchestrator),
        true,
      );
    });
  });
}
