import 'package:freezed_annotation/freezed_annotation.dart';

part 'call_entities.freezed.dart';
part 'call_entities.g.dart';

enum CallStatus { idle, ringing, connecting, connected, ended, missed }

class DurationMillisConverter implements JsonConverter<Duration?, int?> {
  const DurationMillisConverter();

  @override
  Duration? fromJson(int? json) =>
      json != null ? Duration(milliseconds: json) : null;

  @override
  int? toJson(Duration? object) => object?.inMilliseconds;
}

@freezed
sealed class CallState with _$CallState {
  const factory CallState({
    required String callId,
    required String roomId,
    required String remoteUserId,
    required String remoteUserName,
    String? remoteAvatarUrl,
    @Default(CallStatus.idle) CallStatus status,
    @Default(false) bool isVideo,
    DateTime? startedAt,
    @DurationMillisConverter() Duration? duration,
  }) = _CallState;

  factory CallState.fromJson(Map<String, dynamic> json) =>
      _$CallStateFromJson(json);
}
