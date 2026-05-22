enum RuntimeStatus {
  booting,
  running,
  suspending,
  shuttingDown,
  crashed,
}

class RuntimeStateSnapshot {
  final RuntimeStatus status;
  final int activeSessionCount;
  final int activeTaskCount;
  final int loadedPluginCount;
  final int activePluginCount;
  final int capabilityCount;
  final int bootTimeMs;
  final int uptimeMs;

  const RuntimeStateSnapshot({
    required this.status,
    this.activeSessionCount = 0,
    this.activeTaskCount = 0,
    this.loadedPluginCount = 0,
    this.activePluginCount = 0,
    this.capabilityCount = 0,
    required this.bootTimeMs,
    required this.uptimeMs,
  });

  RuntimeStateSnapshot copyWith({
    RuntimeStatus? status,
    int? activeSessionCount,
    int? activeTaskCount,
    int? loadedPluginCount,
    int? activePluginCount,
    int? capabilityCount,
    int? bootTimeMs,
    int? uptimeMs,
  }) =>
      RuntimeStateSnapshot(
        status: status ?? this.status,
        activeSessionCount: activeSessionCount ?? this.activeSessionCount,
        activeTaskCount: activeTaskCount ?? this.activeTaskCount,
        loadedPluginCount: loadedPluginCount ?? this.loadedPluginCount,
        activePluginCount: activePluginCount ?? this.activePluginCount,
        capabilityCount: capabilityCount ?? this.capabilityCount,
        bootTimeMs: bootTimeMs ?? this.bootTimeMs,
        uptimeMs: uptimeMs ?? this.uptimeMs,
      );
}
