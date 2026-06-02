import 'package:freezed_annotation/freezed_annotation.dart';

part 'runtime_identity.freezed.dart';

@freezed
class RuntimeIdentity with _$RuntimeIdentity {
  const RuntimeIdentity._();

  const factory RuntimeIdentity({
    required String identity,
    @Default('default') String instance,
    @Default('local') String node,
  }) = _RuntimeIdentity;

  static RuntimeIdentity forPlugin(
    String pluginId, {
    String instance = 'default',
    String node = 'local',
  }) => RuntimeIdentity(identity: pluginId, instance: instance, node: node);

  static RuntimeIdentity forRuntime(String nodeId) =>
      RuntimeIdentity(identity: 'runtime', instance: 'kernel', node: nodeId);

  bool get isLocal => node == 'local';
  String get address => '$node/$identity/$instance';
}
