import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/file_download_service.dart';

void main() {
  group('FileDownloadService', () {
    test('rejects file name with path traversal', () async {
      final service = FileDownloadService.instance;
      final result = await service.downloadFile(
        url: 'https://example.com/file.txt',
        fileName: '../../../etc/passwd',
      );
      expect(result, isNull);
    });

    test('rejects file name with backslash', () async {
      final service = FileDownloadService.instance;
      final result = await service.downloadFile(
        url: 'https://example.com/file.txt',
        fileName: 'folder\\file.txt',
      );
      expect(result, isNull);
    });

    test('rejects file name with forward slash', () async {
      final service = FileDownloadService.instance;
      final result = await service.downloadFile(
        url: 'https://example.com/file.txt',
        fileName: 'folder/file.txt',
      );
      expect(result, isNull);
    });

    test('rejects subfolder with ..', () async {
      final service = FileDownloadService.instance;
      final result = await service.downloadFile(
        url: 'https://example.com/file.txt',
        fileName: 'file.txt',
        subfolder: '../etc',
      );
      expect(result, isNull);
    });

    test('rejects subfolder with backslash', () async {
      final service = FileDownloadService.instance;
      final result = await service.downloadFile(
        url: 'https://example.com/file.txt',
        fileName: 'file.txt',
        subfolder: 'folder\\sub',
      );
      expect(result, isNull);
    });

    test('rejects subfolder with empty segment', () async {
      final service = FileDownloadService.instance;
      final result = await service.downloadFile(
        url: 'https://example.com/file.txt',
        fileName: 'file.txt',
        subfolder: 'folder//sub',
      );
      expect(result, isNull);
    });

    test('rejects subfolder with . segment', () async {
      final service = FileDownloadService.instance;
      final result = await service.downloadFile(
        url: 'https://example.com/file.txt',
        fileName: 'file.txt',
        subfolder: 'folder/./sub',
      );
      expect(result, isNull);
    });

    test('progress map is initially empty', () {
      final service = FileDownloadService.instance;
      expect(service.progress, isEmpty);
    });

    test('progress map is unmodifiable', () {
      final service = FileDownloadService.instance;
      expect(() => service.progress['test'] = 0.5, throwsUnsupportedError);
    });
  });
}
