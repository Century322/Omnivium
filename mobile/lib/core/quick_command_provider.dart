import 'package:flutter/material.dart';
import 'quick_command_service.dart';
import 'app_logger.dart';

class QuickCommandProvider extends ChangeNotifier {
  final QuickCommandService _service = QuickCommandService.instance;

  List<QuickCommand> get commands => _service.commands;
  Set<String> get categories => _service.categories;

  Future<void> init() async {
    try {
      await _service.init();
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'QuickCommand init failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
    notifyListeners();
  }

  Future<void> addCommand(QuickCommand command) async {
    try {
      await _service.addCommand(command);
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'QuickCommand add failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
    notifyListeners();
  }

  Future<void> updateCommand(QuickCommand command) async {
    try {
      await _service.updateCommand(command);
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'QuickCommand update failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
    notifyListeners();
  }

  Future<void> deleteCommand(String id) async {
    try {
      await _service.deleteCommand(id);
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'QuickCommand delete failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
    notifyListeners();
  }

  Future<void> reorderCommands(int oldIndex, int newIndex) async {
    try {
      await _service.reorderCommands(oldIndex, newIndex);
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'QuickCommand reorder failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    try {
      await _service.resetToDefaults();
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'QuickCommand reset failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
    notifyListeners();
  }

  List<QuickCommand> getCommandsByCategory(String category) {
    return _service.getCommandsByCategory(category);
  }
}
