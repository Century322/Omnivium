import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/remote_ui_engine.dart';

void main() {
  group('RemoteUIEngine', () {
    test('validateSchema returns non-null for valid column', () {
      final schema = {
        'type': 'column',
        'children': [
          {'type': 'text', 'content': 'Hello'},
        ],
      };
      final result = RemoteUIEngine.validateSchema(schema);
      expect(result, isNotNull);
    });

    test('validateSchema returns non-null for valid text', () {
      final schema = {'type': 'text', 'content': 'Hello'};
      final result = RemoteUIEngine.validateSchema(schema);
      expect(result, isNotNull);
    });

    test('validateSchema returns non-null for valid button', () {
      final schema = {'type': 'button', 'label': 'Click me'};
      final result = RemoteUIEngine.validateSchema(schema);
      expect(result, isNotNull);
    });

    test('validateSchema returns non-null for valid divider', () {
      final schema = {'type': 'divider'};
      final result = RemoteUIEngine.validateSchema(schema);
      expect(result, isNotNull);
    });

    test('validateSchema returns non-null for valid spacer', () {
      final schema = {'type': 'spacer'};
      final result = RemoteUIEngine.validateSchema(schema);
      expect(result, isNotNull);
    });

    test('validateSchema returns non-null for valid container', () {
      final schema = <String, dynamic>{'type': 'container', 'children': <Map<String, dynamic>>[]};
      final result = RemoteUIEngine.validateSchema(schema);
      expect(result, isNotNull);
    });

    test('validateSchema returns null for unknown type', () {
      final schema = {'type': 'script', 'src': 'evil.js'};
      final result = RemoteUIEngine.validateSchema(schema);
      expect(result, isNull);
    });

    test('validateSchema returns null for iframe type', () {
      final schema = {'type': 'iframe', 'src': 'https://evil.com'};
      final result = RemoteUIEngine.validateSchema(schema);
      expect(result, isNull);
    });

    test('validateSchema returns null for missing type', () {
      final schema = <String, dynamic>{'children': <Map<String, dynamic>>[]};
      final result = RemoteUIEngine.validateSchema(schema);
      expect(result, isNull);
    });

    test('validateSchema accepts all 14 allowed types', () {
      final types = [
        'column',
        'row',
        'text',
        'button',
        'card',
        'list',
        'image',
        'divider',
        'spacer',
        'container',
        'switch',
        'input',
        'icon',
        'badge',
      ];
      for (final type in types) {
        final schema = {'type': type};
        final result = RemoteUIEngine.validateSchema(schema);
        expect(result, isNotNull, reason: 'Type $type should be allowed');
      }
    });
  });
}
