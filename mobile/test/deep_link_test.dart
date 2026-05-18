import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/deep_link_service.dart';

void main() {
  group('DeepLinkService', () {
    test('parseSessionId from omnivium://chat?id=123', () {
      final uri = Uri.parse('omnivium://chat?id=123');
      final result = DeepLinkService.instance.parseSessionId(uri);
      expect(result, '123');
    });

    test('parseSessionId from omnivium://chat/456', () {
      final uri = Uri.parse('omnivium://chat/456');
      final result = DeepLinkService.instance.parseSessionId(uri);
      expect(result, '456');
    });

    test('parseSessionId returns null for wrong scheme', () {
      final uri = Uri.parse('https://example.com');
      final result = DeepLinkService.instance.parseSessionId(uri);
      expect(result, isNull);
    });

    test('parseRoomId from omnivium://room?id=room1', () {
      final uri = Uri.parse('omnivium://room?id=room1');
      final result = DeepLinkService.instance.parseRoomId(uri);
      expect(result, 'room1');
    });

    test('parseRoomId from omnivium://room/room2', () {
      final uri = Uri.parse('omnivium://room/room2');
      final result = DeepLinkService.instance.parseRoomId(uri);
      expect(result, 'room2');
    });

    test('parseRoomId returns null for wrong host', () {
      final uri = Uri.parse('omnivium://chat?id=123');
      final result = DeepLinkService.instance.parseRoomId(uri);
      expect(result, isNull);
    });
  });
}
