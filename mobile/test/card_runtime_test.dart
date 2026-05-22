import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/runtime/card_runtime.dart';

void main() {
  group('CardLifecycle', () {
    test('has all expected values', () {
      expect(CardLifecycle.values.length, 7);
      expect(CardLifecycle.values, contains(CardLifecycle.created));
      expect(CardLifecycle.values, contains(CardLifecycle.rendering));
      expect(CardLifecycle.values, contains(CardLifecycle.streaming));
      expect(CardLifecycle.values, contains(CardLifecycle.interactive));
      expect(CardLifecycle.values, contains(CardLifecycle.fullscreen));
      expect(CardLifecycle.values, contains(CardLifecycle.expired));
      expect(CardLifecycle.values, contains(CardLifecycle.dismissed));
    });
  });

  group('CardState', () {
    test('creates with required fields', () {
      final now = DateTime.now();
      final state = CardState(id: 'c1', type: 'chat', createdAt: now);
      expect(state.id, 'c1');
      expect(state.type, 'chat');
      expect(state.lifecycle, CardLifecycle.created);
      expect(state.data, isEmpty);
      expect(state.ttl, const Duration(hours: 24));
    });

    test('creates with custom values', () {
      final now = DateTime.now();
      final state = CardState(
        id: 'c2',
        type: 'image',
        lifecycle: CardLifecycle.streaming,
        data: {'url': 'https://example.com'},
        createdAt: now,
        ttl: const Duration(minutes: 30),
      );
      expect(state.lifecycle, CardLifecycle.streaming);
      expect(state.data['url'], 'https://example.com');
      expect(state.ttl, const Duration(minutes: 30));
    });

    test('isExpired returns false within ttl', () {
      final state = CardState(
        id: 'c3',
        type: 'test',
        createdAt: DateTime.now(),
        ttl: const Duration(hours: 1),
      );
      expect(state.isExpired, isFalse);
    });

    test('isExpired returns true after ttl', () {
      final state = CardState(
        id: 'c4',
        type: 'test',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ttl: const Duration(hours: 1),
      );
      expect(state.isExpired, isTrue);
    });

    test('copyWith updates specified fields', () {
      final now = DateTime.now();
      final state = CardState(id: 'c5', type: 'test', createdAt: now);
      final updated = state.copyWith(
        lifecycle: CardLifecycle.interactive,
        data: {'key': 'val'},
      );
      expect(updated.id, 'c5');
      expect(updated.lifecycle, CardLifecycle.interactive);
      expect(updated.data['key'], 'val');
      expect(updated.createdAt, now);
    });

    test('copyWith without args keeps original values', () {
      final now = DateTime.now();
      final state = CardState(
        id: 'c6',
        type: 'test',
        createdAt: now,
        lifecycle: CardLifecycle.streaming,
      );
      final copy = state.copyWith();
      expect(copy.lifecycle, CardLifecycle.streaming);
      expect(copy.id, 'c6');
    });
  });

  group('CardRuntime', () {
    late CardRuntime runtime;

    setUp(() {
      runtime = CardRuntime();
    });

    test('starts with empty cards', () {
      expect(runtime.cards, isEmpty);
    });

    test('create adds a card', () {
      final card = runtime.create('chat');
      expect(runtime.cards.length, 1);
      expect(runtime.cards[card.id], card);
      expect(card.type, 'chat');
    });

    test('create with custom data and ttl', () {
      final card = runtime.create(
        'image',
        data: {'src': 'test.png'},
        ttl: const Duration(minutes: 5),
      );
      expect(card.data['src'], 'test.png');
      expect(card.ttl, const Duration(minutes: 5));
    });

    test('get returns card by id', () {
      final card = runtime.create('test');
      expect(runtime.get(card.id), card);
    });

    test('get returns null for unknown id', () {
      expect(runtime.get('unknown'), isNull);
    });

    test('update modifies card lifecycle and data', () {
      final card = runtime.create('test');
      final updated = runtime.update(
        card.id,
        lifecycle: CardLifecycle.streaming,
        data: {'x': 1},
      );
      expect(updated!.lifecycle, CardLifecycle.streaming);
      expect(updated.data['x'], 1);
    });

    test('update returns null for unknown id', () {
      expect(
        runtime.update('unknown', lifecycle: CardLifecycle.expired),
        isNull,
      );
    });

    test('dismiss removes card', () {
      final card = runtime.create('test');
      runtime.dismiss(card.id);
      expect(runtime.cards, isEmpty);
    });

    test('dismiss unknown id does nothing', () {
      runtime.create('test');
      runtime.dismiss('unknown');
      expect(runtime.cards.length, 1);
    });

    test('expireCards removes expired cards', () {
      runtime.create('fresh');
      final fresh = runtime.create('fresh2');
      expect(runtime.get(fresh.id)!.isExpired, isFalse);
    });

    test('cards map is unmodifiable', () {
      runtime.create('test');
      expect(() => (runtime.cards as Map).clear(), throwsA(anything));
    });
  });
}
