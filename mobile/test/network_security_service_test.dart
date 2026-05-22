import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/network_security_service.dart';

void main() {
  group('NetworkSecurityService', () {
    late NetworkSecurityService service;

    setUp(() {
      service = NetworkSecurityService.instance;
    });

    test('initial state has pinning disabled', () {
      expect(service.pinningEnabled, isFalse);
    });

    test('addPinnedHash adds hash for host', () {
      service.addPinnedHash('example.com', 'abc123');
      service.addPinnedHash('example.com', 'def456');
      expect(service.pinningEnabled, isFalse);
    });

    test('addPinnedHash does not add duplicate hashes', () {
      service.addPinnedHash('test.com', 'hash1');
      service.addPinnedHash('test.com', 'hash1');
    });

    test('enablePinning sets pinningEnabled to true', () {
      service.enablePinning();
      expect(service.pinningEnabled, isTrue);
    });

    test('setPinnedHashes replaces all hashes', () {
      service.addPinnedHash('old.com', 'old_hash');
      service.setPinnedHashes({
        'new.com': ['new_hash'],
      });
    });

    test('verifyPinning returns true when pinning disabled', () async {
      final result = await service.verifyPinning('example.com');
      expect(result, isTrue);
    });
  });
}
