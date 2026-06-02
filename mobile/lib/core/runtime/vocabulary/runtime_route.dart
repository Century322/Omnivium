import 'package:freezed_annotation/freezed_annotation.dart';

part 'runtime_route.freezed.dart';
part 'runtime_route.g.dart';

@freezed
class RuntimeRoute with _$RuntimeRoute {
  const RuntimeRoute._();

  const factory RuntimeRoute({
    required String capability,
    required String pluginId,
    @Default('default') String instanceId,
    @Default('local') String nodeId,
  }) = _RuntimeRoute;

  static RuntimeRoute local({
    required String capability,
    required String pluginId,
    String instanceId = 'default',
  }) => RuntimeRoute(
    capability: capability,
    pluginId: pluginId,
    instanceId: instanceId,
    nodeId: 'local');

  bool get isLocal => nodeId == 'local';
  String get address => '$nodeId/$pluginId/$instanceId/$capability';

  factory RuntimeRoute.fromJson(Map<String, dynamic> json) =>
      _$RuntimeRouteFromJson(json);
}
