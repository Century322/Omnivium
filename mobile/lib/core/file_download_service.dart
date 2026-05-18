import 'app_logger.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_proxy_service.dart';

class FileDownloadService {
  static final FileDownloadService _instance = FileDownloadService._();
  static FileDownloadService get instance => _instance;
  FileDownloadService._();

  final Map<String, double> _progress = {};
  Map<String, double> get progress => Map.unmodifiable(_progress);

  Future<String?> downloadFile({
    required String url,
    required String fileName,
    String? subfolder,
  }) async {
    if (fileName.contains('/') || fileName.contains('\\') || fileName.contains('..')) {
      AppLogger.instance.warning('Invalid file name rejected: $fileName');
      return null;
    }
    if (subfolder != null) {
      if (subfolder.contains('..') || subfolder.contains('\\')) {
        AppLogger.instance.warning('Invalid subfolder rejected: $subfolder');
        return null;
      }
      final segments = subfolder.split('/');
      for (final seg in segments) {
        if (seg.isEmpty || seg == '.' || seg == '..') {
          AppLogger.instance.warning('Invalid subfolder segment rejected: $subfolder');
          return null;
        }
      }
    }

    if (!kIsWeb) {
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) return null;
    }

    try {
      final dir = await _getDownloadDirectory();
      if (dir == null) return null;

      final saveDir = subfolder != null ? Directory('${dir.path}/$subfolder') : dir;
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      final filePath = '${saveDir.path}/$fileName';
      final canonicalSaveDir = await saveDir.resolveSymbolicLinks();
      final canonicalFile = await File(filePath).resolveSymbolicLinks();
      if (!canonicalFile.startsWith(canonicalSaveDir)) {
        AppLogger.instance.warning('Path traversal detected: $filePath');
        return null;
      }

      final file = File(filePath);

      if (await file.exists()) {
        return filePath;
      }

      _progress[url] = 0;

      final request = http.Request('GET', Uri.parse(url));
      final response = await ApiProxyService.instance.secureClient.send(request);

      if (response.statusCode != 200) {
        _progress.remove(url);
        return null;
      }

      final contentLength = response.contentLength ?? 0;
      int downloadedBytes = 0;

      final sink = file.openWrite();
      try {
        await response.stream.map((chunk) {
          downloadedBytes += chunk.length;
          if (contentLength > 0) {
            _progress[url] = downloadedBytes / contentLength;
          }
          return chunk;
        }).pipe(sink);
      } catch (e) {
        await sink.close();
        if (await file.exists()) await file.delete();
        rethrow;
      }

      _progress.remove(url);
      return filePath;
    } catch (e) {
      AppLogger.instance.info('Download failed: $e');
      _progress.remove(url);
      return null;
    }
  }

  Future<String?> downloadMatrixFile({
    required String mxcUrl,
    required String fileName,
  }) async {
    final uri = Uri.parse(mxcUrl);
    final httpUrl = uri.replace(scheme: 'https');
    return downloadFile(url: httpUrl.toString(), fileName: fileName, subfolder: 'Omnivium');
  }

  Future<Directory?> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      final dirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
      if (dirs != null && dirs.isNotEmpty) return dirs.first;
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    }
    return null;
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (status.isGranted) return true;
      final result = await Permission.storage.request();
      return result.isGranted;
    }
    return true;
  }
}
