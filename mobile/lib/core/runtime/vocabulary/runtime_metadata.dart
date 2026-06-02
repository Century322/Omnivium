import 'package:freezed_annotation/freezed_annotation.dart';

part 'runtime_metadata.freezed.dart';

@freezed
class RuntimeMetadata with _$RuntimeMetadata {
  const RuntimeMetadata._();

  const factory RuntimeMetadata({
    @Default('omnivium.runtime.v1') String schema,
    @Default(1) int version,
    required String traceId,
    required String spanId,
    @Default(<String, String>{}) Map<String, String> tags,
  }) = _RuntimeMetadata;

  RuntimeMetadata withTag(String key, String value) => copyWith(
    tags: {...tags, key: value});

  Map<String, dynamic> toJson() => {
    'schema': schema,
    'version': version,
    'traceId': traceId,
    'spanId': spanId,
    'tags': tags,
  };
}
