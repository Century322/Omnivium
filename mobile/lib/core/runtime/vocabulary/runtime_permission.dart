enum IsolationLevel {
  level0InProcess(0),
  level1IsolatedWorker(1),
  level2SandboxRuntime(2),
  level3RemoteNode(3);

  final int value;
  const IsolationLevel(this.value);
}

class NetworkPermission {
  final List<String> allowedHosts;
  final int maxConcurrent;

  const NetworkPermission({
    this.allowedHosts = const [],
    this.maxConcurrent = 4,
  });
}

class StoragePermission {
  final List<String> allowedPaths;
  final int maxBytes;

  const StoragePermission({
    this.allowedPaths = const [],
    this.maxBytes = 50 * 1024 * 1024,
  });
}

class TaskBudget {
  final int maxDurationMs;
  final int maxRetries;
  final int maxMemoryMb;

  const TaskBudget({
    this.maxDurationMs = 30000,
    this.maxRetries = 3,
    this.maxMemoryMb = 128,
  });
}

class RuntimePermission {
  final List<String> capabilities;
  final IsolationLevel isolation;
  final TaskBudget maxBudget;
  final NetworkPermission network;
  final StoragePermission storage;

  const RuntimePermission({
    this.capabilities = const [],
    this.isolation = IsolationLevel.level0InProcess,
    this.maxBudget = const TaskBudget(),
    this.network = const NetworkPermission(),
    this.storage = const StoragePermission(),
  });

  bool hasCapability(String capabilityId) => capabilities.contains(capabilityId) || capabilities.contains('*');
}
