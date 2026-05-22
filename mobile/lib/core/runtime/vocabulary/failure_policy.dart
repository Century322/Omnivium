class RetryPolicy {
  final int maxRetries;
  final int backoffMs;
  final double backoffMultiplier;
  final int maxBackoffMs;
  final List<String> retryableErrors;

  const RetryPolicy({
    this.maxRetries = 3,
    this.backoffMs = 100,
    this.backoffMultiplier = 2.0,
    this.maxBackoffMs = 10000,
    this.retryableErrors = const [],
  });

  Duration delayForAttempt(int attempt) {
    var delay = backoffMs.toDouble();
    for (var i = 0; i < attempt; i++) {
      delay *= backoffMultiplier;
    }
    return Duration(milliseconds: delay.round().clamp(backoffMs, maxBackoffMs));
  }
}

class TimeoutPolicy {
  final int defaultMs;
  final int maxMs;
  final Map<String, int> perCapability;

  const TimeoutPolicy({
    this.defaultMs = 30000,
    this.maxMs = 300000,
    this.perCapability = const {},
  });

  int timeoutFor(String capabilityId) =>
      perCapability[capabilityId] ?? defaultMs;
}

class CircuitBreakerPolicy {
  final int failureThreshold;
  final int resetTimeoutMs;
  final int halfOpenMaxRequests;

  const CircuitBreakerPolicy({
    this.failureThreshold = 5,
    this.resetTimeoutMs = 30000,
    this.halfOpenMaxRequests = 1,
  });
}

enum FallbackStrategy { cache, defaultValue, delegate, failOpen, failClosed }

class FallbackPolicy {
  final FallbackStrategy strategy;
  final String? fallbackCapability;
  final int? cacheTtlMs;

  const FallbackPolicy({
    this.strategy = FallbackStrategy.failClosed,
    this.fallbackCapability,
    this.cacheTtlMs,
  });
}

class DeadLetterPolicy {
  final bool enabled;
  final int maxRetries;
  final int poisonThreshold;
  final PoisonAction onPoison;

  const DeadLetterPolicy({
    this.enabled = true,
    this.maxRetries = 3,
    this.poisonThreshold = 5,
    this.onPoison = PoisonAction.quarantine,
  });
}

enum PoisonAction { quarantine, drop, alert }

class FailurePolicy {
  final RetryPolicy retry;
  final TimeoutPolicy timeout;
  final CircuitBreakerPolicy circuitBreaker;
  final FallbackPolicy fallback;
  final DeadLetterPolicy deadLetter;

  const FailurePolicy({
    this.retry = const RetryPolicy(),
    this.timeout = const TimeoutPolicy(),
    this.circuitBreaker = const CircuitBreakerPolicy(),
    this.fallback = const FallbackPolicy(),
    this.deadLetter = const DeadLetterPolicy(),
  });
}
