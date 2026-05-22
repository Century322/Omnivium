import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../stability/security.dart';
import 'runtime_law.dart';

enum EscalationLevel {
  warning,
  restricted,
  terminated,
}

class LawDecisionRecord {
  final int seq;
  final int timestamp;
  final String sandboxId;
  final String operationType;
  final RuntimeLawId? violatedLaw;
  final bool compliant;
  final String? capabilityId;
  final String? callerId;
  final TrustLevel? callerTrust;
  final EscalationLevel escalationBefore;
  final EscalationLevel escalationAfter;

  const LawDecisionRecord({
    required this.seq,
    required this.timestamp,
    required this.sandboxId,
    required this.operationType,
    this.violatedLaw,
    required this.compliant,
    this.capabilityId,
    this.callerId,
    this.callerTrust,
    required this.escalationBefore,
    required this.escalationAfter,
  });

  Map<String, dynamic> toJson() => {
        'seq': seq,
        'ts': timestamp,
        'sandbox': sandboxId,
        'op': operationType,
        'law': violatedLaw?.name,
        'compliant': compliant,
        'cap': capabilityId,
        'caller': callerId,
        'trust': callerTrust?.name,
        'escBefore': escalationBefore.name,
        'escAfter': escalationAfter.name,
      };
}

class LawStatistics {
  final Map<RuntimeLawId, int> violationCounts;
  final Map<String, int> sandboxViolationCounts;
  final Map<String, int> capabilityViolationCounts;
  final Map<EscalationLevel, int> escalationDistribution;
  final int totalDecisions;
  final int totalViolations;
  final int totalCompliant;
  final double complianceRate;

  const LawStatistics({
    required this.violationCounts,
    required this.sandboxViolationCounts,
    required this.capabilityViolationCounts,
    required this.escalationDistribution,
    required this.totalDecisions,
    required this.totalViolations,
    required this.totalCompliant,
    required this.complianceRate,
  });

  List<RuntimeLawId> mostViolatedLaws({int limit = 5}) {
    final sorted = violationCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  List<String> mostDangerousSandboxes({int limit = 5}) {
    final sorted = sandboxViolationCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  List<String> mostAbusedCapabilities({int limit = 5}) {
    final sorted = capabilityViolationCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }
}

class EscalationPath {
  final String sandboxId;
  final List<LawDecisionRecord> decisions;
  final List<EscalationLevel> levelTransitions;

  const EscalationPath({
    required this.sandboxId,
    required this.decisions,
    required this.levelTransitions,
  });

  bool get reachedTermination =>
      levelTransitions.contains(EscalationLevel.terminated);
}

class ConstitutionalTraceGraph {
  final List<LawDecisionRecord> _decisions = [];
  int _seq = 0;

  List<LawDecisionRecord> get decisions => List.unmodifiable(_decisions);
  int get totalDecisions => _decisions.length;

  LawDecisionRecord record({
    required String sandboxId,
    required String operationType,
    RuntimeLawId? violatedLaw,
    required bool compliant,
    String? capabilityId,
    String? callerId,
    TrustLevel? callerTrust,
    required EscalationLevel escalationBefore,
    required EscalationLevel escalationAfter,
    required int timestamp,
  }) {
    final record = LawDecisionRecord(
      seq: _seq++,
      timestamp: timestamp,
      sandboxId: sandboxId,
      operationType: operationType,
      violatedLaw: violatedLaw,
      compliant: compliant,
      capabilityId: capabilityId,
      callerId: callerId,
      callerTrust: callerTrust,
      escalationBefore: escalationBefore,
      escalationAfter: escalationAfter,
    );
    _decisions.add(record);
    return record;
  }

  LawStatistics computeStatistics() {
    final violationCounts = <RuntimeLawId, int>{};
    final sandboxViolationCounts = <String, int>{};
    final capabilityViolationCounts = <String, int>{};
    final escalationDistribution = <EscalationLevel, int>{};

    var totalViolations = 0;
    var totalCompliant = 0;

    for (final d in _decisions) {
      if (d.compliant) {
        totalCompliant++;
      } else {
        totalViolations++;
        if (d.violatedLaw != null) {
          violationCounts[d.violatedLaw!] = (violationCounts[d.violatedLaw!] ?? 0) + 1;
        }
        sandboxViolationCounts[d.sandboxId] =
            (sandboxViolationCounts[d.sandboxId] ?? 0) + 1;
        if (d.capabilityId != null) {
          capabilityViolationCounts[d.capabilityId!] =
              (capabilityViolationCounts[d.capabilityId!] ?? 0) + 1;
        }
      }
      escalationDistribution[d.escalationAfter] =
          (escalationDistribution[d.escalationAfter] ?? 0) + 1;
    }

    final total = _decisions.length;
    final rate = total > 0 ? totalCompliant / total : 1.0;

    return LawStatistics(
      violationCounts: violationCounts,
      sandboxViolationCounts: sandboxViolationCounts,
      capabilityViolationCounts: capabilityViolationCounts,
      escalationDistribution: escalationDistribution,
      totalDecisions: total,
      totalViolations: totalViolations,
      totalCompliant: totalCompliant,
      complianceRate: rate,
    );
  }

  EscalationPath escalationPathFor(String sandboxId) {
    final sandboxDecisions =
        _decisions.where((d) => d.sandboxId == sandboxId).toList();
    final transitions = <EscalationLevel>[];

    EscalationLevel? lastLevel;
    for (final d in sandboxDecisions) {
      if (lastLevel == null || d.escalationAfter != lastLevel) {
        transitions.add(d.escalationAfter);
        lastLevel = d.escalationAfter;
      }
    }

    return EscalationPath(
      sandboxId: sandboxId,
      decisions: sandboxDecisions,
      levelTransitions: transitions,
    );
  }

  List<LawDecisionRecord> violationsForLaw(RuntimeLawId lawId) =>
      _decisions.where((d) => d.violatedLaw == lawId).toList();

  List<LawDecisionRecord> violationsForSandbox(String sandboxId) =>
      _decisions.where((d) => d.sandboxId == sandboxId && !d.compliant).toList();

  List<LawDecisionRecord> decisionsInTimeRange(int from, int to) =>
      _decisions.where((d) => d.timestamp >= from && d.timestamp <= to).toList();

  void clear() {
    _decisions.clear();
    _seq = 0;
  }
}

class LedgerEntry {
  final int seq;
  final int timestamp;
  final String entryType;
  final String sandboxId;
  final Map<String, dynamic> data;
  final String hash;
  final String? previousHash;

  const LedgerEntry({
    required this.seq,
    required this.timestamp,
    required this.entryType,
    required this.sandboxId,
    required this.data,
    required this.hash,
    this.previousHash,
  });

  Map<String, dynamic> toJson() => {
        'seq': seq,
        'ts': timestamp,
        'type': entryType,
        'sandbox': sandboxId,
        'data': data,
        'hash': hash,
        'prevHash': previousHash,
      };
}

class ImmutableAuditLedger {
  final List<LedgerEntry> _entries = [];
  int _seq = 0;
  String _lastHash = 'genesis';

  List<LedgerEntry> get entries => List.unmodifiable(_entries);
  int get length => _entries.length;
  String get lastHash => _lastHash;
  bool get isEmpty => _entries.isEmpty;

  LedgerEntry append({
    required String entryType,
    required String sandboxId,
    required Map<String, dynamic> data,
    required int timestamp,
  }) {
    final seq = _seq++;
    final previousHash = _lastHash;
    final hash = _computeHash(seq, timestamp, entryType, sandboxId, data, previousHash);

    final entry = LedgerEntry(
      seq: seq,
      timestamp: timestamp,
      entryType: entryType,
      sandboxId: sandboxId,
      data: data,
      hash: hash,
      previousHash: previousHash,
    );

    _entries.add(entry);
    _lastHash = hash;
    return entry;
  }

  bool verifyIntegrity() {
    if (_entries.isEmpty) return true;

    String expectedPrevHash = 'genesis';
    for (final entry in _entries) {
      if (entry.previousHash != expectedPrevHash) return false;

      final expectedHash = _computeHash(
        entry.seq, entry.timestamp, entry.entryType,
        entry.sandboxId, entry.data, entry.previousHash,
      );
      if (entry.hash != expectedHash) return false;

      expectedPrevHash = entry.hash;
    }
    return true;
  }

  bool verifyEntry(int index) {
    if (index < 0 || index >= _entries.length) return false;
    final entry = _entries[index];

    final expectedPrevHash = index == 0 ? 'genesis' : _entries[index - 1].hash;
    if (entry.previousHash != expectedPrevHash) return false;

    final expectedHash = _computeHash(
      entry.seq, entry.timestamp, entry.entryType,
      entry.sandboxId, entry.data, entry.previousHash,
    );
    return entry.hash == expectedHash;
  }

  List<LedgerEntry> entriesFor(String sandboxId) =>
      _entries.where((e) => e.sandboxId == sandboxId).toList();

  List<LedgerEntry> entriesOfType(String entryType) =>
      _entries.where((e) => e.entryType == entryType).toList();

  List<LedgerEntry> entriesInRange(int fromSeq, int toSeq) =>
      _entries.where((e) => e.seq >= fromSeq && e.seq <= toSeq).toList();

  String _computeHash(int seq, int timestamp, String type, String sandboxId,
      Map<String, dynamic> data, String? previousHash) {
    final input = '$seq|$timestamp|$type|$sandboxId|${jsonEncode(data)}|$previousHash';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return 'ledger_${digest.toString().substring(0, 32)}';
  }
}

class CapabilityProof {
  final String capabilityId;
  final String callerId;
  final TrustLevel callerTrust;
  final bool routeProof;
  final bool budgetProof;
  final bool traceProof;
  final bool trustProof;
  final bool schedulerProof;
  final int timestamp;
  final String sandboxId;

  const CapabilityProof({
    required this.capabilityId,
    required this.callerId,
    required this.callerTrust,
    required this.routeProof,
    required this.budgetProof,
    required this.traceProof,
    required this.trustProof,
    required this.schedulerProof,
    required this.timestamp,
    required this.sandboxId,
  });

  bool get isComplete => routeProof && budgetProof && traceProof && trustProof && schedulerProof;

  List<String> missingProofs() {
    final missing = <String>[];
    if (!routeProof) missing.add('RouteProof');
    if (!budgetProof) missing.add('BudgetProof');
    if (!traceProof) missing.add('TraceProof');
    if (!trustProof) missing.add('TrustProof');
    if (!schedulerProof) missing.add('SchedulerProof');
    return missing;
  }

  Map<String, dynamic> toJson() => {
        'cap': capabilityId,
        'caller': callerId,
        'trust': callerTrust.name,
        'route': routeProof,
        'budget': budgetProof,
        'trace': traceProof,
        'trustProof': trustProof,
        'scheduler': schedulerProof,
        'ts': timestamp,
        'sandbox': sandboxId,
        'complete': isComplete,
      };

  factory CapabilityProof.forCapabilityInvocation({
    required String capabilityId,
    required String callerId,
    required TrustLevel callerTrust,
    required bool wasRoutedThroughRouter,
    required bool budgetApproved,
    required bool hasTraceSpan,
    required bool trustVerified,
    required bool scheduledThroughScheduler,
    required int timestamp,
    required String sandboxId,
  }) =>
      CapabilityProof(
        capabilityId: capabilityId,
        callerId: callerId,
        callerTrust: callerTrust,
        routeProof: wasRoutedThroughRouter,
        budgetProof: budgetApproved,
        traceProof: hasTraceSpan,
        trustProof: trustVerified,
        schedulerProof: scheduledThroughScheduler,
        timestamp: timestamp,
        sandboxId: sandboxId,
      );
}
