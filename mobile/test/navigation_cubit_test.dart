import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/navigation_cubit.dart';

void main() {
  group('NavigationCubit', () {
    late NavigationCubit cubit;

    setUp(() {
      cubit = NavigationCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has default values', () {
      expect(cubit.state.currentView, ViewState.home);
      expect(cubit.state.isIncognito, false);
      expect(cubit.state.isSettingsOpen, false);
      expect(cubit.state.shouldShowDrawerAfterSettings, false);
    });

    test('setCurrentView emits correct view', () {
      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<NavigationState>()
              .having((s) => s.currentView, 'currentView', ViewState.discover),
        ]),
      );
      cubit.setCurrentView(ViewState.discover);
    });

    test('setIsIncognito toggles incognito mode', () {
      cubit.setIsIncognito(true);
      expect(cubit.state.isIncognito, true);

      cubit.setIsIncognito(false);
      expect(cubit.state.isIncognito, false);
    });

    test('setIsSettingsOpen sets settings open', () {
      cubit.setIsSettingsOpen(true);
      expect(cubit.state.isSettingsOpen, true);
      expect(cubit.state.shouldShowDrawerAfterSettings, false);
    });

    test('setIsSettingsOpen false clears drawer flag', () {
      cubit.openSettingsFromDrawer();
      expect(cubit.state.shouldShowDrawerAfterSettings, true);

      cubit.setIsSettingsOpen(false);
      expect(cubit.state.isSettingsOpen, false);
      expect(cubit.state.shouldShowDrawerAfterSettings, false);
    });

    test('openSettingsFromDrawer sets both flags', () {
      cubit.openSettingsFromDrawer();
      expect(cubit.state.isSettingsOpen, true);
      expect(cubit.state.shouldShowDrawerAfterSettings, true);
    });

    test('closeSettingsAndReturnToDrawer closes settings and sets drawer flag', () {
      cubit.setIsSettingsOpen(true);
      cubit.closeSettingsAndReturnToDrawer();
      expect(cubit.state.isSettingsOpen, false);
      expect(cubit.state.shouldShowDrawerAfterSettings, true);
    });

    test('clearDrawerFlag clears the flag', () {
      cubit.openSettingsFromDrawer();
      cubit.clearDrawerFlag();
      expect(cubit.state.shouldShowDrawerAfterSettings, false);
    });

    test('goBack sets view to home if not already home', () {
      cubit.setCurrentView(ViewState.search);
      cubit.goBack();
      expect(cubit.state.currentView, ViewState.home);
    });

    test('goBack does nothing if already home', () {
      final stateBefore = cubit.state;
      cubit.goBack();
      expect(cubit.state.currentView, stateBefore.currentView);
    });

    test('shortcut getters match state', () {
      cubit.setCurrentView(ViewState.settings);
      expect(cubit.currentView, ViewState.settings);
      expect(cubit.isSettingsOpen, cubit.state.isSettingsOpen);
      expect(cubit.isIncognito, cubit.state.isIncognito);
      expect(cubit.shouldShowDrawerAfterSettings,
          cubit.state.shouldShowDrawerAfterSettings);
    });
  });
}
