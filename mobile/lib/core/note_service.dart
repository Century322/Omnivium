import 'app_logger.dart';
import 'dart:convert';
import 'database_service.dart';
import 'supabase_sync_service.dart';

enum NoteType { text, todo, schedule }

NoteType _parseNoteType(dynamic value) {
  if (value is String) {
    return NoteType.values.where((e) => e.name == value).firstOrNull ??
        NoteType.text;
  }
  if (value is int) {
    return NoteType.values[value.clamp(0, NoteType.values.length - 1)];
  }
  return NoteType.text;
}

class NoteItem {
  final String id;
  final String title;
  final String content;
  final NoteType type;
  final bool isDone;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteItem({
    required this.id,
    required this.title,
    required this.content,
    this.type = NoteType.text,
    this.isDone = false,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'type': type.name,
    'isDone': isDone,
    'dueDate': dueDate?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory NoteItem.fromJson(Map<String, dynamic> json) => NoteItem(
    id: json['id'] as String,
    title: json['title'] as String,
    content: json['content'] as String? ?? '',
    type: _parseNoteType(json['type']),
    isDone: json['isDone'] as bool? ?? false,
    dueDate: json['dueDate'] != null
        ? DateTime.parse(json['dueDate'] as String)
        : null,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  NoteItem copyWith({
    String? title,
    String? content,
    NoteType? type,
    bool? isDone,
    DateTime? dueDate,
  }) {
    return NoteItem(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      isDone: isDone ?? this.isDone,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class NoteService {
  static final NoteService _instance = NoteService._();
  static NoteService get instance => _instance;
  NoteService._();

  static const _boxKey = 'omnivium_notes';

  List<NoteItem> _items = [];
  List<NoteItem> get items => List.unmodifiable(_items);

  bool _initialized = false;

  void reset() {
    _items = [];
    _initialized = false;
  }

  Future<void> init() async {
    if (_initialized) return;
    final db = DatabaseService.instance;
    if (!db.isInitialized) return;

    final raw = db.data.get(_boxKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _items = list
            .map((item) => NoteItem.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e, stackTrace) {
        AppLogger.instance.warning(
          'Notes load failed',
          error: e,
          stackTrace: stackTrace,
        );
        _items = [];
      }
    }
    _initialized = true;
    await _mergeCloudNotes();
  }

  Future<void> _mergeCloudNotes() async {
    final sync = SupabaseSyncService.instance;
    if (!sync.isAvailable) return;
    try {
      final cloudNotes = await sync.fetchNotes();
      final db = DatabaseService.instance;
      for (final cloud in cloudNotes) {
        final id = cloud['id'] as String?;
        if (id == null) continue;
        final localIdx = _items.indexWhere((n) => n.id == id);
        if (localIdx < 0) {
          try {
            _items.add(NoteItem.fromJson(cloud));
          } catch (e) {
            AppLogger.instance.warning('Parse cloud note failed', error: e);
          }
        } else {
          final cloudUpdated = cloud['updated_at'] as String?;
          final localUpdated = _items[localIdx].updatedAt.toIso8601String();
          if (cloudUpdated != null &&
              cloudUpdated.compareTo(localUpdated) > 0) {
            try {
              _items[localIdx] = NoteItem.fromJson(cloud);
            } catch (e) {
              AppLogger.instance.warning('Update note from cloud failed', error: e);
            }
          }
        }
      }
      await db.data.put(
        _boxKey,
        jsonEncode(_items.map((n) => n.toJson()).toList()),
      );
    } catch (e) {
      AppLogger.instance.info('Cloud notes merge failed: $e');
    }
  }

  Future<void> _save({NoteItem? changedItem}) async {
    final db = DatabaseService.instance;
    await db.data.put(
      _boxKey,
      jsonEncode(_items.map((n) => n.toJson()).toList()),
    );
    if (changedItem != null) {
      _syncItemToCloud(changedItem);
    }
  }

  void _syncItemToCloud(NoteItem item) {
    final sync = SupabaseSyncService.instance;
    if (!sync.isAvailable) return;
    sync.upsertNote({
      'id': item.id,
      'title': item.title,
      'content': item.content,
      'type': item.type.name,
      'is_done': item.isDone,
      'due_date': item.dueDate?.toIso8601String(),
      'created_at': item.createdAt.toIso8601String(),
      'updated_at': item.updatedAt.toIso8601String(),
    });
  }

  Future<void> addItem(NoteItem item) async {
    _items.insert(0, item);
    await _save(changedItem: item);
  }

  Future<void> updateItem(NoteItem item) async {
    final idx = _items.indexWhere((n) => n.id == item.id);
    if (idx != -1) {
      _items[idx] = item;
      await _save(changedItem: item);
    }
  }

  Future<void> deleteItem(String id) async {
    _items.removeWhere((n) => n.id == id);
    await _save();
  }

  Future<void> toggleDone(String id) async {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(isDone: !_items[idx].isDone);
      await _save(changedItem: _items[idx]);
    }
  }

  List<NoteItem> getNotes() =>
      _items.where((n) => n.type == NoteType.text).toList();
  List<NoteItem> getTodos() =>
      _items.where((n) => n.type == NoteType.todo).toList();
  List<NoteItem> getSchedules() =>
      _items.where((n) => n.type == NoteType.schedule).toList();
  List<NoteItem> getTodaySchedules() {
    final now = DateTime.now();
    return _items
        .where(
          (n) {
            final due = n.dueDate;
            return n.type == NoteType.schedule &&
              due != null &&
              due.year == now.year &&
              due.month == now.month &&
              due.day == now.day;
          },
        )
        .toList();
  }

  List<NoteItem> getPendingTodos() =>
      _items.where((n) => n.type == NoteType.todo && !n.isDone).toList();
}
