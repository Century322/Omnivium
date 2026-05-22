class RuntimeIdentity {
  final String identity;
  final String instance;
  final String node;

  const RuntimeIdentity({
    required this.identity,
    this.instance = 'default',
    this.node = 'local',
  });

  static RuntimeIdentity forPlugin(String pluginId, {String instance = 'default', String node = 'local'}) =>
      RuntimeIdentity(identity: pluginId, instance: instance, node: node);

  static RuntimeIdentity forRuntime(String nodeId) =>
      RuntimeIdentity(identity: 'runtime', instance: 'kernel', node: nodeId);

  bool get isLocal => node == 'local';

  String get address => '$node/$identity/$instance';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuntimeIdentity &&
          identity == other.identity &&
          instance == other.instance &&
          node == other.node;

  @override
  int get hashCode => Object.hash(identity, instance, node);
}
