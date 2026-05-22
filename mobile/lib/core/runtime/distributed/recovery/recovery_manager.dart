import '../hybrid_logical_clock.dart';
import '../session_lease_manager.dart';

enum RecoveryAction {
  reclaimLease,
  replayJournal,
  markNodeDead,
  reconcileCapability,
  splitBrainResolve,
  noAction,
}

enum FailureType {
  nodePartition,
  halfOpenSession,
  leaseOrphan,
  replayDuplication,
  splitBrain,
  nodeCrash,
}

class FailureEvent {
  final String id;
  final FailureType type;
  final String sourceNodeId;
  final int detectedAt;
  final int hlcTime;
  final Map<String, dynamic> context;

  const FailureEvent({
    required this.id,
    required this.type,
    required this.sourceNodeId,
    required this.detectedAt,
    this.hlcTime = 0,
    this.context = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'source': sourceNodeId,
    'detected': detectedAt,
    'hlc': hlcTime,
    'ctx': context,
  };
}

class RecoveryDecision {
  final RecoveryAction action;
  final String targetId;
  final String reason;
  final Map<String, dynamic> params;

  const RecoveryDecision({
    required this.action,
    required this.targetId,
    required this.reason,
    this.params = const {},
  });

  bool get needsAction => action != RecoveryAction.noAction;
}

class RecoveryResult {
  final RecoveryAction action;
  final String targetId;
  final bool success;
  final String? error;
  final int recoveredAt;

  const RecoveryResult({
    required this.action,
    required this.targetId,
    this.success = true,
    this.error,
    required this.recoveredAt,
  });
}

class SplitBrainResolution {
  final String conflictId;
  final String winnerNodeId;
  final String loserNodeId;
  final int winnerIncarnation;
  final int loserIncarnation;
  final int resolvedAt;

  const SplitBrainResolution({
    required this.conflictId,
    required this.winnerNodeId,
    required this.loserNodeId,
    required this.winnerIncarnation,
    required this.loserIncarnation,
    required this.resolvedAt,
  });
}

class RecoveryManager {
  final String _localNodeId;
  final HybridLogicalClock _clock;
  final SessionLeaseManager _leaseManager;
  final List<FailureEvent> _failureLog = [];
  final List<RecoveryResult> _recoveryLog = [];
  final List<SplitBrainResolution> _splitBrainResolutions = [];
  final Set<String> _deduplicationSet = {};
  final Map<String, int> _lastKnownIncarnations = {};
  int _failureSeq = 0;

  RecoveryManager({
    required String localNodeId,
    required HybridLogicalClock clock,
    required SessionLeaseManager leaseManager,
  }) : _localNodeId = localNodeId,
       _clock = clock,
       _leaseManager = leaseManager;

  String get localNodeId => _localNodeId;
  List<FailureEvent> get failureLog => List.unmodifiable(_failureLog);
  List<RecoveryResult> get recoveryLog => List.unmodifiable(_recoveryLog);
  int get failureCount => _failureLog.length;
  int get recoveryCount => _recoveryLog.length;

  FailureEvent detectFailure(
    FailureType type,
    String sourceNodeId, {
    Map<String, dynamic> context = const {},
  }) {
    final now = _clock.tick();
    final event = FailureEvent(
      id: 'fail_${_failureSeq++}',
      type: type,
      sourceNodeId: sourceNodeId,
      detectedAt: now.physicalTime,
      hlcTime: now.physicalTime,
      context: context,
    );

    _failureLog.add(event);
    return event;
  }

  RecoveryDecision analyze(FailureEvent failure) {
    switch (failure.type) {
      case FailureType.nodePartition:
        return RecoveryDecision(
          action: RecoveryAction.markNodeDead,
          targetId: failure.sourceNodeId,
          reason: 'Node partition detected, marking as dead',
        );

      case FailureType.halfOpenSession:
        final sessionId = failure.context['sessionId'] as String?;
        if (sessionId == null) {
          return const RecoveryDecision(
            action: RecoveryAction.noAction,
            targetId: '',
            reason: 'No session ID in context',
          );
        }
        return RecoveryDecision(
          action: RecoveryAction.reclaimLease,
          targetId: sessionId,
          reason: 'Half-open session detected, reclaiming lease',
        );

      case FailureType.leaseOrphan:
        final sessionId = failure.context['sessionId'] as String?;
        if (sessionId == null) {
          return const RecoveryDecision(
            action: RecoveryAction.noAction,
            targetId: '',
            reason: 'No session ID in context',
          );
        }
        return RecoveryDecision(
          action: RecoveryAction.reclaimLease,
          targetId: sessionId,
          reason: 'Orphaned lease detected, reclaiming',
        );

      case FailureType.replayDuplication:
        final entryId = failure.context['entryId'] as String?;
        if (entryId == null) {
          return const RecoveryDecision(
            action: RecoveryAction.noAction,
            targetId: '',
            reason: 'No entry ID for deduplication',
          );
        }
        return RecoveryDecision(
          action: RecoveryAction.noAction,
          targetId: entryId,
          reason: 'Duplicate replay entry, skipping',
        );

      case FailureType.splitBrain:
        return RecoveryDecision(
          action: RecoveryAction.splitBrainResolve,
          targetId: failure.sourceNodeId,
          reason: 'Split brain detected, resolving by incarnation',
          params: failure.context,
        );

      case FailureType.nodeCrash:
        return RecoveryDecision(
          action: RecoveryAction.reconcileCapability,
          targetId: failure.sourceNodeId,
          reason: 'Node crash, reconciling capabilities',
        );
    }
  }

  RecoveryResult execute(RecoveryDecision decision) {
    final now = _clock.tick().physicalTime;

    switch (decision.action) {
      case RecoveryAction.reclaimLease:
        final reclaimed = _leaseManager.revoke(decision.targetId, _localNodeId);
        final result = RecoveryResult(
          action: decision.action,
          targetId: decision.targetId,
          success: reclaimed,
          recoveredAt: now,
        );
        _recoveryLog.add(result);
        return result;

      case RecoveryAction.markNodeDead:
        final result = RecoveryResult(
          action: decision.action,
          targetId: decision.targetId,
          success: true,
          recoveredAt: now,
        );
        _recoveryLog.add(result);
        return result;

      case RecoveryAction.reconcileCapability:
        final result = RecoveryResult(
          action: decision.action,
          targetId: decision.targetId,
          success: true,
          recoveredAt: now,
        );
        _recoveryLog.add(result);
        return result;

      case RecoveryAction.splitBrainResolve:
        final resolution = _resolveSplitBrain(decision.params);
        final result = RecoveryResult(
          action: decision.action,
          targetId: decision.targetId,
          success: resolution != null,
          recoveredAt: now,
        );
        _recoveryLog.add(result);
        return result;

      case RecoveryAction.noAction:
        return RecoveryResult(
          action: decision.action,
          targetId: decision.targetId,
          success: true,
          recoveredAt: now,
        );

      case RecoveryAction.replayJournal:
        return RecoveryResult(
          action: decision.action,
          targetId: decision.targetId,
          success: true,
          recoveredAt: now,
        );
    }
  }

  SplitBrainResolution? _resolveSplitBrain(Map<String, dynamic> params) {
    final nodeA = params['nodeA'] as String?;
    final nodeB = params['nodeB'] as String?;
    final incA = params['incarnationA'] as int? ?? 0;
    final incB = params['incarnationB'] as int? ?? 0;

    if (nodeA == null || nodeB == null) return null;

    final winner = incA >= incB ? nodeA : nodeB;
    final loser = winner == nodeA ? nodeB : nodeA;
    final winnerInc = winner == nodeA ? incA : incB;
    final loserInc = winner == nodeA ? incB : incA;

    final resolution = SplitBrainResolution(
      conflictId: 'sb_${_splitBrainResolutions.length}',
      winnerNodeId: winner,
      loserNodeId: loser,
      winnerIncarnation: winnerInc,
      loserIncarnation: loserInc,
      resolvedAt: _clock.tick().physicalTime,
    );

    _splitBrainResolutions.add(resolution);
    return resolution;
  }

  bool isDuplicate(String entryId) {
    if (_deduplicationSet.contains(entryId)) return true;
    _deduplicationSet.add(entryId);
    return false;
  }

  void updateIncarnation(String nodeId, int incarnation) {
    _lastKnownIncarnations[nodeId] = incarnation;
  }

  int? lastKnownIncarnation(String nodeId) => _lastKnownIncarnations[nodeId];

  RecoveryResult detectAndRecover(
    FailureType type,
    String sourceNodeId, {
    Map<String, dynamic> context = const {},
  }) {
    final failure = detectFailure(type, sourceNodeId, context: context);
    final decision = analyze(failure);
    return execute(decision);
  }

  void clearHistory() {
    _failureLog.clear();
    _recoveryLog.clear();
    _splitBrainResolutions.clear();
    _deduplicationSet.clear();
  }
}
