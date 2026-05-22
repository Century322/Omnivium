class RuntimeClock {
  final int _bootTimeMs;

  RuntimeClock() : _bootTimeMs = DateTime.now().millisecondsSinceEpoch;

  int now() => DateTime.now().millisecondsSinceEpoch;

  int monotonicMs() => DateTime.now().millisecondsSinceEpoch - _bootTimeMs;

  int deadline(int timeoutMs) => now() + timeoutMs;

  bool isExpired(int deadlineMs) => now() > deadlineMs;

  int get bootTimeMs => _bootTimeMs;

  int get uptimeMs => monotonicMs();
}
