import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/agent/embedding_service.dart';

void main() {
  group('EmbeddingService cosineSimilarity', () {
    final service = EmbeddingService.instance;

    test('identical vectors return 1.0', () {
      final vec = [1.0, 2.0, 3.0];
      final result = service.cosineSimilarity(vec, vec);
      expect(result, closeTo(1.0, 0.0001));
    });

    test('orthogonal vectors return 0.0', () {
      final a = [1.0, 0.0];
      final b = [0.0, 1.0];
      final result = service.cosineSimilarity(a, b);
      expect(result, closeTo(0.0, 0.0001));
    });

    test('opposite vectors return -1.0', () {
      final a = [1.0, 0.0];
      final b = [-1.0, 0.0];
      final result = service.cosineSimilarity(a, b);
      expect(result, closeTo(-1.0, 0.0001));
    });

    test('different length vectors return 0', () {
      final a = [1.0, 2.0, 3.0];
      final b = [1.0, 2.0];
      expect(service.cosineSimilarity(a, b), 0);
    });

    test('empty vectors return 0', () {
      expect(service.cosineSimilarity([], []), 0);
    });

    test('zero vectors return 0', () {
      final a = [0.0, 0.0, 0.0];
      final b = [1.0, 2.0, 3.0];
      expect(service.cosineSimilarity(a, b), 0);
    });

    test('known values calculate correctly', () {
      final a = [1.0, 2.0, 3.0];
      final b = [4.0, 5.0, 6.0];
      final dot = 1 * 4 + 2 * 5 + 3 * 6;
      final normA = (1 + 4 + 9);
      final normB = (16 + 25 + 36);
      final expected = dot / (sqrt(normA) * sqrt(normB));
      final result = service.cosineSimilarity(a, b);
      expect(result, closeTo(expected, 0.0001));
    });

    test('single element vectors', () {
      expect(service.cosineSimilarity([5.0], [5.0]), closeTo(1.0, 0.0001));
      expect(service.cosineSimilarity([5.0], [-5.0]), closeTo(-1.0, 0.0001));
    });
  });
}
