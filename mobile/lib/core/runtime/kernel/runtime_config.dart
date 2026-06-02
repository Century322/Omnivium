import 'package:freezed_annotation/freezed_annotation.dart';

part 'runtime_config.freezed.dart';

@freezed
class RuntimeConfig with _$RuntimeConfig {
  const factory RuntimeConfig({
    @Default('1.0.0') String runtimeVersion,
    @Default('local') String nodeId,
    @Default(30000) int defaultTimeoutMs,
    @Default(16) int maxConcurrentTasks,
    @Default(64) int maxPlugins,
    @Default(true) bool enableHotReload,
    @Default(true) bool enableAsyncDiscovery,
    @Default(1024) int maxEventBusCapacity,
    @Default(3) int defaultRetryMaxAttempts,
    @Default(100) int defaultRetryBackoffMs,
    @Default(2.0) double defaultRetryBackoffMultiplier,
    @Default(10000) int defaultRetryMaxBackoffMs,
  }) = _RuntimeConfig;
}
