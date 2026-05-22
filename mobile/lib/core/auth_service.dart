import 'app_logger.dart';
import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'secure_storage_service.dart';
import 'api_proxy_service.dart';
import 'matrix/matrix_service.dart';
import 'identity_bridge.dart';

class AuthService {
  static final AuthService _instance = AuthService._();
  static AuthService get instance => _instance;
  AuthService._();

  static const _supabaseUrlKey = 'supabase_url';
  static const _supabaseAnonKeyKey = 'supabase_anon_key';
  static const _supabaseUrlEnvKey = 'SUPABASE_URL';
  static const _supabaseAnonKeyEnvKey = 'SUPABASE_ANON_KEY';

  SupabaseClient? _client;
  User? _currentUser;
  String? _jwtToken;
  StreamSubscription<AuthState>? _authSubscription;
  Timer? _refreshTimer;
  bool _supabaseInitialized = false;

  User? get currentUser => _currentUser;
  String? get jwtToken => _jwtToken;
  bool get isAuthenticated => _currentUser != null;
  String? get matrixUserId =>
      _currentUser?.userMetadata?['matrix_user_id'] as String?;
  SupabaseClient? get client => _client;
  bool get isSupabaseInitialized => _supabaseInitialized;

  final _authStateController = StreamController<AuthState>.broadcast();
  Stream<AuthState> get onAuthStateChange => _authStateController.stream;

  String? _getEnv(String envKey) {
    if (envKey == _supabaseUrlEnvKey) {
      final value = const String.fromEnvironment('SUPABASE_URL');
      return value.isEmpty ? null : value;
    }
    if (envKey == _supabaseAnonKeyEnvKey) {
      final value = const String.fromEnvironment('SUPABASE_ANON_KEY');
      return value.isEmpty ? null : value;
    }
    return null;
  }

  Future<void> initFromBackend() async {
    final storage = SecureStorageService.instance;
    String? cachedUrl = await storage.read(_supabaseUrlKey);
    String? cachedKey = await storage.read(_supabaseAnonKeyKey);

    if (cachedUrl == null || cachedKey == null) {
      final envUrl = _getEnv(_supabaseUrlEnvKey);
      final envKey = _getEnv(_supabaseAnonKeyEnvKey);
      if (envUrl == null ||
          envUrl.isEmpty ||
          envKey == null ||
          envKey.isEmpty) {
        AppLogger.instance.warning(
          'Supabase credentials not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define or backend config.',
        );
        return;
      }
      cachedUrl = envUrl;
      cachedKey = envKey;
    }

    await storage.write(_supabaseUrlKey, cachedUrl);
    await storage.write(_supabaseAnonKeyKey, cachedKey);
    await _initSupabase(cachedUrl, cachedKey);

    try {
      final proxy = ApiProxyService.instance;
      if (proxy.isConfigured) {
        final uri = Uri.parse('${proxy.backendUrl}/config/init');
        final response = await proxy.secureClient
            .get(uri, headers: proxy.buildDeviceHeaders())
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          final url = body['supabase_url'] as String?;
          final anonKey = body['supabase_anon_key'] as String?;
          if (url != null &&
              anonKey != null &&
              (url != cachedUrl || anonKey != cachedKey)) {
            await storage.write(_supabaseUrlKey, url);
            await storage.write(_supabaseAnonKeyKey, anonKey);
            await _reinitSupabase(url, anonKey);
          }
        }
      }
    } catch (e) {
      AppLogger.instance.info('Failed to fetch config from backend: $e');
    }

    _tryAutoSignInWithMatrix();
  }

  Future<void> _initSupabase(String url, String anonKey) async {
    if (_supabaseInitialized) return;
    try {
      await Supabase.initialize(url: url, anonKey: anonKey);
      _client = Supabase.instance.client;
      _supabaseInitialized = true;
      _setupAuthListener();
      _startTokenRefreshTimer();
    } catch (e) {
      AppLogger.instance.warning('Supabase init failed', error: e);
    }
  }

  Future<void> _reinitSupabase(String url, String anonKey) async {
    if (!_supabaseInitialized) {
      await _initSupabase(url, anonKey);
      return;
    }
    AppLogger.instance.info(
      'Supabase config updated from backend, will apply on next app restart',
    );
  }

  void _setupAuthListener() {
    if (_client == null) return;
    _authSubscription?.cancel();
    _authSubscription = _client!.auth.onAuthStateChange.listen((event) {
      _currentUser = event.session?.user;
      _jwtToken = event.session?.accessToken;
      _authStateController.add(event);
    });

    final session = _client!.auth.currentSession;
    if (session != null) {
      _currentUser = session.user;
      _jwtToken = session.accessToken;
    }
  }

  void _startTokenRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (isAuthenticated) {
        refreshSession();
      }
    });
  }

  void _tryAutoSignInWithMatrix() async {
    final matrix = MatrixService.instance;
    if (!matrix.isLoggedIn || _client == null) return;
    if (isAuthenticated) return;

    final userId = matrix.userId;
    if (userId == null) return;

    await _linkMatrixAccount(userId);
  }

  Future<void> _linkMatrixAccount(String matrixUserId) async {
    if (_client == null || !_supabaseInitialized) return;
    try {
      if (isAuthenticated) {
        final currentMeta = _currentUser?.userMetadata;
        if (currentMeta?['matrix_user_id'] == matrixUserId) return;
      }
      final response = await _client!.auth.signInAnonymously();
      _currentUser = response.user;
      _jwtToken = response.session?.accessToken;
      await _client!.auth.updateUser(
        UserAttributes(data: {'matrix_user_id': matrixUserId}),
      );
      if (_currentUser != null) {
        await IdentityBridge.instance.onUserAuthenticated(
          _currentUser!.id,
          matrixId: matrixUserId,
        );
      }
    } catch (e) {
      AppLogger.instance.info('Auto sign-in with Matrix failed: $e');
    }
  }

  void onMatrixLogin() {
    final userId = MatrixService.instance.userId;
    if (userId != null) {
      _linkMatrixAccount(userId);
    } else {
      _tryAutoSignInWithMatrix();
    }
  }

  void onMatrixLogout() {
    if (_client == null) return;
    signOut();
  }

  Future<bool> signIn({required String email, required String password}) async {
    if (_client == null || !_supabaseInitialized) return false;
    try {
      final response = await _client!.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _currentUser = response.user;
      _jwtToken = response.session?.accessToken;
      if (_currentUser != null) {
        await IdentityBridge.instance.onUserAuthenticated(_currentUser!.id);
      }
      return _currentUser != null;
    } catch (e) {
      AppLogger.instance.warning('Sign in failed', error: e);
      return false;
    }
  }

  Future<void> signOut() async {
    if (_client == null) return;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    await _authSubscription?.cancel();
    _authSubscription = null;
    try {
      await _client!.auth.signOut();
    } catch (e) {
      AppLogger.instance.warning('Sign out failed', error: e);
    }
    _currentUser = null;
    _jwtToken = null;
    await IdentityBridge.instance.onLogout();
  }

  Future<bool> refreshSession() async {
    if (_client == null || !_supabaseInitialized) return false;
    try {
      final response = await _client!.auth.refreshSession();
      _currentUser = response.user;
      _jwtToken = response.session?.accessToken;
      return _currentUser != null;
    } catch (e) {
      AppLogger.instance.warning('Session refresh failed', error: e);
      return false;
    }
  }

  void dispose() {
    _refreshTimer?.cancel();
    _authSubscription?.cancel();
    _authStateController.close();
  }
}
