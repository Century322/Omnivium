
import 'di/app_di.dart';
import 'app_logger.dart';
import 'package:html/parser.dart' as html_parser;
import 'api_proxy_service.dart';

class LinkPreviewData {
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? siteName;
  final String url;

  const LinkPreviewData({
    this.title,
    this.description,
    this.imageUrl,
    this.siteName,
    required this.url,
  });
}

class LinkPreviewService {
  static final _cache = <String, _CacheEntry>{};
  static const _cacheTtl = Duration(hours: 6);
  static const _maxCacheSize = 100;

  static const _blockedHosts = {
    'localhost',
    '127.0.0.1',
    '0.0.0.0',
    '::1',
    '169.254.169.254',
    'metadata.google.internal',
    'metadata.internal',
  };

  static const _blockedSchemes = {
    'file',
    'ftp',
    'data',
    'javascript',
    'vbscript',
  };

  static bool _isUrlSafe(String url) {
    try {
      final uri = Uri.parse(url);
      if (_blockedSchemes.contains(uri.scheme)) return false;
      if (uri.scheme != 'http' && uri.scheme != 'https') return false;
      final host = uri.host;
      if (host.isEmpty) return false;
      if (_blockedHosts.contains(host)) return false;
      if (host.startsWith('192.168.') || host.startsWith('10.')) return false;
      final octets = host.split('.');
      if (octets.length == 4 && octets[0] == '172') {
        final second = int.tryParse(octets[1]) ?? 0;
        if (second >= 16 && second <= 31) return false;
      }
      return true;
    } catch (e) {
      AppLogger.instance.debug('Link preview fetch failed', error: e);
      return false;
    }
  }

  static Future<LinkPreviewData?> fetchPreview(String url) async {
    final cached = _cache[url];
    if (cached != null && !cached.isExpired) return cached.data;
    if (cached != null && cached.isExpired) _cache.remove(url);

    if (!_isUrlSafe(url)) {
      AppLogger.instance.warning('Blocked unsafe URL in link preview: $url');
      return null;
    }

    try {
      final uri = Uri.parse(url);
      final response = await getIt<ApiProxyService>().secureClient
          .get(uri)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;

      final document = html_parser.parse(response.body);
      final head = document.head;
      if (head == null) return null;

      String? getMeta(String property) {
        final element = head.querySelector('meta[property="$property"]');
        if (element != null) return element.attributes['content'];
        final nameElement = head.querySelector('meta[name="$property"]');
        if (nameElement != null) return nameElement.attributes['content'];
        return null;
      }

      String? title = getMeta('og:title') ?? getMeta('twitter:title');
      if (title == null) {
        final titleEl = head.querySelector('title');
        title = titleEl?.text;
      }

      String? description =
          getMeta('og:description') ??
          getMeta('twitter:description') ??
          getMeta('description');

      String? imageUrl = getMeta('og:image') ?? getMeta('twitter:image');
      if (imageUrl != null && !imageUrl.startsWith('http')) {
        try {
          imageUrl = uri.resolve(imageUrl).toString();
        } catch (e, stackTrace) {
          AppLogger.instance.warning(
            'Image URL resolve failed',
            error: e,
            stackTrace: stackTrace);
          imageUrl = null;
        }
      }

      String? siteName = getMeta('og:site_name');

      final data = LinkPreviewData(
        title: title?.trim(),
        description: description?.trim(),
        imageUrl: imageUrl,
        siteName: siteName?.trim(),
        url: url);

      if (_cache.length >= _maxCacheSize) {
        _cache.remove(_cache.keys.first);
      }
      _cache[url] = _CacheEntry(data, DateTime.now());
      return data;
    } catch (e) {
      AppLogger.instance.info('Link preview fetch failed for $url: $e');
      return null;
    }
  }

  static Future<LinkPreviewData?> getCachedOrFetch(String url) async {
    final cached = _cache[url];
    if (cached != null && !cached.isExpired) return cached.data;
    return await fetchPreview(url);
  }

  static void clearCache() => _cache.clear();
}

class _CacheEntry {
  final LinkPreviewData data;
  final DateTime cachedAt;
  const _CacheEntry(this.data, this.cachedAt);
  bool get isExpired =>
      DateTime.now().difference(cachedAt) > LinkPreviewService._cacheTtl;
}
