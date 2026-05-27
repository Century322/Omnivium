import '../app_logger.dart';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import '../api_proxy_service.dart';
import '../database_service.dart';
import 'package:crypto/crypto.dart';

class EmbeddingService {
  static final EmbeddingService _instance = EmbeddingService._();
  static EmbeddingService get instance => _instance;
  EmbeddingService._();

  static const _cacheKey = 'embedding_cache';
  static const _maxCacheSize = 1000;

  final LinkedHashMap<String, List<double>> _cache = LinkedHashMap();
  final Map<String, String> _keyToHash = {};
  final Set<String> _dirtyKeys = {};
  bool _initialized = false;

  String _computeCacheKey(String text) {
    if (text.length <= 100) return text;
    return sha256.convert(utf8.encode(text)).toString().substring(0, 32);
  }

  Future<void> init() async {
    if (_initialized) return;
    final db = DatabaseService.instance;
    final indexRaw = db.getCache(_cacheKey);
    if (indexRaw != null) {
      try {
        final indexData = jsonDecode(indexRaw);
        if (indexData is List) {
          final keys = indexData.cast<String>();
          for (final key in keys) {
            final entryRaw = db.getCache('$_cacheKey::$key');
            if (entryRaw != null) {
              final list = (jsonDecode(entryRaw) as List)
                  .map((e) => (e as num).toDouble())
                  .toList();
              _cache[key] = list;
            }
          }
        } else if (indexData is Map<String, dynamic>) {
          _cache.addAll(
            indexData.map((k, v) => MapEntry(k, List<double>.from(v as List))),
          );
        }
      } catch (e, stackTrace) {
        AppLogger.instance.error(
          'Embedding cache load failed',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
    _initialized = true;
  }

  Future<List<double>?> getEmbedding(String text) async {
    final cacheKey = _computeCacheKey(text);

    if (_cache.containsKey(cacheKey)) {
      final value = _cache.remove(cacheKey)!;
      _cache[cacheKey] = value;
      return value;
    }

    final proxy = ApiProxyService.instance;
    if (!proxy.isConfigured) return null;

    try {
      final uri = Uri.parse('${proxy.backendUrl}/ai/embed');
      final response = await proxy.secureClient
          .post(
            uri,
            headers: {
              ...proxy.buildAuthHeaders(),
              ...proxy.buildDeviceHeaders(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final embedding = (body['embedding'] as List?)?.cast<double>();
        if (embedding != null) {
          _cache[cacheKey] = embedding;
          _keyToHash[cacheKey] = text;
          _dirtyKeys.add(cacheKey);
          while (_cache.length > _maxCacheSize) {
            final evictedKey = _cache.keys.first;
            _cache.remove(evictedKey);
            _keyToHash.remove(evictedKey);
            _dirtyKeys.remove(evictedKey);
            await DatabaseService.instance.deleteCache(
              '$_cacheKey::$evictedKey',
            );
          }
          await _saveDirtyEntries();
          return embedding;
        }
      }
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'Embedding request failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
    return null;
  }

  double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0;
    double dotProduct = 0, normA = 0, normB = 0;
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  Future<List<MapEntry<String, double>>> searchSimilar(
    String query, {
    int maxResults = 5,
    double threshold = 0.5,
  }) async {
    final queryEmbedding = await getEmbedding(query);
    if (queryEmbedding == null) return [];

    final results = <MapEntry<String, double>>[];
    for (final entry in _cache.entries) {
      final similarity = cosineSimilarity(queryEmbedding, entry.value);
      if (similarity >= threshold) {
        results.add(MapEntry(entry.key, similarity));
      }
    }

    results.sort((a, b) => b.value.compareTo(a.value));
    return results.take(maxResults).toList();
  }

  Future<void> _saveDirtyEntries() async {
    if (_dirtyKeys.isEmpty) return;
    final db = DatabaseService.instance;
    for (final key in _dirtyKeys) {
      final value = _cache[key];
      if (value != null) {
        await db.putCache('$_cacheKey::$key', jsonEncode(value));
      }
    }
    await db.putCache(_cacheKey, jsonEncode(_cache.keys.toList()));
    _dirtyKeys.clear();
  }
}
