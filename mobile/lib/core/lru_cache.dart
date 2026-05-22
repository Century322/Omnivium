import 'dart:collection';

class LruCache<K, V> {
  final int maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();
  final Map<K, String> _groups = {};

  LruCache(this.maxSize);

  int get size => _cache.length;
  bool get isEmpty => _cache.isEmpty;
  bool get isNotEmpty => _cache.isNotEmpty;

  V? get(K key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value;
    }
    return value;
  }

  void put(K key, V value, {String? group}) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= maxSize) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
      _groups.remove(oldestKey);
    }
    _cache[key] = value;
    if (group != null) _groups[key] = group;
  }

  V? remove(K key) {
    _groups.remove(key);
    return _cache.remove(key);
  }

  void removeGroup(String group) {
    final keysToRemove = _groups.entries
        .where((e) => e.value == group)
        .map((e) => e.key)
        .toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
      _groups.remove(key);
    }
  }

  List<V> getGroup(String group) {
    return _groups.entries
        .where((e) => e.value == group)
        .map((e) => _cache[e.key])
        .whereType<V>()
        .toList();
  }

  void clear() {
    _cache.clear();
    _groups.clear();
  }

  bool containsKey(K key) => _cache.containsKey(key);

  void forEach(void Function(K key, V value) action) {
    for (final entry in _cache.entries) {
      action(entry.key, entry.value);
    }
  }
}

class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._();
  static ImageCacheManager get instance => _instance;
  ImageCacheManager._();

  final LruCache<String, dynamic> _memoryCache = LruCache(200);
  final LruCache<String, dynamic> _thumbCache = LruCache(100);
  final LruCache<String, dynamic> _stickerCache = LruCache(50);

  LruCache<String, dynamic> get memory => _memoryCache;
  LruCache<String, dynamic> get thumbs => _thumbCache;
  LruCache<String, dynamic> get stickers => _stickerCache;

  void clearAll() {
    _memoryCache.clear();
    _thumbCache.clear();
    _stickerCache.clear();
  }

  void clearGroup(String group) {
    _memoryCache.removeGroup(group);
    _thumbCache.removeGroup(group);
  }
}
