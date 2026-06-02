class CapabilityParams {
  final Map<String, Object?> _data;

  const CapabilityParams([this._data = const {}]);

  factory CapabilityParams.from(Object? params) {
    if (params is Map<String, Object?>) return CapabilityParams(params);
    if (params is Map<String, dynamic>) {
      return CapabilityParams(Map<String, Object?>.from(params));
    }
    if (params == null) return const CapabilityParams();
    return CapabilityParams({'value': params});
  }

  Map<String, Object?> get raw => _data;

  bool get isEmpty => _data.isEmpty;
  bool get isNotEmpty => _data.isNotEmpty;
  int get length => _data.length;
  Set<String> get keys => _data.keys.toSet();

  bool has(String key) => _data.containsKey(key);

  String? string(String key) {
    final v = _data[key];
    if (v is String) return v;
    if (v != null) return v.toString();
    return null;
  }

  String stringOr(String key, String defaultValue) {
    return string(key) ?? defaultValue;
  }

  int? int_(String key) {
    final v = _data[key];
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  int intOr(String key, int defaultValue) {
    return int_(key) ?? defaultValue;
  }

  double? double_(String key) {
    final v = _data[key];
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  double doubleOr(String key, double defaultValue) {
    return double_(key) ?? defaultValue;
  }

  bool? bool_(String key) {
    final v = _data[key];
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    if (v is int) return v != 0;
    return null;
  }

  bool boolOr(String key, bool defaultValue) {
    return bool_(key) ?? defaultValue;
  }

  List<T>? list<T>(String key) {
    final v = _data[key];
    if (v is List) return v.cast<T>();
    return null;
  }

  List<T> listOr<T>(String key, List<T> defaultValue) {
    return list<T>(key) ?? defaultValue;
  }

  Map<String, Object?>? map(String key) {
    final v = _data[key];
    if (v is Map<String, Object?>) return v;
    if (v is Map<String, dynamic>) return Map<String, Object?>.from(v);
    return null;
  }

  CapabilityParams nested(String key) {
    final m = map(key);
    return m != null ? CapabilityParams(m) : const CapabilityParams();
  }

  Object? operator [](String key) => _data[key];

  @override
  String toString() => 'CapabilityParams($_data)';
}
