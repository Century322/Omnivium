import 'package:flutter_bloc/flutter_bloc.dart';
import 'quick_command_service.dart';
import 'app_logger.dart';

class QuickCommandState {
  final List<QuickCommand> commands;
  final Set<String> categories;

  const QuickCommandState({
    this.commands = const [],
    this.categories = const {},
  });

  QuickCommandState copyWith({
    List<QuickCommand>? commands,
    Set<String>? categories,
  }) {
    return QuickCommandState(
      commands: commands ?? this.commands,
      categories: categories ?? this.categories);
  }
}

class QuickCommandCubit extends Cubit<QuickCommandState> {
  QuickCommandCubit() : super(const QuickCommandState());

  final QuickCommandService _service = QuickCommandService.instance;

  List<QuickCommand> get commands => state.commands;
  Set<String> get categories => state.categories;

  void _refresh() {
    emit(state.copyWith(
      commands: List.unmodifiable(_service.commands),
      categories: Set.unmodifiable(_service.categories)));
  }

  Future<void> init() async {
    try {
      await _service.init();
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'QuickCommand init failed',
        error: e,
        stackTrace: stackTrace);
    }
    _refresh();
  }

  Future<void> addCommand(QuickCommand command) async {
    try {
      await _service.addCommand(command);
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'QuickCommand add failed',
        error: e,
        stackTrace: stackTrace);
    }
    _refresh();
  }

  Future<void> updateCommand(QuickCommand command) async {
    try {
      await _service.updateCommand(command);
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'QuickCommand update failed',
        error: e,
        stackTrace: stackTrace);
    }
    _refresh();
  }

  Future<void> deleteCommand(String id) async {
    try {
      await _service.deleteCommand(id);
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'QuickCommand delete failed',
        error: e,
        stackTrace: stackTrace);
    }
    _refresh();
  }

  Future<void> reorderCommands(int oldIndex, int newIndex) async {
    try {
      await _service.reorderCommands(oldIndex, newIndex);
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'QuickCommand reorder failed',
        error: e,
        stackTrace: stackTrace);
    }
    _refresh();
  }

  Future<void> resetToDefaults() async {
    try {
      await _service.resetToDefaults();
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'QuickCommand reset failed',
        error: e,
        stackTrace: stackTrace);
    }
    _refresh();
  }

  List<QuickCommand> getCommandsByCategory(String category) {
    return _service.getCommandsByCategory(category);
  }
}
