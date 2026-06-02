import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ViewState { home, discover, settings, search }

class NavigationState {
  final ViewState currentView;
  final bool isIncognito;
  final bool isSettingsOpen;
  final bool shouldShowDrawerAfterSettings;

  const NavigationState({
    this.currentView = ViewState.home,
    this.isIncognito = false,
    this.isSettingsOpen = false,
    this.shouldShowDrawerAfterSettings = false,
  });

  NavigationState copyWith({
    ViewState? currentView,
    bool? isIncognito,
    bool? isSettingsOpen,
    bool? shouldShowDrawerAfterSettings,
  }) {
    return NavigationState(
      currentView: currentView ?? this.currentView,
      isIncognito: isIncognito ?? this.isIncognito,
      isSettingsOpen: isSettingsOpen ?? this.isSettingsOpen,
      shouldShowDrawerAfterSettings:
          shouldShowDrawerAfterSettings ?? this.shouldShowDrawerAfterSettings);
  }
}

class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(const NavigationState());

  ViewState get currentView => state.currentView;
  bool get isIncognito => state.isIncognito;
  bool get isSettingsOpen => state.isSettingsOpen;
  bool get shouldShowDrawerAfterSettings => state.shouldShowDrawerAfterSettings;

  void setCurrentView(ViewState view) {
    emit(state.copyWith(currentView: view));
  }

  void setIsIncognito(bool value) {
    emit(state.copyWith(isIncognito: value));
  }

  void setIsSettingsOpen(bool value) {
    emit(state.copyWith(
      isSettingsOpen: value,
      shouldShowDrawerAfterSettings: value ? state.shouldShowDrawerAfterSettings : false));
  }

  void openSettingsFromDrawer() {
    emit(state.copyWith(
      shouldShowDrawerAfterSettings: true,
      isSettingsOpen: true));
  }

  void closeSettingsAndReturnToDrawer() {
    emit(state.copyWith(
      isSettingsOpen: false,
      shouldShowDrawerAfterSettings: true));
  }

  void clearDrawerFlag() {
    emit(state.copyWith(shouldShowDrawerAfterSettings: false));
  }

  void goBack() {
    if (state.currentView != ViewState.home) {
      emit(state.copyWith(currentView: ViewState.home));
    }
  }
}
