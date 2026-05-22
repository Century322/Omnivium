class RuntimeConfig {
  final String runtimeVersion;
  final String nodeId;
  final int defaultTimeoutMs;
  final int maxConcurrentTasks;
  final int maxPlugins;
  final bool enableHotReload;
  final bool enableAsyncDiscovery;
  final int maxEventBusCapacity;
  final int defaultRetryMaxAttempts;
  final int defaultRetryBackoffMs;
  final double defaultRetryBackoffMultiplier;
  final int defaultRetryMaxBackoffMs;

  const RuntimeConfig({
    this.runtimeVersion = '1.0.0',
    this.nodeId = 'local',
    this.defaultTimeoutMs = 30000,
    this.maxConcurrentTasks = 16,
    this.maxPlugins = 64,
    this.enableHotReload = true,
    this.enableAsyncDiscovery = true,
    this.maxEventBusCapacity = 1024,
    this.defaultRetryMaxAttempts = 3,
    this.defaultRetryBackoffMs = 100,
    this.defaultRetryBackoffMultiplier = 2.0,
    this.defaultRetryMaxBackoffMs = 10000,
  });

  RuntimeConfig copyWith({
    String? runtimeVersion,
    String? nodeId,
    int? defaultTimeoutMs,
    int? maxConcurrentTasks,
    int? maxPlugins,
    bool? enableHotReload,
    bool? enableAsyncDiscovery,
    int? maxEventBusCapacity,
    int? defaultRetryMaxAttempts,
    int? defaultRetryBackoffMs,
    double? defaultRetryBackoffMultiplier,
    int? defaultRetryMaxBackoffMs,
  }) =>
      RuntimeConfig(
        runtimeVersion: runtimeVersion ?? this.runtimeVersion,
        nodeId: nodeId ?? this.nodeId,
        defaultTimeoutMs: defaultTimeoutMs ?? this.defaultTimeoutMs,
        maxConcurrentTasks: maxConcurrentTasks ?? this.maxConcurrentTasks,
        maxPlugins: maxPlugins ?? this.maxPlugins,
        enableHotReload: enableHotReload ?? this.enableHotReload,
        enableAsyncDiscovery: enableAsyncDiscovery ?? this.enableAsyncDiscovery,
        maxEventBusCapacity: maxEventBusCapacity ?? this.maxEventBusCapacity,
        defaultRetryMaxAttempts: defaultRetryMaxAttempts ?? this.defaultRetryMaxAttempts,
        defaultRetryBackoffMs: defaultRetryBackoffMs ?? this.defaultRetryBackoffMs,
        defaultRetryBackoffMultiplier: defaultRetryBackoffMultiplier ?? this.defaultRetryBackoffMultiplier,
        defaultRetryMaxBackoffMs: defaultRetryMaxBackoffMs ?? this.defaultRetryMaxBackoffMs,
      );
}
