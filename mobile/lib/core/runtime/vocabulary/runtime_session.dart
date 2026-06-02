import 'package:freezed_annotation/freezed_annotation.dart';

part 'runtime_session.freezed.dart';

enum SessionState { active, suspended, closed }

@freezed
class RuntimeSession with _$RuntimeSession {
  const RuntimeSession._();

  const factory RuntimeSession({
    required String id,
    required String userId,
    required int createdAt,
    required int lastActiveAt,
    @Default(SessionState.active) SessionState state,
    @Default(<String, dynamic>{}) Map<String, dynamic> metadata,
  }) = _RuntimeSession;

  bool get isActive => state == SessionState.active;
}
