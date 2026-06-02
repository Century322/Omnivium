import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact.freezed.dart';
part 'contact.g.dart';

enum ContactStatus { none, requestSent, requestReceived, accepted, blocked }

@freezed
sealed class Contact with _$Contact {
  const factory Contact({
    required String userId,
    required String displayName,
    String? avatarUrl,
    String? matrixId,
    @Default(false) bool isOnline,
    DateTime? lastSeen,
    @Default(ContactStatus.none) ContactStatus status,
  }) = _Contact;

  factory Contact.fromJson(Map<String, dynamic> json) =>
      _$ContactFromJson(json);
}
