import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/app_data_gateway.dart';

void main() {
  group('AppDataGateway', () {
    test('instance is singleton', () {
      expect(AppDataGateway.instance, same(AppDataGateway.instance));
    });

    test('persistence getter exists', () {
      final gateway = AppDataGateway.instance;
      expect(() => gateway.persistence, returnsNormally);
    });

    test('db getter exists', () {
      final gateway = AppDataGateway.instance;
      expect(() => gateway.db, returnsNormally);
    });
  });
}
