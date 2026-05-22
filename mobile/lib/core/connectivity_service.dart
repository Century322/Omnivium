import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'app_logger.dart';

enum NetworkQuality { excellent, good, poor, unknown }

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  static ConnectivityService get instance => _instance;
  ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  final StreamController<NetworkQuality> _qualityController =
      StreamController<NetworkQuality>.broadcast();
  StreamSubscription? _subscription;
  bool _isOnline = true;
  bool _initialized = false;
  NetworkQuality _quality = NetworkQuality.unknown;
  ConnectivityResult _connectionType = ConnectivityResult.none;
  DateTime? _lastOnlineTime;
  DateTime? _lastOfflineTime;

  bool get isOnline => _isOnline;
  bool get isInitialized => _initialized;
  NetworkQuality get quality => _quality;
  ConnectivityResult get connectionType => _connectionType;
  DateTime? get lastOnlineTime => _lastOnlineTime;
  DateTime? get lastOfflineTime => _lastOfflineTime;
  Duration? get offlineDuration => _lastOfflineTime != null
      ? DateTime.now().difference(_lastOfflineTime!)
      : null;

  Stream<bool> get onConnectivityChanged => _controller.stream;
  Stream<NetworkQuality> get onQualityChanged => _qualityController.stream;

  bool get isWifi => _connectionType == ConnectivityResult.wifi;
  bool get isMobile => _connectionType == ConnectivityResult.mobile;
  bool get isExpensive => _connectionType == ConnectivityResult.mobile;

  Future<void> init() async {
    if (_initialized) return;

    try {
      final initialResult = await _connectivity.checkConnectivity();
      _connectionType = initialResult.isNotEmpty
          ? initialResult.first
          : ConnectivityResult.none;
      _isOnline = initialResult.any((r) => r != ConnectivityResult.none);
      _quality = _inferQuality(_connectionType);
      if (_isOnline) _lastOnlineTime = DateTime.now();
      _controller.add(_isOnline);
      _qualityController.add(_quality);
      _initialized = true;
    } catch (e) {
      AppLogger.instance.warning(
        'Initial connectivity check failed, assuming offline',
        error: e,
      );
      _isOnline = false;
      _initialized = true;
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      final newType = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;
      final newQuality = _inferQuality(newType);

      _connectionType = newType;

      if (online != _isOnline) {
        _isOnline = online;
        if (online) {
          _lastOnlineTime = DateTime.now();
        } else {
          _lastOfflineTime = DateTime.now();
        }
        _controller.add(online);
        AppLogger.instance.info(
          'Connectivity changed: ${online ? 'online' : 'offline'}',
        );
      }

      if (newQuality != _quality) {
        _quality = newQuality;
        _qualityController.add(_quality);
      }
    });
  }

  NetworkQuality _inferQuality(ConnectivityResult type) {
    switch (type) {
      case ConnectivityResult.wifi:
        return NetworkQuality.excellent;
      case ConnectivityResult.mobile:
        return NetworkQuality.good;
      case ConnectivityResult.ethernet:
        return NetworkQuality.excellent;
      case ConnectivityResult.bluetooth:
        return NetworkQuality.poor;
      case ConnectivityResult.vpn:
        return NetworkQuality.good;
      default:
        return NetworkQuality.unknown;
    }
  }

  Future<void> forceCheck() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final online = result.any((r) => r != ConnectivityResult.none);
      _connectionType = result.isNotEmpty
          ? result.first
          : ConnectivityResult.none;
      final newQuality = _inferQuality(_connectionType);
      if (online != _isOnline) {
        _isOnline = online;
        if (online) {
          _lastOnlineTime = DateTime.now();
        } else {
          _lastOfflineTime = DateTime.now();
        }
        _controller.add(online);
      }
      if (newQuality != _quality) {
        _quality = newQuality;
        _qualityController.add(_quality);
      }
    } catch (e) {
      AppLogger.instance.warning('Force connectivity check failed', error: e);
    }
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
    _qualityController.close();
  }
}
