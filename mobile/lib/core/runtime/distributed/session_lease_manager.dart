import 'vocabulary/distributed_session_lease.dart';
import 'hybrid_logical_clock.dart';

class LeaseConfig {
  final Duration defaultTtl;
  final Duration renewalInterval;
  final Duration expiryGracePeriod;
  final int maxRenewals;

  const LeaseConfig({
    this.defaultTtl = const Duration(seconds: 30),
    this.renewalInterval = const Duration(seconds: 10),
    this.expiryGracePeriod = const Duration(seconds: 5),
    this.maxRenewals = 100,
  });
}

class SessionLeaseManager {
  final String _localNodeId;
  final HybridLogicalClock _clock;
  final LeaseConfig _config;
  final Map<String, DistributedSessionLease> _leases = {};

  SessionLeaseManager({
    required String localNodeId,
    required HybridLogicalClock clock,
    LeaseConfig config = const LeaseConfig(),
  }) : _localNodeId = localNodeId,
       _clock = clock,
       _config = config;

  String get localNodeId => _localNodeId;
  int get activeLeaseCount => _leases.values.where((l) => l.isActive).length;
  int get totalLeaseCount => _leases.length;
  List<DistributedSessionLease> get activeLeases =>
      _leases.values.where((l) => l.isActive).toList();

  DistributedSessionLease acquire(String sessionId) {
    final existing = _leases[sessionId];
    if (existing != null && existing.isActive) {
      if (existing.ownerNodeId == _localNodeId) {
        return existing;
      }
      throw StateError(
        'Session $sessionId is owned by node ${existing.ownerNodeId}',
      );
    }

    final now = _clock.tick();
    final lease = DistributedSessionLease(
      sessionId: sessionId,
      ownerNodeId: _localNodeId,
      state: LeaseState.active,
      acquiredAt: now.physicalTime,
      expiresAt: now.physicalTime + _config.defaultTtl.inMilliseconds,
    );

    _leases[sessionId] = lease;
    return lease;
  }

  DistributedSessionLease? tryAcquire(String sessionId) {
    try {
      return acquire(sessionId);
    } catch (_) {
      return null;
    }
  }

  bool renew(String sessionId) {
    final lease = _leases[sessionId];
    if (lease == null || !lease.isActive) return false;
    if (lease.ownerNodeId != _localNodeId) return false;
    if (lease.renewalCount >= _config.maxRenewals) return false;

    final now = _clock.tick();
    _leases[sessionId] = lease.copyWith(
      expiresAt: now.physicalTime + _config.defaultTtl.inMilliseconds,
      renewalCount: lease.renewalCount + 1,
    );
    return true;
  }

  bool release(String sessionId) {
    final lease = _leases[sessionId];
    if (lease == null) return false;
    if (lease.ownerNodeId != _localNodeId) return false;

    _leases[sessionId] = lease.copyWith(state: LeaseState.released);
    return true;
  }

  bool revoke(String sessionId, String revokerNodeId) {
    final lease = _leases[sessionId];
    if (lease == null) return false;

    _leases[sessionId] = lease.copyWith(state: LeaseState.revoked);
    return true;
  }

  bool isOwner(String sessionId) {
    final lease = _leases[sessionId];
    return lease != null && lease.ownerNodeId == _localNodeId && lease.isActive;
  }

  bool canWrite(String sessionId) {
    final lease = _leases[sessionId];
    if (lease == null) return false;
    if (!lease.isActive) return false;
    return lease.ownerNodeId == _localNodeId;
  }

  void tickExpiry() {
    final now = _clock.tick().physicalTime;

    for (final entry in _leases.entries) {
      final lease = entry.value;
      if (lease.isActive && now >= lease.expiresAt) {
        _leases[entry.key] = lease.copyWith(state: LeaseState.expired);
      }
    }
  }

  void reclaimExpiredLeases() {
    final now = _clock.tick().physicalTime;
    final gracePeriodMs = _config.expiryGracePeriod.inMilliseconds;

    final expiredSessions = _leases.entries
        .where(
          (e) => e.value.isExpired && now - e.value.expiresAt > gracePeriodMs,
        )
        .map((e) => e.key)
        .toList();

    for (final sessionId in expiredSessions) {
      _leases.remove(sessionId);
    }
  }

  void receiveLeaseState(DistributedSessionLease remoteLease) {
    final local = _leases[remoteLease.sessionId];
    if (local == null) {
      _leases[remoteLease.sessionId] = remoteLease;
      return;
    }

    if (remoteLease.acquiredAt > local.acquiredAt) {
      _leases[remoteLease.sessionId] = remoteLease;
    }
  }

  void clear() => _leases.clear();
}
