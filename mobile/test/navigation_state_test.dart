import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/navigation_cubit.dart';

void main() {
  group('NavigationState', () {
    test('initial state has default values', () {
      const state = NavigationState();
      expect(state.currentView, ViewState.home);
      expect(state.isIncognito, false);
      expect(state.isSettingsOpen, false);
      expect(state.shouldShowDrawerAfterSettings, false);
    });

    test('copyWith updates currentView', () {
      const state = NavigationState();
      final updated = state.copyWith(currentView: ViewState.search);
      expect(updated.currentView, ViewState.search);
      expect(updated.isIncognito, false);
    });

    test('copyWith updates isIncognito', () {
      const state = NavigationState();
      final updated = state.copyWith(isIncognito: true);
      expect(updated.isIncognito, true);
      expect(updated.currentView, ViewState.home);
    });

    test('copyWith preserves unmodified fields', () {
      const state = NavigationState(
        currentView: ViewState.discover,
        isIncognito: true,
      );
      final updated = state.copyWith(isSettingsOpen: true);
      expect(updated.currentView, ViewState.discover);
      expect(updated.isIncognito, true);
      expect(updated.isSettingsOpen, true);
    });
  });

  group('ViewState', () {
    test('has all expected values', () {
      expect(ViewState.values, contains(ViewState.home));
      expect(ViewState.values, contains(ViewState.discover));
      expect(ViewState.values, contains(ViewState.settings));
      expect(ViewState.values, contains(ViewState.search));
    });
  });
}
