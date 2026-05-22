class ResourceBudget {
  final int maxTokens;
  final int maxStreams;
  final int maxMemoryMb;
  final int maxTasks;
  final int maxRetries;
  final int maxEventsPerSec;
  final double maxRetryAmplification;
  final double maxEventAmplification;

  const ResourceBudget({
    this.maxTokens = 100000,
    this.maxStreams = 16,
    this.maxMemoryMb = 512,
    this.maxTasks = 64,
    this.maxRetries = 100,
    this.maxEventsPerSec = 10000,
    this.maxRetryAmplification = 10.0,
    this.maxEventAmplification = 100.0,
  });
}

class ResourceUsage {
  int tokensUsed;
  int activeStreams;
  int memoryUsedMb;
  int activeTasks;
  int totalRetries;
  int eventsPerSec;
  double retryAmplification;
  double eventAmplification;

  ResourceUsage({
    this.tokensUsed = 0,
    this.activeStreams = 0,
    this.memoryUsedMb = 0,
    this.activeTasks = 0,
    this.totalRetries = 0,
    this.eventsPerSec = 0,
    this.retryAmplification = 1.0,
    this.eventAmplification = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'tokensUsed': tokensUsed,
        'activeStreams': activeStreams,
        'memoryUsedMb': memoryUsedMb,
        'activeTasks': activeTasks,
        'totalRetries': totalRetries,
        'eventsPerSec': eventsPerSec,
        'retryAmplification': retryAmplification,
        'eventAmplification': eventAmplification,
      };
}

enum ResourceLimitType {
  tokens,
  streams,
  memory,
  tasks,
  retries,
  eventsPerSec,
  retryAmplification,
  eventAmplification,
}

class ResourceLimitExceeded {
  final ResourceLimitType type;
  final int current;
  final int limit;
  final String message;

  const ResourceLimitExceeded({
    required this.type,
    required this.current,
    required this.limit,
    required this.message,
  });

  @override
  String toString() => 'ResourceLimitExceeded: $message (current=$current, limit=$limit)';
}

class ResourceController {
  final ResourceBudget _budget;
  final ResourceUsage _usage = ResourceUsage();
  final Map<String, ResourceUsage> _perPlugin = {};
  final List<ResourceLimitExceeded> _violations = [];

  ResourceController({ResourceBudget? budget}) : _budget = budget ?? const ResourceBudget();

  ResourceBudget get budget => _budget;
  ResourceUsage get usage => _usage;
  List<ResourceLimitExceeded> get violations => List.unmodifiable(_violations);
  int get violationCount => _violations.length;

  ResourceUsage usageFor(String pluginId) => _perPlugin[pluginId] ?? ResourceUsage();

  bool tryAcquireTokens(int count, {String? pluginId}) {
    if (_usage.tokensUsed + count > _budget.maxTokens) {
      _recordViolation(ResourceLimitType.tokens, _usage.tokensUsed + count, _budget.maxTokens,
          'Token budget exceeded');
      return false;
    }
    _usage.tokensUsed += count;
    if (pluginId != null) {
      _perPlugin.putIfAbsent(pluginId, () => ResourceUsage());
      _perPlugin[pluginId]!.tokensUsed += count;
    }
    return true;
  }

  bool tryAcquireStream({String? pluginId}) {
    if (_usage.activeStreams >= _budget.maxStreams) {
      _recordViolation(ResourceLimitType.streams, _usage.activeStreams, _budget.maxStreams,
          'Stream budget exceeded');
      return false;
    }
    _usage.activeStreams++;
    if (pluginId != null) {
      _perPlugin.putIfAbsent(pluginId, () => ResourceUsage());
      _perPlugin[pluginId]!.activeStreams++;
    }
    return true;
  }

  void releaseStream({String? pluginId}) {
    if (_usage.activeStreams > 0) _usage.activeStreams--;
    if (pluginId != null) {
      final pu = _perPlugin[pluginId];
      if (pu != null && pu.activeStreams > 0) pu.activeStreams--;
    }
  }

  bool tryAcquireTask({String? pluginId}) {
    if (_usage.activeTasks >= _budget.maxTasks) {
      _recordViolation(ResourceLimitType.tasks, _usage.activeTasks, _budget.maxTasks,
          'Task budget exceeded');
      return false;
    }
    _usage.activeTasks++;
    if (pluginId != null) {
      _perPlugin.putIfAbsent(pluginId, () => ResourceUsage());
      _perPlugin[pluginId]!.activeTasks++;
    }
    return true;
  }

  void releaseTask({String? pluginId}) {
    if (_usage.activeTasks > 0) _usage.activeTasks--;
    if (pluginId != null) {
      final pu = _perPlugin[pluginId];
      if (pu != null && pu.activeTasks > 0) pu.activeTasks--;
    }
  }

  bool recordRetry({String? pluginId}) {
    _usage.totalRetries++;
    _usage.retryAmplification = _usage.totalRetries > 0
        ? _usage.totalRetries / (_usage.activeTasks + 1)
        : 1.0;

    if (_usage.totalRetries > _budget.maxRetries) {
      _recordViolation(ResourceLimitType.retries, _usage.totalRetries, _budget.maxRetries,
          'Retry budget exceeded');
      return false;
    }

    if (_usage.retryAmplification > _budget.maxRetryAmplification) {
      _recordViolation(ResourceLimitType.retryAmplification,
          _usage.retryAmplification.toInt(), _budget.maxRetryAmplification.toInt(),
          'Retry amplification exceeded');
      return false;
    }

    if (pluginId != null) {
      _perPlugin.putIfAbsent(pluginId, () => ResourceUsage());
      _perPlugin[pluginId]!.totalRetries++;
    }
    return true;
  }

  bool recordEvents(int count, {String? pluginId}) {
    _usage.eventsPerSec = count;
    _usage.eventAmplification = count > 0 ? count / (_usage.activeTasks + 1) : 1.0;

    if (count > _budget.maxEventsPerSec) {
      _recordViolation(ResourceLimitType.eventsPerSec, count, _budget.maxEventsPerSec,
          'Events per second exceeded');
      return false;
    }

    if (_usage.eventAmplification > _budget.maxEventAmplification) {
      _recordViolation(ResourceLimitType.eventAmplification,
          _usage.eventAmplification.toInt(), _budget.maxEventAmplification.toInt(),
          'Event amplification exceeded');
      return false;
    }

    return true;
  }

  void recordMemory(int mb, {String? pluginId}) {
    _usage.memoryUsedMb = mb;
    if (pluginId != null) {
      _perPlugin.putIfAbsent(pluginId, () => ResourceUsage());
      _perPlugin[pluginId]!.memoryUsedMb = mb;
    }
  }

  bool checkMemoryLimit(int additionalMb) {
    if (_usage.memoryUsedMb + additionalMb > _budget.maxMemoryMb) {
      _recordViolation(ResourceLimitType.memory, _usage.memoryUsedMb + additionalMb, _budget.maxMemoryMb,
          'Memory budget exceeded');
      return false;
    }
    return true;
  }

  void reset() {
    _usage.tokensUsed = 0;
    _usage.activeStreams = 0;
    _usage.memoryUsedMb = 0;
    _usage.activeTasks = 0;
    _usage.totalRetries = 0;
    _usage.eventsPerSec = 0;
    _usage.retryAmplification = 1.0;
    _usage.eventAmplification = 1.0;
    _perPlugin.clear();
    _violations.clear();
  }

  void _recordViolation(ResourceLimitType type, int current, int limit, String message) {
    _violations.add(ResourceLimitExceeded(
      type: type,
      current: current,
      limit: limit,
      message: message,
    ));
  }
}
