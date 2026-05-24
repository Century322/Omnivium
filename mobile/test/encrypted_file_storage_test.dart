import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/encrypted_file_storage.dart';
import 'helpers/test_helpers.dart';

void main() {
  setUp(() async {
    await setupTestEnv();
    await initSecureStorage();
  });

  group('EncryptedFileStorage', () {
    test('instance is singleton', () {
      expect(
        EncryptedFileStorage.instance,
        same(EncryptedFileStorage.instance),
      );
    });

    test('init completes without error', () async {
      final service = EncryptedFileStorage.instance;
      await service.init();
    });
  });
}
