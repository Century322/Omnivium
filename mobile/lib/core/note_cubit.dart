import 'di/app_di.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'note_service.dart';
import 'app_logger.dart';

class NoteState {
  final List<NoteItem> items;

  const NoteState({this.items = const []});

  List<NoteItem> get notes => items.where((i) => i.type == NoteType.text).toList();
  List<NoteItem> get todos => items.where((i) => i.type == NoteType.todo).toList();
  List<NoteItem> get schedules => items.where((i) => i.type == NoteType.schedule).toList();
  List<NoteItem> get todaySchedules => schedules
      .where((i) {
        final now = DateTime.now();
        final scheduled = i.dueDate;
        if (scheduled == null) return false;
        return scheduled.year == now.year &&
            scheduled.month == now.month &&
            scheduled.day == now.day;
      })
      .toList();
  List<NoteItem> get pendingTodos => todos.where((i) => !i.isDone).toList();

  NoteState copyWith({List<NoteItem>? items}) {
    return NoteState(items: items ?? this.items);
  }
}

class NoteCubit extends Cubit<NoteState> {
  NoteCubit() : super(const NoteState());

  final NoteService _service = getIt<NoteService>();

  List<NoteItem> get items => state.items;
  List<NoteItem> get notes => state.notes;
  List<NoteItem> get todos => state.todos;
  List<NoteItem> get schedules => state.schedules;
  List<NoteItem> get todaySchedules => state.todaySchedules;
  List<NoteItem> get pendingTodos => state.pendingTodos;

  void _refresh() {
    emit(state.copyWith(items: List.unmodifiable(_service.items)));
  }

  Future<void> init() async {
    try {
      await _service.init();
      _refresh();
    } catch (e, stackTrace) {
      AppLogger.instance.warning(
        'NoteCubit init failed',
        error: e,
        stackTrace: stackTrace);
    }
  }

  Future<void> addItem(NoteItem item) async {
    try {
      await _service.addItem(item);
      _refresh();
    } catch (e, stackTrace) {
      AppLogger.instance.warning(
        'NoteCubit addItem failed',
        error: e,
        stackTrace: stackTrace);
    }
  }

  Future<void> updateItem(NoteItem item) async {
    try {
      await _service.updateItem(item);
      _refresh();
    } catch (e, stackTrace) {
      AppLogger.instance.warning(
        'NoteCubit updateItem failed',
        error: e,
        stackTrace: stackTrace);
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _service.deleteItem(id);
      _refresh();
    } catch (e, stackTrace) {
      AppLogger.instance.warning(
        'NoteCubit deleteItem failed',
        error: e,
        stackTrace: stackTrace);
    }
  }

  Future<void> toggleDone(String id) async {
    try {
      await _service.toggleDone(id);
      _refresh();
    } catch (e, stackTrace) {
      AppLogger.instance.warning(
        'NoteCubit toggleDone failed',
        error: e,
        stackTrace: stackTrace);
    }
  }
}
