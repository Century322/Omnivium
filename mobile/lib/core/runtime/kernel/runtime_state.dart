import 'package:freezed_annotation/freezed_annotation.dart';

part 'runtime_state.freezed.dart';

enum RuntimeStatus { booting, running, suspending, shuttingDown, crashed }

@freezed
class RuntimeStateSnapshot with _$RuntimeStateSnapshot {
  const factory RuntimeStateSnapshot({
    required RuntimeStatus status,
    @Default(0) int activeSessionCount,
    @Default(0) int activeTaskCount,
    @Default(0) int loadedPluginCount,
    @Default(0) int activePluginCount,
    @Default(0) int capabilityCount,
    required int bootTimeMs,
    required int uptimeMs,
  }) = _RuntimeStateSnapshot;
}
