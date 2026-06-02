import 'dart:convert';
import '../../app_logger.dart';
import '../../database_service.dart';
import 'cognitive_types.dart';
import 'memory_transaction.dart';

class SpeakerEntry {
  final String speakerId;
  final String speakerType;
  final String? displayName;
  final DateTime lastSeenAt;
  final int messageCount;
  final Map<String, dynamic> metadata;

  const SpeakerEntry({
    required this.speakerId,
    required this.speakerType,
    this.displayName,
    required this.lastSeenAt,
    this.messageCount = 1,
    this.metadata = const {},
  });

  SpeakerEntry copyWith({
    String? displayName,
    DateTime? lastSeenAt,
    int? messageCount,
    Map<String, dynamic>? metadata,
  }) => SpeakerEntry(
    speakerId: speakerId,
    speakerType: speakerType,
    displayName: displayName ?? this.displayName,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    messageCount: messageCount ?? this.messageCount,
    metadata: metadata ?? this.metadata,
  );

  Map<String, dynamic> toJson() => {
    'speakerId': speakerId,
    'speakerType': speakerType,
    'displayName': displayName,
    'lastSeenAt': lastSeenAt.toIso8601String(),
    'messageCount': messageCount,
    'metadata': metadata,
  };

  factory SpeakerEntry.fromJson(Map<String, dynamic> json) => SpeakerEntry(
    speakerId: json['speakerId'] as String,
    speakerType: json['speakerType'] as String,
    displayName: json['displayName'] as String?,
    lastSeenAt: DateTime.parse(json['lastSeenAt'] as String),
    messageCount: (json['messageCount'] as num?)?.toInt() ?? 1,
    metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
  );
}

class SpeakerGraph {
  static const _speakersKey = 'cognitive_speakers';

  final DatabaseService _db;
  List<SpeakerEntry> _speakers = [];
  bool _initialized = false;
  bool _dirty = false;

  SpeakerGraph(this._db);

  Future<void> init() async {
    if (_initialized) return;
    try {
      final json = await _db.getCache(_speakersKey);
      if (json != null) {
        final list = jsonDecode(json) as List<dynamic>;
        _speakers = list.map((e) => SpeakerEntry.fromJson(e as Map<String, dynamic>)).toList();
      }
      _initialized = true;
    } catch (e, st) {
      AppLogger.instance.error('SpeakerGraph init failed', error: e, stackTrace: st);
    }
  }

  Future<void> _persist() async {
    if (!_dirty) return;
    _dirty = false;
    try {
      await _db.putCache(_speakersKey, jsonEncode(_speakers.map((s) => s.toJson()).toList()));
    } catch (e, st) {
      AppLogger.instance.error('SpeakerGraph persist failed', error: e, stackTrace: st);
    }
  }

  void _markDirty() => _dirty = true;

  void registerWithTransaction(MemoryTransaction tx) {
    if (!_dirty) return;
    tx.register(_speakersKey, () => jsonEncode(_speakers.map((s) => s.toJson()).toList()));
    _dirty = false;
  }

  List<SpeakerEntry> get speakers => List.unmodifiable(_speakers);

  SpeakerEntry? getSpeaker(String speakerId) {
    for (final s in _speakers) {
      if (s.speakerId == speakerId) return s;
    }
    return null;
  }

  List<SpeakerEntry> getSpeakersByType(String speakerType) =>
      _speakers.where((s) => s.speakerType == speakerType).toList()
        ..sort((a, b) => b.lastSeenAt.compareTo(a.lastSeenAt));

  List<SpeakerEntry> getFrequentSpeakers({int minMessages = 5}) =>
      _speakers.where((s) => s.messageCount >= minMessages).toList()
        ..sort((a, b) => b.messageCount.compareTo(a.messageCount));

  List<SpeakerEntry> getRecentSpeakers({int limit = 10}) =>
      _speakers.toList()..sort((a, b) => b.lastSeenAt.compareTo(a.lastSeenAt));

  Future<void> recordSpeaker({
    required String speakerId,
    required String speakerType,
    String? displayName,
  }) async {
    final idx = _speakers.indexWhere((s) => s.speakerId == speakerId);
    if (idx >= 0) {
      _speakers[idx] = _speakers[idx].copyWith(
        displayName: displayName ?? _speakers[idx].displayName,
        lastSeenAt: DateTime.now(),
        messageCount: _speakers[idx].messageCount + 1,
      );
    } else {
      _speakers.add(SpeakerEntry(
        speakerId: speakerId,
        speakerType: speakerType,
        displayName: displayName,
        lastSeenAt: DateTime.now(),
      ));
    }
    _markDirty();
  }

  Future<void> removeSpeaker(String speakerId) async {
    _speakers.removeWhere((s) => s.speakerId == speakerId);
    _markDirty();
  }

  int get speakerCount => _speakers.length;
}
