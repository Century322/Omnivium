import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/audit_log_service.dart';

void main() {
  group('AuditLogEntry', () {
    test('toJson returns correct map', () {
      final entry = AuditLogEntry(
        id: 'abc',
        type: 'capability.invoked',
        operation: 'agent.chat',
        actor: 'user1',
        target: 'session1',
        allowed: true,
        timestamp: 1000,
        details: {'key': 'value'},
      );
      final json = entry.toJson();
      expect(json['id'], 'abc');
      expect(json['type'], 'capability.invoked');
      expect(json['operation'], 'agent.chat');
      expect(json['actor'], 'user1');
      expect(json['target'], 'session1');
      expect(json['allowed'], isTrue);
      expect(json['timestamp'], 1000);
      expect(json['details'], {'key': 'value'});
    });

    test('default details is empty map', () {
      final entry = AuditLogEntry(
        id: '1',
        type: 'test',
        operation: 'op',
        actor: 'a',
        target: 't',
        allowed: false,
        timestamp: 0,
      );
      expect(entry.details, isEmpty);
    });
  });

  group('AuditLogService', () {
    test('getRecentEntries returns empty when SDK not initialized', () {
      final service = AuditLogService.instance;
      expect(service.getRecentEntries(), isEmpty);
    });

    test('getSummary returns available false when SDK not initialized', () {
      final service = AuditLogService.instance;
      final summary = service.getSummary();
      expect(summary['available'], isFalse);
    });

    test('getCapabilityInvocations returns empty when SDK not initialized', () {
      final service = AuditLogService.instance;
      expect(service.getCapabilityInvocations(), isEmpty);
    });
  });
}
