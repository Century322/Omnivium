import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/auth_service.dart';

void main() {
  group('AuthService', () {
    test('instance is singleton', () {
      expect(AuthService.instance, same(AuthService.instance));
    });

    test('currentUser is null before init', () {
      final service = AuthService.instance;
      expect(service.currentUser, isNull);
    });

    test('jwtToken is null before init', () {
      final service = AuthService.instance;
      expect(service.jwtToken, isNull);
    });

    test('isAuthenticated is false before init', () {
      final service = AuthService.instance;
      expect(service.isAuthenticated, isFalse);
    });

    test('matrixUserId is null before init', () {
      final service = AuthService.instance;
      expect(service.matrixUserId, isNull);
    });

    test('isSupabaseInitialized is false before init', () {
      final service = AuthService.instance;
      expect(service.isSupabaseInitialized, isFalse);
    });

    test('onAuthStateChange returns a stream', () {
      final service = AuthService.instance;
      expect(service.onAuthStateChange, isA<Stream>());
    });
  });
}
