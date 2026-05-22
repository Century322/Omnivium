class RuntimeMetadata {
  final String schema;
  final int version;
  final String traceId;
  final String spanId;
  final Map<String, String> tags;

  const RuntimeMetadata({
    this.schema = 'omnivium.runtime.v1',
    this.version = 1,
    required this.traceId,
    required this.spanId,
    this.tags = const {},
  });

  RuntimeMetadata copyWith({
    String? schema,
    int? version,
    String? traceId,
    String? spanId,
    Map<String, String>? tags,
  }) =>
      RuntimeMetadata(
        schema: schema ?? this.schema,
        version: version ?? this.version,
        traceId: traceId ?? this.traceId,
        spanId: spanId ?? this.spanId,
        tags: tags ?? this.tags,
      );

  RuntimeMetadata withTag(String key, String value) =>
      RuntimeMetadata(
        schema: schema,
        version: version,
        traceId: traceId,
        spanId: spanId,
        tags: {...tags, key: value},
      );

  Map<String, dynamic> toJson() => {
        'schema': schema,
        'version': version,
        'traceId': traceId,
        'spanId': spanId,
        'tags': tags,
      };
}
