enum LeaseState { active, expired, released, revoked }

class DistributedSessionLease {
  final String sessionId;
  final String ownerNodeId;
  final LeaseState state;
  final int acquiredAt;
  final int expiresAt;
  final int renewalCount;

  const DistributedSessionLease({
    required this.sessionId,
    required this.ownerNodeId,
    this.state = LeaseState.active,
    required this.acquiredAt,
    required this.expiresAt,
    this.renewalCount = 0,
  });

  DistributedSessionLease copyWith({
    String? sessionId,
    String? ownerNodeId,
    LeaseState? state,
    int? acquiredAt,
    int? expiresAt,
    int? renewalCount,
  }) => DistributedSessionLease(
    sessionId: sessionId ?? this.sessionId,
    ownerNodeId: ownerNodeId ?? this.ownerNodeId,
    state: state ?? this.state,
    acquiredAt: acquiredAt ?? this.acquiredAt,
    expiresAt: expiresAt ?? this.expiresAt,
    renewalCount: renewalCount ?? this.renewalCount);

  bool get isActive => state == LeaseState.active;
  bool get isExpired => state == LeaseState.expired;

  bool isValidAt(int timestamp) =>
      state == LeaseState.active && timestamp < expiresAt;

  Duration get ttl => Duration(milliseconds: expiresAt - acquiredAt);

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'ownerNodeId': ownerNodeId,
    'state': state.name,
    'acquiredAt': acquiredAt,
    'expiresAt': expiresAt,
    'renewalCount': renewalCount,
  };

  factory DistributedSessionLease.fromJson(Map<String, dynamic> json) =>
      DistributedSessionLease(
        sessionId: json['sessionId'] as String,
        ownerNodeId: json['ownerNodeId'] as String,
        state: LeaseState.values.firstWhere(
          (s) => s.name == json['state'],
          orElse: () => LeaseState.expired),
        acquiredAt: json['acquiredAt'] as int,
        expiresAt: json['expiresAt'] as int,
        renewalCount: json['renewalCount'] as int? ?? 0);
}
