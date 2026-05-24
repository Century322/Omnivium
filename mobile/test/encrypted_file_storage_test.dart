import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/encrypted_file_storage.dart';
import 'helpers/test_helpers.dart';

void main() {
  bool storageReady = false;

  setUp(() async {
    await setupTestEnv();
    storageReady = await initSecureStorage();
  });

  group('EncryptedFileStorage', () {
    test('instance is singleton', () {
      expect(
        EncryptedFileStorage.instance,
        same(EncryptedFileStorage.instance),
      );
    });

    test('init completes without error', () async {
      if (!storageReady) return;
      final service = EncryptedFileStorage.instance;
      await service.init();
    });
  });
}
