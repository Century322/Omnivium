import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';
import '../../app_logger.dart';
import '../../database_service.dart';
import 'cognitive_types.dart';
import 'memory_transaction.dart';

part 'procedural_memory.freezed.dart';

@freezed
class ProceduralMemory with _$ProceduralMemory {
  const ProceduralMemory._();

  const factory ProceduralMemory({
    required String id,
    required String lesson,
    required String trigger,
    required String action,
    @Default(1) int failureCount,
    required DateTime lastTriggered,
    @Default(50) double confidence,
    @Default(<String, dynamic>{}) Map<String, dynamic> metadata,
  }) = _ProceduralMemory;

  Map<String, dynamic> toJson() => {
    'id': id,
    'lesson': lesson,
    'trigger': trigger,
    'action': action,
    'failureCount': failureCount,
    'lastTriggered': lastTriggered.toIso8601String(),
    'confidence': confidence,
    'metadata': metadata,
  };

  factory ProceduralMemory.fromJson(Map<String, dynamic> json) => ProceduralMemory(
    id: json['id'] as String,
    lesson: json['lesson'] as String,
    trigger: json['trigger'] as String,
    action: json['action'] as String,
    failureCount: (json['failureCount'] as num?)?.toInt() ?? 1,
    lastTriggered: DateTime.parse(json['lastTriggered'] as String),
    confidence: (json['confidence'] as num?)?.toDouble() ?? 50,
    metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
  );
}

class ProceduralMemoryStore {
  static const _proceduresKey = 'cognitive_procedures';

  final DatabaseService _db;
  List<ProceduralMemory> _procedures = [];
  bool _initialized = false;
  bool _dirty = false;

  ProceduralMemoryStore(this._db);

  Future<void> init() async {
    if (_initialized) return;
    try {
      final json = await _db.getCache(_proceduresKey);
      if (json != null) {
        final list = jsonDecode(json) as List<dynamic>;
        _procedures = list.map((e) => ProceduralMemory.fromJson(e as Map<String, dynamic>)).toList();
      }
      _initialized = true;
    } catch (e, st) {
      AppLogger.instance.error('ProceduralMemoryStore init failed', error: e, stackTrace: st);
    }
  }

  Future<void> _persist() async {
    if (!_dirty) return;
    _dirty = false;
    try {
      await _db.putCache(_proceduresKey, jsonEncode(_procedures.map((p) => p.toJson()).toList()));
    } catch (e, st) {
      AppLogger.instance.error('ProceduralMemoryStore persist failed', error: e, stackTrace: st);
    }
  }

  void _markDirty() => _dirty = true;

  void registerWithTransaction(MemoryTransaction tx) {
    if (!_dirty) return;
    tx.register(_proceduresKey, () => jsonEncode(_procedures.map((p) => p.toJson()).toList()));
    _dirty = false;
  }

  List<ProceduralMemory> get procedures => List.unmodifiable(_procedures);

  ProceduralMemory? getProcedure(String id) {
    for (final p in _procedures) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<ProceduralMemory> getHighConfidenceProcedures({double minConfidence = 70}) =>
      _procedures.where((p) => p.confidence >= minConfidence).toList()
        ..sort((a, b) => b.confidence.compareTo(a.confidence));

  List<ProceduralMemory> getTriggeredProcedures(String context) {
    final contextLower = context.toLowerCase();
    return _procedures.where((p) => contextLower.contains(p.trigger.toLowerCase())).toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
  }

  Future<ProceduralMemory> recordLesson({
    required String lesson,
    required String trigger,
    required String action,
  }) async {
    final existing = _procedures.where((p) => p.lesson == lesson).firstOrNull;
    if (existing != null) {
      final updated = existing.copyWith(
        failureCount: existing.failureCount + 1,
        lastTriggered: DateTime.now(),
        confidence: (existing.confidence + 10).clamp(0, 100),
      );
      final idx = _procedures.indexWhere((p) => p.id == existing.id);
      _procedures[idx] = updated;
      _markDirty();
      return updated;
    }

    final procedure = ProceduralMemory(
      id: 'proc_${DateTime.now().millisecondsSinceEpoch}_${lesson.hashCode.abs()}',
      lesson: lesson,
      trigger: trigger,
      action: action,
      failureCount: 1,
      lastTriggered: DateTime.now(),
    );
    _procedures.add(procedure);
    _markDirty();
    return procedure;
  }

  Future<void> removeProcedure(String id) async {
    _procedures.removeWhere((p) => p.id == id);
    _markDirty();
  }

  String buildProcedureContext({double minConfidence = 60}) {
    final highConf = getHighConfidenceProcedures(minConfidence: minConfidence);
    if (highConf.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('[Learned Procedures]');
    for (final proc in highConf.take(5)) {
      buffer.writeln('- IF "${proc.trigger}" THEN ${proc.action} (confidence: ${proc.confidence.toStringAsFixed(0)}%)');
    }
    return buffer.toString();
  }

  int get procedureCount => _procedures.length;
}
