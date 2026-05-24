import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/lru_cache.dart';

void main() {
  group('LruCache', () {
    test('put and get', () {
      final cache = LruCache<String, int>(3);
      cache.put('a', 1);
      cache.put('b', 2);
      expect(cache.get('a'), 1);
      expect(cache.get('b'), 2);
      expect(cache.get('c'), isNull);
    });

    test('evicts oldest when full', () {
      final cache = LruCache<String, int>(2);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), 2);
      expect(cache.get('c'), 3);
    });

    test('get promotes to most recent', () {
      final cache = LruCache<String, int>(2);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.get('a');
      cache.put('c', 3);
      expect(cache.get('a'), 1);
      expect(cache.get('b'), isNull);
    });

    test('put updates existing key', () {
      final cache = LruCache<String, int>(2);
      cache.put('a', 1);
      cache.put('a', 10);
      expect(cache.get('a'), 10);
      expect(cache.size, 1);
    });

    test('remove', () {
      final cache = LruCache<String, int>(3);
      cache.put('a', 1);
      expect(cache.remove('a'), 1);
      expect(cache.get('a'), isNull);
    });

    test('removeGroup', () {
      final cache = LruCache<String, int>(10);
      cache.put('a', 1, group: 'g1');
      cache.put('b', 2, group: 'g1');
      cache.put('c', 3, group: 'g2');
      cache.removeGroup('g1');
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), isNull);
      expect(cache.get('c'), 3);
    });

    test('getGroup', () {
      final cache = LruCache<String, int>(10);
      cache.put('a', 1, group: 'g1');
      cache.put('b', 2, group: 'g1');
      cache.put('c', 3, group: 'g2');
      expect(cache.getGroup('g1'), [1, 2]);
      expect(cache.getGroup('g2'), [3]);
    });

    test('clear', () {
      final cache = LruCache<String, int>(3);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.clear();
      expect(cache.isEmpty, isTrue);
      expect(cache.size, 0);
    });

    test('containsKey', () {
      final cache = LruCache<String, int>(3);
      cache.put('a', 1);
      expect(cache.containsKey('a'), isTrue);
      expect(cache.containsKey('b'), isFalse);
    });

    test('forEach iterates in order', () {
      final cache = LruCache<String, int>(3);
      cache.put('a', 1);
      cache.put('b', 2);
      final keys = <String>[];
      cache.forEach((k, v) => keys.add(k));
      expect(keys, ['a', 'b']);
    });

    test('size and isEmpty', () {
      final cache = LruCache<String, int>(3);
      expect(cache.isEmpty, isTrue);
      expect(cache.size, 0);
      cache.put('a', 1);
      expect(cache.isNotEmpty, isTrue);
      expect(cache.size, 1);
    });
  });

  group('ImageCacheManager', () {
    test('clearAll clears all caches', () {
      final manager = ImageCacheManager.instance;
      manager.memory.put('a', 1);
      manager.thumbs.put('b', 2);
      manager.stickers.put('c', 3);
      manager.clearAll();
      expect(manager.memory.isEmpty, isTrue);
      expect(manager.thumbs.isEmpty, isTrue);
      expect(manager.stickers.isEmpty, isTrue);
    });

    test('clearGroup removes from memory and thumbs', () {
      final manager = ImageCacheManager.instance;
      manager.memory.put('a', 1, group: 'chat1');
      manager.thumbs.put('b', 2, group: 'chat1');
      manager.clearGroup('chat1');
      expect(manager.memory.get('a'), isNull);
      expect(manager.thumbs.get('b'), isNull);
    });
  });
}
