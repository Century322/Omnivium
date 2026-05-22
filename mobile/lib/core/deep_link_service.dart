import 'app_logger.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._();
  static DeepLinkService get instance => _instance;
  DeepLinkService._();

  static const _allowedHosts = {'chat', 'room', 'settings', 'profile'};
  static const _allowedSchemes = {'omnivium', 'https'};

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  Uri? _initialLink;
  Uri? get initialLink => _initialLink;

  Future<void> init() async {
    try {
      _initialLink = await _appLinks.getInitialLink();
      if (_initialLink != null && !_isValidDeepLink(_initialLink!)) {
        AppLogger.instance.warning(
          'Blocked invalid initial deep link: $_initialLink',
        );
        _initialLink = null;
      }
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'Deep link init failed',
        error: e,
        stackTrace: stackTrace,
      );
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        if (_isValidDeepLink(uri)) {
          _handleDeepLink(uri);
        } else {
          AppLogger.instance.warning('Blocked invalid deep link: $uri');
        }
      },
      onError: (err) {
        AppLogger.instance.info('Deep link error: $err');
      },
    );
  }

  void dispose() {
    _linkSubscription?.cancel();
  }

  bool _isValidDeepLink(Uri uri) {
    if (!_allowedSchemes.contains(uri.scheme)) return false;
    if (uri.scheme == 'omnivium' && !_allowedHosts.contains(uri.host))
      return false;
    if (uri.scheme == 'https' && uri.host != 'omnivium.app') return false;
    final id =
        uri.queryParameters['id'] ??
        (uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '');
    if (id.length > 256) return false;
    return true;
  }

  void Function(Uri uri)? onDeepLink;

  void _handleDeepLink(Uri uri) {
    AppLogger.instance.info('Deep link received: ${uri.scheme}://${uri.host}');
    onDeepLink?.call(uri);
  }

  String? _parseId(Uri uri) {
    return uri.queryParameters['id'] ??
        (uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null);
  }

  String? parseSessionId(Uri uri) {
    if (uri.scheme != 'omnivium') return null;
    if (uri.host == 'chat') return _parseId(uri);
    return null;
  }

  String? parseRoomId(Uri uri) {
    if (uri.scheme != 'omnivium') return null;
    if (uri.host == 'room') return _parseId(uri);
    return null;
  }
}
