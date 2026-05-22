enum SessionState {
  active,
  suspended,
  closed,
}

class RuntimeSession {
  final String id;
  final String userId;
  final int createdAt;
  final int lastActiveAt;
  final SessionState state;
  final Map<String, dynamic> metadata;

  const RuntimeSession({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.lastActiveAt,
    this.state = SessionState.active,
    this.metadata = const {},
  });

  RuntimeSession copyWith({
    String? id,
    String? userId,
    int? createdAt,
    int? lastActiveAt,
    SessionState? state,
    Map<String, dynamic>? metadata,
  }) =>
      RuntimeSession(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        createdAt: createdAt ?? this.createdAt,
        lastActiveAt: lastActiveAt ?? this.lastActiveAt,
        state: state ?? this.state,
        metadata: metadata ?? this.metadata,
      );

  bool get isActive => state == SessionState.active;
}
