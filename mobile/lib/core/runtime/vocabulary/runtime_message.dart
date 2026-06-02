import 'package:freezed_annotation/freezed_annotation.dart';
import 'runtime_metadata.dart';
import 'runtime_route.dart';
import 'runtime_event.dart';

part 'runtime_message.freezed.dart';

@freezed
class RuntimeMessage with _$RuntimeMessage {
  const RuntimeMessage._();

  const factory RuntimeMessage({
    required String id,
    @Default(1) int version,
    required String type,
    required RuntimeRoute source,
    required RuntimeRoute target,
    Object? payload,
    required RuntimeMetadata metadata,
    @Default(PropagationScope.local) PropagationScope scope,
    required int timestamp,
  }) = _RuntimeMessage;

  Map<String, dynamic> toJson() => {
    'id': id,
    'version': version,
    'type': type,
    'source': source.toJson(),
    'target': target.toJson(),
    'payload': payload,
    'metadata': metadata.toJson(),
    'scope': scope.name,
    'timestamp': timestamp,
  };
}
