enum ClusterEventType {
  nodeJoined,
  nodeLeft,
  nodeSuspect,
  nodeDead,
  nodeAlive,
  capabilityAdvertised,
  capabilityWithdrawn,
  sessionLeaseAcquired,
  sessionLeaseReleased,
  sessionLeaseExpired,
  partitionDetected,
  partitionHealed,
}

class ClusterEvent {
  final String id;
  final ClusterEventType type;
  final String sourceNodeId;
  final int timestamp;
  final int hlcTime;
  final Map<String, dynamic> payload;

  const ClusterEvent({
    required this.id,
    required this.type,
    required this.sourceNodeId,
    required this.timestamp,
    this.hlcTime = 0,
    this.payload = const {},
  });

  ClusterEvent copyWith({
    String? id,
    ClusterEventType? type,
    String? sourceNodeId,
    int? timestamp,
    int? hlcTime,
    Map<String, dynamic>? payload,
  }) => ClusterEvent(
    id: id ?? this.id,
    type: type ?? this.type,
    sourceNodeId: sourceNodeId ?? this.sourceNodeId,
    timestamp: timestamp ?? this.timestamp,
    hlcTime: hlcTime ?? this.hlcTime,
    payload: payload ?? this.payload,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'sourceNodeId': sourceNodeId,
    'timestamp': timestamp,
    'hlcTime': hlcTime,
    'payload': payload,
  };

  factory ClusterEvent.fromJson(Map<String, dynamic> json) => ClusterEvent(
    id: json['id'] as String,
    type: ClusterEventType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => ClusterEventType.nodeJoined,
    ),
    sourceNodeId: json['sourceNodeId'] as String,
    timestamp: json['timestamp'] as int,
    hlcTime: json['hlcTime'] as int? ?? 0,
    payload: json['payload'] as Map<String, dynamic>? ?? {},
  );
}
