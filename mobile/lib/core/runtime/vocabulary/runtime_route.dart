class RuntimeRoute {
  final String capability;
  final String pluginId;
  final String instanceId;
  final String nodeId;

  const RuntimeRoute({
    required this.capability,
    required this.pluginId,
    this.instanceId = 'default',
    this.nodeId = 'local',
  });

  static RuntimeRoute local({
    required String capability,
    required String pluginId,
    String instanceId = 'default',
  }) =>
      RuntimeRoute(
        capability: capability,
        pluginId: pluginId,
        instanceId: instanceId,
        nodeId: 'local',
      );

  bool get isLocal => nodeId == 'local';

  String get address => '$nodeId/$pluginId/$instanceId/$capability';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuntimeRoute &&
          capability == other.capability &&
          pluginId == other.pluginId &&
          instanceId == other.instanceId &&
          nodeId == other.nodeId;

  @override
  int get hashCode => Object.hash(capability, pluginId, instanceId, nodeId);

  Map<String, dynamic> toJson() => {
        'capability': capability,
        'pluginId': pluginId,
        'instanceId': instanceId,
        'nodeId': nodeId,
      };

  factory RuntimeRoute.fromJson(Map<String, dynamic> json) => RuntimeRoute(
        capability: json['capability'] as String,
        pluginId: json['pluginId'] as String,
        instanceId: json['instanceId'] as String? ?? 'default',
        nodeId: json['nodeId'] as String? ?? 'local',
      );
}
