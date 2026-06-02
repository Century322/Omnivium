import 'package:freezed_annotation/freezed_annotation.dart';

part 'session.freezed.dart';
part 'session.g.dart';

@freezed
sealed class Session with _$Session {
  const Session._();

  const factory Session({
    required String accessToken,
    required String refreshToken,
    required String deviceId,
    required String userId,
    required DateTime expiresAt,
  }) = _Session;

  factory Session.fromJson(Map<String, dynamic> json) =>
      _$SessionFromJson(json);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
