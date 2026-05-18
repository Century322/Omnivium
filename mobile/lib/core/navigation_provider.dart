import 'package:flutter/material.dart';

enum ViewState { home, voice, discover, settings, library, search }

class NavigationProvider extends ChangeNotifier {
  ViewState _currentView = ViewState.home;
  ViewState get currentView => _currentView;
  bool _disposed = false;

  void setCurrentView(ViewState view) {
    _currentView = view;
    if (!_disposed) notifyListeners();
  }

  bool _isIncognito = false;
  bool get isIncognito => _isIncognito;
  void setIsIncognito(bool value) {
    _isIncognito = value;
    if (!_disposed) notifyListeners();
  }

  bool _isSettingsOpen = false;
  bool get isSettingsOpen => _isSettingsOpen;

  bool _shouldShowDrawerAfterSettings = false;
  bool get shouldShowDrawerAfterSettings => _shouldShowDrawerAfterSettings;

  void setIsSettingsOpen(bool value) {
    _isSettingsOpen = value;
    if (!value) {
      _shouldShowDrawerAfterSettings = false;
    }
    if (!_disposed) notifyListeners();
  }

  void openSettingsFromDrawer() {
    _shouldShowDrawerAfterSettings = true;
    _isSettingsOpen = true;
    if (!_disposed) notifyListeners();
  }

  void closeSettingsAndReturnToDrawer() {
    _isSettingsOpen = false;
    _shouldShowDrawerAfterSettings = true;
    if (!_disposed) notifyListeners();
  }

  void clearDrawerFlag() {
    _shouldShowDrawerAfterSettings = false;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
