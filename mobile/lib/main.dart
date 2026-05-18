import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'l10n/app_localizations.dart';
import 'presentation/theme/app_colors.dart';
import 'presentation/theme/theme_provider.dart';
import 'presentation/theme/locale_provider.dart';
import 'core/app_provider.dart';
import 'core/navigation_provider.dart';
import 'core/secure_storage_service.dart';
import 'core/privacy_consent_service.dart';
import 'core/voice_service.dart';
import 'core/database_service.dart';
import 'core/deep_link_service.dart';
import 'core/network_security_service.dart';
import 'core/api_proxy_service.dart';
import 'core/providers/ai_provider.dart';
import 'core/security_check_service.dart';
import 'core/vodozemac_init.dart';
import 'core/push_notification_service.dart';
import 'core/push_notification_service_io.dart'
    if (dart.library.html) 'core/push_notification_service_stub.dart';
import 'core/remote_config_service.dart';
import 'core/agent/agent_memory_service.dart';
import 'core/agent/embedding_service.dart';
import 'core/auth_service.dart';
import 'core/supabase_sync_service.dart';
import 'core/app_logger.dart';
import 'core/connectivity_service.dart';
import 'core/offline_service.dart';
import 'core/service_locator.dart';
import 'core/ab_test_service.dart';
import 'core/crash_recovery_service.dart';
import 'core/performance_monitor_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'presentation/views/home_view.dart';
import 'presentation/views/voice_view.dart';
import 'presentation/views/discover_view.dart';
import 'presentation/views/search_view.dart';
import 'presentation/views/library_view.dart';
import 'presentation/views/settings_view.dart';
import 'presentation/views/matrix_login_view.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger.instance.error('Flutter error', error: details.exception, stackTrace: details.stack);
    CrashRecoveryService.instance.reportUnhandledError(details.exception, details.stack ?? StackTrace.empty);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.instance.error('Uncaught platform error', error: error, stackTrace: stack);
    CrashRecoveryService.instance.reportUnhandledError(error, stack);
    return true;
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: AppColors.danger, size: 48),
              const SizedBox(height: 16),
              Text('Error occurred', style: TextStyle(color: AppColors.danger, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  };
  if (!kIsWeb) {
    try {
      await initVodozemac();
    } catch (e) {
      if (kDebugMode) debugPrint('Vodozemac init failed: $e');
    }
  }
  try {
    final sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: 'https://8c3a67d45a320eff8d5567632224a2bc@o4511395076046848.ingest.us.sentry.io/4511395086139392');
    if (sentryDsn.isNotEmpty) {
      await SentryFlutter.init(
        (options) {
          options.dsn = sentryDsn;
          options.tracesSampleRate = 0.2;
          // ignore: experimental_member_use
          options.profilesSampleRate = kDebugMode ? 1.0 : 0.1;
          options.environment = kDebugMode ? 'development' : 'production';
          options.enableAutoSessionTracking = true;
          options.attachThreads = true;
        },
        appRunner: () async {
          await _initApp();
          runApp(const OmniviumApp());
        },
      );
    } else {
      await _initApp();
      runApp(const OmniviumApp());
    }
  } catch (e) {
    if (kDebugMode) debugPrint('Sentry init failed: $e');
    await _initApp();
    runApp(const OmniviumApp());
  }
}

final Set<String> _initFailures = {};
bool _criticalInitFailed = false;

Future<void> _initApp() async {
  await _safeInit(() => SecureStorageService.instance.init(), 'SecureStorage', critical: true);
  if (_criticalInitFailed) return;

  await _safeInit(() => DatabaseService.instance.init(), 'Database', critical: true);
  if (_criticalInitFailed) return;

  await _safeInit(() => DatabaseService.instance.migrateFromSharedPreferences(), 'DBMigration');

  await _safeInit(() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final storage = SecureStorageService.instance;
    String? deviceId = await storage.read('omnivium_device_id');
    if (deviceId == null) {
      deviceId = 'dev_${DateTime.now().millisecondsSinceEpoch}_${packageInfo.buildNumber}';
      await storage.write('omnivium_device_id', deviceId);
    }
    ApiProxyService.instance.setDeviceInfo(
      deviceId: deviceId,
      appVersion: '${packageInfo.version}+${packageInfo.buildNumber}',
    );
  }, 'DeviceInfo');

  await setupLocator();

  await _safeInit(() => CrashRecoveryService.instance.init(), 'CrashRecovery');
  await _safeInit(() => CrashRecoveryService.instance.markAppStart(), 'CrashFlag');
  await _safeInit(() => PerformanceMonitorService.instance.init(), 'PerformanceMonitor');

  await _safeInit(() => VoiceService.instance.init(), 'Voice');
  await _safeInit(() => ApiProxyService.instance.init(), 'ApiProxy');
  await _safeInit(() => NetworkSecurityService.instance.initWithDynamicPins(), 'NetworkSecurity');
  await _safeInit(() => ConnectivityService.instance.init(), 'Connectivity');
  _safeInitSync(() => OfflineService.instance.init(), 'Offline');
  await _safeInit(() => PushNotificationService.instance.init(), 'PushNotification');
  await _safeInit(() => AgentMemoryService.instance.init(), 'AgentMemory');
  await _safeInit(() => EmbeddingService.instance.init(), 'Embedding');
  await _safeInit(() => RemoteConfigService.instance.init(), 'RemoteConfig');
  await _safeInit(() => ABTestService.instance.init(), 'ABTest');
  await _safeInit(() => AuthService.instance.initFromBackend(), 'Auth');
  await _safeInit(() => SupabaseSyncService.instance.init(), 'SupabaseSync');

  if (CrashRecoveryService.instance.crashDetected) {
    await CrashRecoveryService.instance.attemptRecovery();
  }
}

Future<bool> _safeInit(Future<void> Function() init, String name, {bool critical = false}) async {
  try {
    await init();
    return true;
  } catch (e) {
    _initFailures.add(name);
    if (critical) {
      _criticalInitFailed = true;
      AppLogger.instance.fatal('Critical service $name init failed', error: e);
    } else {
      AppLogger.instance.error('$name init failed', error: e);
    }
    return false;
  }
}

bool _safeInitSync(void Function() init, String name, {bool critical = false}) {
  try {
    init();
    return true;
  } catch (e) {
    _initFailures.add(name);
    if (critical) {
      _criticalInitFailed = true;
      AppLogger.instance.fatal('Critical service $name init failed', error: e);
    } else {
      AppLogger.instance.error('$name init failed', error: e);
    }
    return false;
  }
}

class OmniviumApp extends StatelessWidget {
  const OmniviumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([themeProvider, localeProvider]),
      builder: (context, _) {
        return MaterialApp(
          title: 'Omnivium',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: ThemeProvider.lightTheme,
          darkTheme: ThemeProvider.darkTheme,
          themeMode: themeProvider.mode,
          locale: localeProvider.locale,
          localizationsDelegates: [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('zh'), Locale('en'), Locale('ja'), Locale('ko')],
          home: const _AppShell(),
        );
      },
    );
  }
}

final themeProvider = ThemeProvider();

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> with TickerProviderStateMixin, WidgetsBindingObserver {
  final AppProvider _provider = AppProvider();
  final _privacyService = PrivacyConsentService();
  StreamSubscription<AuthEvent>? _authEventSub;
  bool _initialized = false;
  bool _showLogin = false;
  bool _showPrivacyConsent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    try {
      final status = await ApiProxyService.instance.checkAppStatus();
      final forceUpdate = status['force_update'] as bool? ?? false;
      final suggestUpdate = status['suggest_update'] as bool? ?? false;
      final minVersion = status['min_version'] as String?;
      final latestVersion = status['latest_version'] as String?;
      if ((forceUpdate || suggestUpdate) && latestVersion != null && mounted) {
        showDialog(
          context: context,
          barrierDismissible: !forceUpdate,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.sf(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(localeProvider.t('update_available'), style: TextStyle(color: AppColors.textPrimary(context))),
            content: Text('${localeProvider.t('new_version')}: $latestVersion${minVersion != null ? '\n${localeProvider.t('min_version_required')}: $minVersion' : ''}', style: TextStyle(color: AppColors.textSecondary(context))),
            actions: [
              if (!forceUpdate) TextButton(onPressed: () => Navigator.pop(context), child: Text(localeProvider.t('later'), style: TextStyle(color: AppColors.sec(context)))),
              TextButton(onPressed: () => Navigator.pop(context), child: Text(localeProvider.t('update_now'), style: TextStyle(color: AppColors.accent))),
            ],
          ),
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _authEventSub?.cancel();
    _provider.session.saveCurrentSession();
    _provider.dispose();
    ConnectivityService.instance.dispose();
    DeepLinkService.instance.dispose();
    OfflineService.instance.dispose();
    PushNotificationService.instance.dispose();
    VoiceService.instance.dispose();
    PerformanceMonitorService.instance.dispose();
    CrashRecoveryService.instance.markAppCleanExit();
    disposeFirebaseMessaging();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_provider.matrix.isLoggedIn) {
        _provider.matrix.tryRestoreSession();
      }
      SupabaseSyncService.instance.init();
    } else if (state == AppLifecycleState.paused) {
      VoiceService.instance.stopListening();
    }
  }

  Future<void> _init() async {
    try {
      await SecurityCheckService.instance.check();
    } catch (e) {
      if (kDebugMode) debugPrint('SecurityCheck init failed: $e');
    }
    try {
      NetworkSecurityService.instance.enablePinning();
    } catch (e) {
      if (kDebugMode) debugPrint('NetworkSecurity enablePinning failed: $e');
    }
    bool restored = false;
    try {
      restored = await _provider.matrix.tryRestoreSession();
    } catch (e) {
      if (kDebugMode) debugPrint('Matrix session restore failed: $e');
    }
    try {
      await ApiProxyService.instance.init();
    } catch (e) {
      if (kDebugMode) debugPrint('ApiProxy init failed: $e');
    }
    try {
      await _provider.initSubProviders();
    } catch (e) {
      if (kDebugMode) debugPrint('Provider init failed: $e');
    }
    bool hasConsented = false;
    try {
      hasConsented = await _privacyService.hasConsented();
    } catch (e) {
      if (kDebugMode) debugPrint('PrivacyConsent check failed: $e');
    }
    try {
      await DeepLinkService.instance.init();
      DeepLinkService.instance.onDeepLink = (uri) {
        final sessionId = DeepLinkService.instance.parseSessionId(uri);
        if (sessionId != null) {
          _provider.session.switchSession(sessionId);
        }
      };
      final initialLink = DeepLinkService.instance.initialLink;
      if (initialLink != null) {
        DeepLinkService.instance.onDeepLink?.call(initialLink);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('DeepLink init failed: $e');
    }
    if (mounted) {
      _provider.session.startAutoSave();
      _authEventSub = ChatService.onAuthEvent.listen((event) {
        if (event == AuthEvent.tokenExpired && mounted) {
          setState(() {
            _showLogin = true;
          });
        }
      });
      setState(() {
        _initialized = true;
        _showPrivacyConsent = !hasConsented;
        _showLogin = !restored && !_provider.matrix.isLoggedIn;
      });
      _checkSecurityWarning();
    }
  }

  void _checkSecurityWarning() {
    final security = SecurityCheckService.instance;
    if (!security.isCompromised) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context == null) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.sf(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Icon(Icons.security, color: AppColors.warn(context), size: 24),
            const SizedBox(width: 8),
            Text(localeProvider.t('security_warning'), style: TextStyle(color: AppColors.textPrimary(context), fontSize: 17)),
          ]),
          content: Text(localeProvider.t('security_warning_desc'), style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localeProvider.t('understand'), style: TextStyle(color: AppColors.accent)),
            ),
          ],
        ),
      );
    });
  }

  void _onLoginSuccess() {
    AuthService.instance.onMatrixLogin();
    setState(() => _showLogin = false);
  }

  void _onPrivacyConsentResult(bool agreed) async {
    if (agreed) {
      await _privacyService.grantConsent();
    }
    if (mounted) setState(() => _showPrivacyConsent = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        theme: ThemeProvider.lightTheme,
        darkTheme: ThemeProvider.darkTheme,
        themeMode: themeProvider.mode,
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
        ),
      );
    }

    if (_showPrivacyConsent) {
      return MaterialApp(
        theme: ThemeProvider.darkTheme,
        home: _PrivacyConsentScreen(onResult: _onPrivacyConsentResult),
      );
    }

    return ListenableBuilder(
      listenable: Listenable.merge([_provider.navigation, _provider.matrix, localeProvider, themeProvider]),
      builder: (context, _) {
        final isLoggedIn = _provider.matrix.isLoggedIn;
        if (!isLoggedIn && !_showLogin) {
          _showLogin = true;
        }

        return Stack(
          children: [
            HomeView(provider: _provider),
            if (_showLogin && !isLoggedIn)
              MatrixLoginView(provider: _provider, onLoginSuccess: _onLoginSuccess),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                if (child is VoiceView) {
                  return FadeTransition(opacity: animation, child: child);
                }
                return SlideTransition(
                  position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
                  child: child,
                );
              },
              child: _buildCurrentOverlay(),
            ),
          ],
        );
      },
    );
  }

  Widget? _buildCurrentOverlay() {
    if (_provider.navigation.isSettingsOpen) {
      return SettingsView(key: const ValueKey('settings'), provider: _provider);
    }
    switch (_provider.navigation.currentView) {
      case ViewState.voice:
        return VoiceView(key: const ValueKey('voice'), provider: _provider);
      case ViewState.discover:
        return DiscoverView(key: const ValueKey('discover'), provider: _provider);
      case ViewState.search:
        return SearchView(key: const ValueKey('search'), provider: _provider);
      case ViewState.library:
        return LibraryView(key: const ValueKey('library'), provider: _provider);
      default:
        return null;
    }
  }
}

class _PrivacyConsentScreen extends StatelessWidget {
  final ValueChanged<bool> onResult;
  const _PrivacyConsentScreen({required this.onResult});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final agreed = PrivacyConsentDialog.show(context);
      agreed.then((result) => onResult(result));
    });
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
    );
  }
}
