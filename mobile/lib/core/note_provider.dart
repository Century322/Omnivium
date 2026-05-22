import 'package:flutter/material.dart';
import 'note_service.dart';
import 'app_logger.dart';

class NoteProvider extends ChangeNotifier {
  final NoteService _service = NoteService.instance;

  List<NoteItem> get items => _service.items;
  List<NoteItem> get notes => _service.getNotes();
  List<NoteItem> get todos => _service.getTodos();
  List<NoteItem> get schedules => _service.getSchedules();
  List<NoteItem> get todaySchedules => _service.getTodaySchedules();
  List<NoteItem> get pendingTodos => _service.getPendingTodos();

  Future<void> init() async {
    try {
      await _service.init();
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.instance.warning(
        'NoteProvider init failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> addItem(NoteItem item) async {
    try {
      await _service.addItem(item);
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.instance.warning(
        'NoteProvider addItem failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> updateItem(NoteItem item) async {
    try {
      await _service.updateItem(item);
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.instance.warning(
        'NoteProvider updateItem failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _service.deleteItem(id);
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.instance.warning(
        'NoteProvider deleteItem failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> toggleDone(String id) async {
    try {
      await _service.toggleDone(id);
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.instance.warning(
        'NoteProvider toggleDone failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
