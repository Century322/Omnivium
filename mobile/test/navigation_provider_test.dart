import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/navigation_provider.dart';

void main() {
  group('NavigationProvider', () {
    late NavigationProvider provider;

    setUp(() {
      provider = NavigationProvider();
    });

    test('initial state is home', () {
      expect(provider.currentView, ViewState.home);
    });

    test('initial isIncognito is false', () {
      expect(provider.isIncognito, false);
    });

    test('initial isSettingsOpen is false', () {
      expect(provider.isSettingsOpen, false);
    });

    test('initial shouldShowDrawerAfterSettings is false', () {
      expect(provider.shouldShowDrawerAfterSettings, false);
    });

    test('setCurrentView updates view', () {
      provider.setCurrentView(ViewState.discover);
      expect(provider.currentView, ViewState.discover);
    });

    test('setCurrentView to all views', () {
      for (final view in ViewState.values) {
        provider.setCurrentView(view);
        expect(provider.currentView, view);
      }
    });

    test('setCurrentView notifies listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);
      provider.setCurrentView(ViewState.settings);
      expect(notified, true);
    });

    test('setCurrentView to same view still notifies', () {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);
      provider.setCurrentView(ViewState.home);
      expect(notifyCount, 1);
    });

    test('setIsIncognito updates value', () {
      provider.setIsIncognito(true);
      expect(provider.isIncognito, true);
    });

    test('setIsIncognito toggles', () {
      provider.setIsIncognito(true);
      expect(provider.isIncognito, true);
      provider.setIsIncognito(false);
      expect(provider.isIncognito, false);
    });

    test('setIsIncognito notifies listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);
      provider.setIsIncognito(true);
      expect(notified, true);
    });

    test('openSettingsFromDrawer sets both flags', () {
      provider.openSettingsFromDrawer();
      expect(provider.isSettingsOpen, true);
      expect(provider.shouldShowDrawerAfterSettings, true);
    });

    test('openSettingsFromDrawer notifies listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);
      provider.openSettingsFromDrawer();
      expect(notified, true);
    });

    test(
      'closeSettingsAndReturnToDrawer clears settings and sets drawer flag',
      () {
        provider.openSettingsFromDrawer();
        provider.closeSettingsAndReturnToDrawer();
        expect(provider.isSettingsOpen, false);
        expect(provider.shouldShowDrawerAfterSettings, true);
      },
    );

    test('closeSettingsAndReturnToDrawer notifies listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);
      provider.closeSettingsAndReturnToDrawer();
      expect(notified, true);
    });

    test('setIsSettingsOpen true', () {
      provider.setIsSettingsOpen(true);
      expect(provider.isSettingsOpen, true);
    });

    test('setIsSettingsOpen false clears drawer flag', () {
      provider.openSettingsFromDrawer();
      provider.setIsSettingsOpen(false);
      expect(provider.isSettingsOpen, false);
      expect(provider.shouldShowDrawerAfterSettings, false);
    });

    test('setIsSettingsOpen notifies listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);
      provider.setIsSettingsOpen(true);
      expect(notified, true);
    });

    test('clearDrawerFlag clears flag', () {
      provider.openSettingsFromDrawer();
      provider.clearDrawerFlag();
      expect(provider.shouldShowDrawerAfterSettings, false);
    });

    test('clearDrawerFlag notifies listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);
      provider.clearDrawerFlag();
      expect(notified, true);
    });

    test('clearDrawerFlag when already false still notifies', () {
      var notified = false;
      provider.addListener(() => notified = true);
      provider.clearDrawerFlag();
      expect(notified, true);
    });

    test('full settings flow: open from drawer -> close -> show drawer', () {
      provider.openSettingsFromDrawer();
      expect(provider.isSettingsOpen, true);
      expect(provider.shouldShowDrawerAfterSettings, true);

      provider.closeSettingsAndReturnToDrawer();
      expect(provider.isSettingsOpen, false);
      expect(provider.shouldShowDrawerAfterSettings, true);

      provider.clearDrawerFlag();
      expect(provider.shouldShowDrawerAfterSettings, false);
    });

    test('settings open without drawer flag', () {
      provider.setIsSettingsOpen(true);
      expect(provider.isSettingsOpen, true);
      expect(provider.shouldShowDrawerAfterSettings, false);
    });

    test('dispose does not throw', () {
      expect(() => provider.dispose(), returnsNormally);
    });
  });

  group('ViewState', () {
    test('all ViewState values exist', () {
      expect(
        ViewState.values,
        containsAll([
          ViewState.home,
          ViewState.discover,
          ViewState.settings,
          ViewState.search,
        ]),
      );
    });

    test('ViewState has exactly 5 values', () {
      expect(ViewState.values.length, 5);
    });

    test('all ViewState values are distinct', () {
      expect(ViewState.values.toSet().length, ViewState.values.length);
    });

    test('ViewState names are readable', () {
      for (final view in ViewState.values) {
        expect(view.name, isNotEmpty);
      }
    });
  });
}
