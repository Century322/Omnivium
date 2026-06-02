import 'package:freezed_annotation/freezed_annotation.dart';
import 'runtime_metadata.dart';
import 'runtime_route.dart';

part 'runtime_event.freezed.dart';

@freezed
class RuntimeEvent with _$RuntimeEvent {
  const RuntimeEvent._();

  const factory RuntimeEvent({
    required String id,
    required String type,
    required RuntimeRoute source,
    Object? data,
    required RuntimeMetadata metadata,
    @Default(PropagationScope.local) PropagationScope scope,
    @Default(false) bool cancelled,
  }) = _RuntimeEvent;

  void preventPropagation() {
    // cancelled flag is immutable in freezed; use copyWith in caller
  }
}
