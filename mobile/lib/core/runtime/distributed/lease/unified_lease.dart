import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../app_logger.dart';
import '../hybrid_logical_clock.dart';

part 'unified_lease.freezed.dart';

enum LeaseType { session, resource, capability }
enum LeaseState { active, expired, released, revoked }

@freezed
class UnifiedLease with _$UnifiedLease {
  const UnifiedLease._();

  const factory UnifiedLease({
    required String leaseId,
    required LeaseType leaseType,
    @Default(LeaseState.active) LeaseState state,
    required String ownerId,
    required String targetId,
    required int acquiredAt,
    required int expiresAt,
    @Default(0) int renewalCount,
    @Default(0) int incarnation,
    @Default(<String, dynamic>{}) Map<String, dynamic> constraints,
  }) = _UnifiedLease;

  bool get isActive => state == LeaseState.active;
  bool get isExpired => state == LeaseState.expired;
  bool get isSessionLease => leaseType == LeaseType.session;
  bool get isResourceLease => leaseType == LeaseType.resource;
  bool get isCapabilityLease => leaseType == LeaseType.capability;
  bool isValidAt(int timestamp) => isActive && timestamp < expiresAt;
  Duration get ttl => Duration(milliseconds: expiresAt - acquiredAt);

  Map<String, dynamic> toJson() => {
    'leaseId': leaseId,
    'type': leaseType.name,
    'state': state.name,
    'ownerId': ownerId,
    'targetId': targetId,
    'acquiredAt': acquiredAt,
    'expiresAt': expiresAt,
    'renewalCount': renewalCount,
    'incarnation': incarnation,
    'constraints': constraints,
  };

  factory UnifiedLease.fromJson(Map<String, dynamic> json) => UnifiedLease(
    leaseId: json['leaseId'] as String,
    leaseType: LeaseType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => LeaseType.session),
    state: LeaseState.values.firstWhere(
      (s) => s.name == json['state'],
      orElse: () => LeaseState.expired),
    ownerId: json['ownerId'] as String,
    targetId: json['targetId'] as String,
    acquiredAt: json['acquiredAt'] as int,
    expiresAt: json['expiresAt'] as int,
    renewalCount: json['renewalCount'] as int? ?? 0,
    incarnation: json['incarnation'] as int? ?? 0,
    constraints: json['constraints'] as Map<String, dynamic>? ?? {});
}

class LeaseConfig {
  final Duration sessionTtl;
  final Duration resourceTtl;
  final Duration capabilityTtl;
  final int maxRenewals;
  final Duration expiryGracePeriod;

  const LeaseConfig({
    this.sessionTtl = const Duration(seconds: 30),
    this.resourceTtl = const Duration(seconds: 60),
    this.capabilityTtl = const Duration(seconds: 15),
    this.maxRenewals = 100,
    this.expiryGracePeriod = const Duration(seconds: 5),
  });

  Duration ttlForType(LeaseType type) {
    switch (type) {
      case LeaseType.session: return sessionTtl;
      case LeaseType.resource: return resourceTtl;
      case LeaseType.capability: return capabilityTtl;
    }
  }
}

class UnifiedLeaseManager {
  final String _localNodeId;
  final HybridLogicalClock _clock;
  final LeaseConfig _config;
  final Map<String, UnifiedLease> _leases = {};
  int _leaseSeq = 0;

  UnifiedLeaseManager({
    required String localNodeId,
    required HybridLogicalClock clock,
    LeaseConfig config = const LeaseConfig(),
  }) : _localNodeId = localNodeId,
       _clock = clock,
       _config = config;

  String get localNodeId => _localNodeId;
  int get activeLeaseCount => _leases.values.where((l) => l.isActive).length;
  int get totalLeaseCount => _leases.length;
  List<UnifiedLease> get activeLeases =>
      _leases.values.where((l) => l.isActive).toList();
  List<UnifiedLease> get sessionLeases =>
      _leases.values.where((l) => l.isSessionLease && l.isActive).toList();
  List<UnifiedLease> get resourceLeases =>
      _leases.values.where((l) => l.isResourceLease && l.isActive).toList();
  List<UnifiedLease> get capabilityLeases =>
      _leases.values.where((l) => l.isCapabilityLease && l.isActive).toList();

  UnifiedLease acquire(
    LeaseType type,
    String targetId, {
    Map<String, dynamic> constraints = const {},
  }) {
    final existing = _leases[targetId];
    if (existing != null && existing.isActive) {
      if (existing.ownerId == _localNodeId) return existing;
      throw StateError('$targetId is leased by ${existing.ownerId}');
    }

    final now = _clock.tick();
    final ttl = _config.ttlForType(type);
    final lease = UnifiedLease(
      leaseId: 'lease_${_leaseSeq++}',
      leaseType: type,
      ownerId: _localNodeId,
      targetId: targetId,
      acquiredAt: now.physicalTime,
      expiresAt: now.physicalTime + ttl.inMilliseconds,
      constraints: constraints);

    _leases[targetId] = lease;
    return lease;
  }

  UnifiedLease? tryAcquire(
    LeaseType type,
    String targetId, {
    Map<String, dynamic> constraints = const {},
  }) {
    try {
      return acquire(type, targetId, constraints: constraints);
    } catch (e) {
      AppLogger.instance.debug('Unified lease acquire failed', error: e);
      return null;
    }
  }

  bool renew(String targetId) {
    final lease = _leases[targetId];
    if (lease == null || !lease.isActive) return false;
    if (lease.ownerId != _localNodeId) return false;
    if (lease.renewalCount >= _config.maxRenewals) return false;

    final now = _clock.tick();
    final ttl = _config.ttlForType(lease.leaseType);
    _leases[targetId] = lease.copyWith(
      expiresAt: now.physicalTime + ttl.inMilliseconds,
      renewalCount: lease.renewalCount + 1);
    return true;
  }

  bool release(String targetId) {
    final lease = _leases[targetId];
    if (lease == null || lease.ownerId != _localNodeId) return false;
    _leases[targetId] = lease.copyWith(state: LeaseState.released);
    return true;
  }

  bool revoke(String targetId, String revokerNodeId) {
    final lease = _leases[targetId];
    if (lease == null) return false;
    _leases[targetId] = lease.copyWith(state: LeaseState.revoked);
    return true;
  }

  bool isOwner(String targetId) {
    final lease = _leases[targetId];
    return lease != null && lease.ownerId == _localNodeId && lease.isActive;
  }

  bool canWrite(String targetId) {
    final lease = _leases[targetId];
    return lease != null && lease.isActive && lease.ownerId == _localNodeId;
  }

  UnifiedLease? getLease(String targetId) => _leases[targetId];

  void tickExpiry() {
    final now = _clock.tick().physicalTime;
    for (final entry in _leases.entries) {
      if (entry.value.isActive && now >= entry.value.expiresAt) {
        _leases[entry.key] = entry.value.copyWith(state: LeaseState.expired);
      }
    }
  }

  void reclaimExpired() {
    final now = _clock.tick().physicalTime;
    final graceMs = _config.expiryGracePeriod.inMilliseconds;
    final toRemove = _leases.entries
        .where((e) => e.value.isExpired && now - e.value.expiresAt > graceMs)
        .map((e) => e.key)
        .toList();
    for (final key in toRemove) {
      _leases.remove(key);
    }
  }

  void receiveLeaseState(UnifiedLease remoteLease) {
    final local = _leases[remoteLease.targetId];
    if (local == null) {
      _leases[remoteLease.targetId] = remoteLease;
      return;
    }
    if (remoteLease.incarnation > local.incarnation) {
      _leases[remoteLease.targetId] = remoteLease;
    }
  }

  void clear() => _leases.clear();
}
