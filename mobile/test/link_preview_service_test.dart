import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/link_preview_service.dart';

void main() {
  group('LinkPreviewData', () {
    test('constructor sets all fields', () {
      final data = LinkPreviewData(
        title: 'Test',
        description: 'Desc',
        imageUrl: 'https://example.com/img.png',
        siteName: 'Example',
        url: 'https://example.com',
      );
      expect(data.title, 'Test');
      expect(data.description, 'Desc');
      expect(data.imageUrl, 'https://example.com/img.png');
      expect(data.siteName, 'Example');
      expect(data.url, 'https://example.com');
    });

    test('nullable fields default to null', () {
      final data = LinkPreviewData(url: 'https://example.com');
      expect(data.title, isNull);
      expect(data.description, isNull);
      expect(data.imageUrl, isNull);
      expect(data.siteName, isNull);
    });
  });

  group('LinkPreviewService URL safety', () {
    test('blocks localhost', () async {
      final result = await LinkPreviewService.fetchPreview(
        'http://localhost/test',
      );
      expect(result, isNull);
    });

    test('blocks 127.0.0.1', () async {
      final result = await LinkPreviewService.fetchPreview(
        'http://127.0.0.1/test',
      );
      expect(result, isNull);
    });

    test('blocks 169.254.169.254 (SSRF)', () async {
      final result = await LinkPreviewService.fetchPreview(
        'http://169.254.169.254/metadata',
      );
      expect(result, isNull);
    });

    test('blocks file:// scheme', () async {
      final result = await LinkPreviewService.fetchPreview(
        'file:///etc/passwd',
      );
      expect(result, isNull);
    });

    test('blocks javascript: scheme', () async {
      final result = await LinkPreviewService.fetchPreview(
        'javascript:alert(1)',
      );
      expect(result, isNull);
    });

    test('blocks data: scheme', () async {
      final result = await LinkPreviewService.fetchPreview(
        'data:text/html,<h1>test</h1>',
      );
      expect(result, isNull);
    });

    test('blocks private IP 192.168.x.x', () async {
      final result = await LinkPreviewService.fetchPreview(
        'http://192.168.1.1/admin',
      );
      expect(result, isNull);
    });

    test('blocks private IP 10.x.x.x', () async {
      final result = await LinkPreviewService.fetchPreview(
        'http://10.0.0.1/admin',
      );
      expect(result, isNull);
    });

    test('blocks private IP 172.16-31.x.x', () async {
      final result = await LinkPreviewService.fetchPreview(
        'http://172.16.0.1/admin',
      );
      expect(result, isNull);
    });

    test('clearCache does not throw', () {
      expect(() => LinkPreviewService.clearCache(), returnsNormally);
    });
  });
}
