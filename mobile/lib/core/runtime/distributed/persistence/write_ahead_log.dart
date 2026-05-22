import '../hybrid_logical_clock.dart';
import '../../plugins/persistence_backend.dart';

enum WalEntryType {
  beginTransaction,
  commitTransaction,
  rollbackTransaction,
  sessionCreate,
  sessionUpdate,
  sessionClose,
  leaseAcquire,
  leaseRelease,
  capabilityRegister,
  capabilityWithdraw,
  pluginLoad,
  pluginUnload,
  taskSchedule,
  taskComplete,
  taskFail,
  eventPublish,
  snapshotCreate,
  checkpoint,
}

class WalEntry {
  final int lsn;
  final WalEntryType type;
  final int hlcTime;
  final String sourceNodeId;
  final String transactionId;
  final Map<String, dynamic> data;
  final int checksum;

  const WalEntry({
    required this.lsn,
    required this.type,
    required this.hlcTime,
    required this.sourceNodeId,
    this.transactionId = '',
    required this.data,
    this.checksum = 0,
  });

  int computeChecksum() {
    return Object.hash(lsn, type.name, hlcTime, sourceNodeId, data.hashCode);
  }

  bool get isValid => checksum == 0 || computeChecksum() == checksum;

  Map<String, dynamic> toJson() => {
        'lsn': lsn,
        'type': type.name,
        'hlc': hlcTime,
        'src': sourceNodeId,
        'tx': transactionId,
        'data': data,
        'cksum': checksum,
      };

  factory WalEntry.fromJson(Map<String, dynamic> json) => WalEntry(
        lsn: json['lsn'] as int,
        type: WalEntryType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => WalEntryType.checkpoint,
        ),
        hlcTime: json['hlc'] as int,
        sourceNodeId: json['src'] as String,
        transactionId: json['tx'] as String? ?? '',
        data: json['data'] as Map<String, dynamic>? ?? {},
        checksum: json['cksum'] as int? ?? 0,
      );
}

class WalTransaction {
  final String transactionId;
  final int startLsn;
  final List<WalEntry> entries;
  final int startedAt;
  int? committedAt;

  WalTransaction({
    required this.transactionId,
    required this.startLsn,
    required this.startedAt,
  }) : entries = [];

  void addEntry(WalEntry entry) => entries.add(entry);

  bool get isCommitted => committedAt != null;

  int get entryCount => entries.length;
}

class WriteAheadLog {
  final String _nodeId;
  final HybridLogicalClock _clock;
  final List<WalEntry> _log = [];
  final Map<String, WalTransaction> _activeTransactions = {};
  final PersistenceBackend? _persistence;
  int _lsn = 0;
  int _checkpointLsn = 0;

  WriteAheadLog({
    required String nodeId,
    required HybridLogicalClock clock,
    PersistenceBackend? persistence,
  })  : _nodeId = nodeId,
        _clock = clock,
        _persistence = persistence;

  String get nodeId => _nodeId;
  int get currentLsn => _lsn;
  int get lastCheckpointLsn => _checkpointLsn;
  int get entryCount => _log.length;
  int get activeTransactionCount => _activeTransactions.length;
  List<WalEntry> get entries => List.unmodifiable(_log);

  WalEntry append(WalEntryType type, Map<String, dynamic> data, {String transactionId = ''}) {
    final now = _clock.tick();
    final entry = WalEntry(
      lsn: _lsn++,
      type: type,
      hlcTime: now.physicalTime,
      sourceNodeId: _nodeId,
      transactionId: transactionId,
      data: data,
      checksum: 0,
    );

    final withChecksum = WalEntry(
      lsn: entry.lsn,
      type: entry.type,
      hlcTime: entry.hlcTime,
      sourceNodeId: entry.sourceNodeId,
      transactionId: entry.transactionId,
      data: entry.data,
      checksum: entry.computeChecksum(),
    );

    _log.add(withChecksum);
    _persistEntry(withChecksum);

    if (transactionId.isNotEmpty) {
      final tx = _activeTransactions[transactionId];
      if (tx != null) {
        tx.addEntry(withChecksum);
      }
    }

    return withChecksum;
  }

  String beginTransaction() {
    final txId = 'tx_${_lsn}_${_clock.tick().physicalTime}';
    final now = _clock.tick();

    _activeTransactions[txId] = WalTransaction(
      transactionId: txId,
      startLsn: _lsn,
      startedAt: now.physicalTime,
    );

    append(WalEntryType.beginTransaction, {'txId': txId}, transactionId: txId);
    return txId;
  }

  bool commitTransaction(String txId) {
    final tx = _activeTransactions[txId];
    if (tx == null) return false;

    append(WalEntryType.commitTransaction, {'txId': txId}, transactionId: txId);
    tx.committedAt = _clock.tick().physicalTime;
    _activeTransactions.remove(txId);
    return true;
  }

  bool rollbackTransaction(String txId) {
    final tx = _activeTransactions[txId];
    if (tx == null) return false;

    append(WalEntryType.rollbackTransaction, {'txId': txId}, transactionId: txId);
    _activeTransactions.remove(txId);
    return true;
  }

  WalEntry checkpoint() {
    final entry = append(WalEntryType.checkpoint, {
      'lsn': _lsn,
      'previousCheckpoint': _checkpointLsn,
      'activeTransactions': _activeTransactions.keys.toList(),
    });
    _checkpointLsn = _lsn;
    return entry;
  }

  List<WalEntry> replay({int? fromLsn, int? toLsn}) {
    var filtered = _log;

    if (fromLsn != null) {
      filtered = filtered.where((e) => e.lsn >= fromLsn).toList();
    }
    if (toLsn != null) {
      filtered = filtered.where((e) => e.lsn <= toLsn).toList();
    }

    return filtered.where((e) => e.isValid).toList();
  }

  List<WalEntry> replayType(WalEntryType type) {
    return _log.where((e) => e.type == type && e.isValid).toList();
  }

  List<WalEntry> replayTransaction(String txId) {
    return _log
        .where((e) => e.transactionId == txId && e.isValid)
        .toList();
  }

  List<WalEntry> replaySinceCheckpoint() {
    return replay(fromLsn: _checkpointLsn);
  }

  void compact({int? keepLastN}) {
    final keep = keepLastN ?? 10000;
    if (_log.length <= keep) return;

    final checkpointEntries = _log.where((e) => e.type == WalEntryType.checkpoint).toList();
    final lastCheckpoint = checkpointEntries.isNotEmpty ? checkpointEntries.last : null;

    final cutoffLsn = lastCheckpoint?.lsn ?? (_log.last.lsn - keep);
    _log.removeWhere((e) => e.lsn < cutoffLsn && e.type != WalEntryType.checkpoint);
  }

  void truncate(int toLsn) {
    _log.removeWhere((e) => e.lsn > toLsn);
    _lsn = _log.isNotEmpty ? _log.last.lsn + 1 : 0;
  }

  bool validateIntegrity() {
    for (final entry in _log) {
      if (!entry.isValid) return false;
    }
    return true;
  }

  void clear() {
    _log.clear();
    _activeTransactions.clear();
    _lsn = 0;
    _checkpointLsn = 0;
  }

  void _persistEntry(WalEntry entry) {
    _persistence?.write('wal_${entry.lsn}', entry.toJson());
  }

  Future<void> loadFromPersistence() async {
    if (_persistence == null) return;
    final keys = await _persistence.listKeys('wal_');
    for (final key in keys) {
      final data = await _persistence.read(key);
      if (data != null) {
        final entry = WalEntry.fromJson(data);
        if (entry.isValid) {
          _log.add(entry);
          if (entry.lsn >= _lsn) _lsn = entry.lsn + 1;
        }
      }
    }
    _log.sort((a, b) => a.lsn.compareTo(b.lsn));
  }
}

class EventStore {
  final WriteAheadLog _wal;
  final Map<String, int> _streamVersions = {};
  final Map<String, List<WalEntry>> _streams = {};

  EventStore(this._wal);

  WriteAheadLog get wal => _wal;
  int get streamCount => _streams.length;

  WalEntry appendToStream(String streamId, WalEntryType type, Map<String, dynamic> data) {
    final version = _streamVersions[streamId] ?? 0;
    final entry = _wal.append(type, {
      'streamId': streamId,
      'version': version + 1,
      ...data,
    });

    _streamVersions[streamId] = version + 1;
    _streams.putIfAbsent(streamId, () => []).add(entry);

    return entry;
  }

  List<WalEntry> readStream(String streamId, {int? fromVersion}) {
    final entries = _streams[streamId] ?? [];
    if (fromVersion == null) return List.unmodifiable(entries);
    return entries.where((e) => (e.data['version'] as int? ?? 0) >= fromVersion).toList();
  }

  int streamVersion(String streamId) => _streamVersions[streamId] ?? 0;

  List<WalEntry> replayAllStreams({int? fromLsn}) {
    return _wal.replay(fromLsn: fromLsn);
  }

  void rebuildFromWal() {
    _streams.clear();
    _streamVersions.clear();

    for (final entry in _wal.entries) {
      final streamId = entry.data['streamId'] as String?;
      if (streamId == null) continue;

      _streams.putIfAbsent(streamId, () => []).add(entry);
      final version = entry.data['version'] as int? ?? 0;
      _streamVersions[streamId] = version > (_streamVersions[streamId] ?? 0)
          ? version
          : _streamVersions[streamId]!;
    }
  }

  void clear() {
    _streams.clear();
    _streamVersions.clear();
  }
}
