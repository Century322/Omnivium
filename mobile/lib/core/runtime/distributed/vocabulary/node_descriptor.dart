enum NodeRole {
  primary,
  edge,
  mobile,
  worker,
}

enum NodeState {
  joining,
  alive,
  suspect,
  dead,
  left,
}

class NodeDescriptor {
  final String nodeId;
  final String address;
  final int port;
  final NodeRole role;
  final NodeState state;
  final int incarnation;
  final int joinedAt;
  final int lastHeartbeatAt;
  final Map<String, String> metadata;

  const NodeDescriptor({
    required this.nodeId,
    required this.address,
    this.port = 0,
    this.role = NodeRole.worker,
    this.state = NodeState.joining,
    this.incarnation = 0,
    this.joinedAt = 0,
    this.lastHeartbeatAt = 0,
    this.metadata = const {},
  });

  NodeDescriptor copyWith({
    String? nodeId,
    String? address,
    int? port,
    NodeRole? role,
    NodeState? state,
    int? incarnation,
    int? joinedAt,
    int? lastHeartbeatAt,
    Map<String, String>? metadata,
  }) =>
      NodeDescriptor(
        nodeId: nodeId ?? this.nodeId,
        address: address ?? this.address,
        port: port ?? this.port,
        role: role ?? this.role,
        state: state ?? this.state,
        incarnation: incarnation ?? this.incarnation,
        joinedAt: joinedAt ?? this.joinedAt,
        lastHeartbeatAt: lastHeartbeatAt ?? this.lastHeartbeatAt,
        metadata: metadata ?? this.metadata,
      );

  bool get isAlive => state == NodeState.alive;
  bool get isSuspect => state == NodeState.suspect;
  bool get isDead => state == NodeState.dead || state == NodeState.left;

  String get addressKey => '$address:$port';

  Map<String, dynamic> toJson() => {
        'nodeId': nodeId,
        'address': address,
        'port': port,
        'role': role.name,
        'state': state.name,
        'incarnation': incarnation,
        'joinedAt': joinedAt,
        'lastHeartbeatAt': lastHeartbeatAt,
        'metadata': metadata,
      };

  factory NodeDescriptor.fromJson(Map<String, dynamic> json) => NodeDescriptor(
        nodeId: json['nodeId'] as String,
        address: json['address'] as String,
        port: json['port'] as int? ?? 0,
        role: NodeRole.values.firstWhere(
          (r) => r.name == json['role'],
          orElse: () => NodeRole.worker,
        ),
        state: NodeState.values.firstWhere(
          (s) => s.name == json['state'],
          orElse: () => NodeState.joining,
        ),
        incarnation: json['incarnation'] as int? ?? 0,
        joinedAt: json['joinedAt'] as int? ?? 0,
        lastHeartbeatAt: json['lastHeartbeatAt'] as int? ?? 0,
        metadata: (json['metadata'] as Map<String, dynamic>?)?.cast<String, String>() ?? {},
      );
}
