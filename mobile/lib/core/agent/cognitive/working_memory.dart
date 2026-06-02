import 'package:freezed_annotation/freezed_annotation.dart';
import 'cognitive_types.dart';
import 'entity_layer.dart';
import 'memory_event.dart';

part 'working_memory.freezed.dart';

@freezed
class WorkingMemoryItem with _$WorkingMemoryItem {
  const factory WorkingMemoryItem({
    required String id,
    required String content,
    required MemoryType type,
    @Default(50) int importance,
    required DateTime addedAt,
    required DateTime lastAccessedAt,
    @Default(1.0) double relevanceScore,
  }) = _WorkingMemoryItem;
}

class WorkingMemory {
  final int maxItems;
  final List<WorkingMemoryItem> _items = [];

  String? _currentWorkspaceId;
  final Set<String> _activeEntityIds = {};
  final Set<String> _activeGoalIds = {};
  final List<String> _recentEventIds = [];

  WorkingMemory({this.maxItems = 50});

  List<WorkingMemoryItem> get items => List.unmodifiable(_items);
  String? get currentWorkspaceId => _currentWorkspaceId;
  Set<String> get activeEntityIds => Set.unmodifiable(_activeEntityIds);
  Set<String> get activeGoalIds => Set.unmodifiable(_activeGoalIds);
  List<String> get recentEventIds => List.unmodifiable(_recentEventIds);

  void setWorkspace(String? workspaceId) {
    _currentWorkspaceId = workspaceId;
  }

  void addEntity(String entityId) {
    _activeEntityIds.add(entityId);
    if (_activeEntityIds.length > 20) {
      _activeEntityIds.remove(_activeEntityIds.first);
    }
  }

  void addGoal(String goalId) {
    _activeGoalIds.add(goalId);
    if (_activeGoalIds.length > 10) {
      _activeGoalIds.remove(_activeGoalIds.first);
    }
  }

  void addEvent(String eventId) {
    _recentEventIds.add(eventId);
    if (_recentEventIds.length > 30) {
      _recentEventIds.removeAt(0);
    }
  }

  void addItem(WorkingMemoryItem item) {
    final existingIdx = _items.indexWhere((i) => i.id == item.id);
    if (existingIdx >= 0) {
      _items[existingIdx] = item.copyWith(
        lastAccessedAt: DateTime.now(),
        relevanceScore: item.relevanceScore,
      );
    } else {
      _items.add(item);
    }
    _evict();
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
  }

  void touch(String id) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(lastAccessedAt: DateTime.now());
    }
  }

  void _evict() {
    while (_items.length > maxItems) {
      int lowestIdx = 0;
      double lowestScore = _scoreItem(_items[0]);
      for (var i = 1; i < _items.length; i++) {
        final score = _scoreItem(_items[i]);
        if (score < lowestScore) {
          lowestScore = score;
          lowestIdx = i;
        }
      }
      _items.removeAt(lowestIdx);
    }
  }

  double _scoreItem(WorkingMemoryItem item) {
    final ageHours = DateTime.now().difference(item.lastAccessedAt).inHours;
    final ageDecay = 1.0 / (1.0 + ageHours * 0.1);
    return item.importance * 0.5 + item.relevanceScore * 30 + ageDecay * 20;
  }

  List<WorkingMemoryItem> getSortedItems() {
    final sorted = List<WorkingMemoryItem>.from(_items);
    sorted.sort((a, b) => _scoreItem(b).compareTo(_scoreItem(a)));
    return sorted;
  }

  void clear() {
    _items.clear();
    _activeEntityIds.clear();
    _activeGoalIds.clear();
    _recentEventIds.clear();
    _currentWorkspaceId = null;
  }
}
