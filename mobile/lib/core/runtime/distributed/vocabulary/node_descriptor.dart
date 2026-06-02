import 'package:freezed_annotation/freezed_annotation.dart';

part 'node_descriptor.freezed.dart';

enum NodeRole { primary, edge, mobile, worker }
enum NodeState { joining, alive, suspect, dead, left }

@freezed
class NodeDescriptor with _$NodeDescriptor {
  const NodeDescriptor._();

  const factory NodeDescriptor({
    required String nodeId,
    required String address,
    @Default(0) int port,
    @Default(NodeRole.worker) NodeRole role,
    @Default(NodeState.joining) NodeState state,
    @Default(0) int incarnation,
    @Default(0) int joinedAt,
    @Default(0) int lastHeartbeatAt,
    @Default(<String, String>{}) Map<String, String> metadata,
  }) = _NodeDescriptor;

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
      orElse: () => NodeRole.worker),
    state: NodeState.values.firstWhere(
      (s) => s.name == json['state'],
      orElse: () => NodeState.joining),
    incarnation: json['incarnation'] as int? ?? 0,
    joinedAt: json['joinedAt'] as int? ?? 0,
    lastHeartbeatAt: json['lastHeartbeatAt'] as int? ?? 0,
    metadata:
        (json['metadata'] as Map<String, dynamic>?)?.cast<String, String>() ??
        {});
}
