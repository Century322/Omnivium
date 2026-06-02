enum MetricType { counter, gauge, histogram }

class MetricPoint {
  final String name;
  final MetricType type;
  final Map<String, String> labels;
  final num value;
  final int timestamp;

  const MetricPoint({
    required this.name,
    required this.type,
    this.labels = const {},
    required this.value,
    required this.timestamp,
  });
}

class MetricsService {
  final Map<String, _Counter> _counters = {};
  final Map<String, _Gauge> _gauges = {};
  final Map<String, _Histogram> _histograms = {};
  final List<MetricPoint> _timeline = [];
  int get counterCount => _counters.length;

  void increment(
    String name, {
    Map<String, String> labels = const {},
    int delta = 1,
  }) {
    final key = _metricKey(name, labels);
    _counters.putIfAbsent(key, () => _Counter(name, labels));
    _counters[key]!.value += delta;
    _recordTimeline(name, MetricType.counter, labels, _counters[key]!.value);
  }

  void gauge(String name, num value, {Map<String, String> labels = const {}}) {
    final key = _metricKey(name, labels);
    _gauges[key] = _Gauge(name, labels, value);
    _recordTimeline(name, MetricType.gauge, labels, value);
  }

  void observe(
    String name,
    num value, {
    Map<String, String> labels = const {},
  }) {
    final key = _metricKey(name, labels);
    _histograms.putIfAbsent(key, () => _Histogram(name, labels));
    _histograms[key]!.observe(value);
    _recordTimeline(name, MetricType.histogram, labels, value);
  }

  num? getCounter(String name, {Map<String, String> labels = const {}}) =>
      _counters[_metricKey(name, labels)]?.value;

  num? getGauge(String name, {Map<String, String> labels = const {}}) =>
      _gauges[_metricKey(name, labels)]?.value;

  Map<String, dynamic>? getHistogram(
    String name, {
    Map<String, String> labels = const {},
  }) => _histograms[_metricKey(name, labels)]?.summary();

  List<MetricPoint> getTimeline({int limit = 1000}) =>
      _timeline.reversed.take(limit).toList();

  Map<String, dynamic> snapshot() {
    final counters = <String, int>{};
    for (final e in _counters.entries) {
      counters[e.value.name] = e.value.value;
    }

    final gauges = <String, num>{};
    for (final e in _gauges.entries) {
      gauges[e.value.name] = e.value.value;
    }

    final histograms = <String, Map<String, dynamic>>{};
    for (final e in _histograms.entries) {
      histograms[e.value.name] = e.value.summary();
    }

    return {'counters': counters, 'gauges': gauges, 'histograms': histograms};
  }

  void clear() {
    _counters.clear();
    _gauges.clear();
    _histograms.clear();
    _timeline.clear();
  }

  void _recordTimeline(
    String name,
    MetricType type,
    Map<String, String> labels,
    num value) {
    _timeline.add(
      MetricPoint(
        name: name,
        type: type,
        labels: labels,
        value: value,
        timestamp: DateTime.now().millisecondsSinceEpoch));
  }

  String _metricKey(String name, Map<String, String> labels) {
    if (labels.isEmpty) return name;
    final sorted = labels.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return '$name{${sorted.map((e) => '${e.key}=${e.value}').join(',')}}';
  }
}

class _Counter {
  final String name;
  final Map<String, String> labels;
  int value = 0;

  _Counter(this.name, this.labels);
}

class _Gauge {
  final String name;
  final Map<String, String> labels;
  num value;

  _Gauge(this.name, this.labels, this.value);
}

class _Histogram {
  final String name;
  final Map<String, String> labels;
  final List<num> _values = [];

  _Histogram(this.name, this.labels);

  void observe(num value) => _values.add(value);

  Map<String, dynamic> summary() {
    if (_values.isEmpty)
      return {'count': 0, 'min': 0, 'max': 0, 'avg': 0, 'p50': 0, 'p99': 0};
    final sorted = _values.toList()..sort();
    return {
      'count': sorted.length,
      'min': sorted.first,
      'max': sorted.last,
      'avg': sorted.reduce((a, b) => a + b) / sorted.length,
      'p50': sorted[(sorted.length * 0.5).floor().clamp(0, sorted.length - 1)],
      'p99': sorted[(sorted.length * 0.99).floor().clamp(0, sorted.length - 1)],
    };
  }
}
