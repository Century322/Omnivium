import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'core/app_navigator.dart';
import 'core/app_config.dart';
import 'core/analytics_service.dart';
import 'core/agent/agent_reminder_service.dart' show ReminderService;
import 'core/navigation_provider.dart';
import 'presentation/widgets/app_error_boundary.dart';
import 'core/secure_storage_service.dart';
import 'core/privacy_consent_service.dart';
import 'core/voice_service.dart';
import 'core/database_service.dart';
import 'core/deep_link_service.dart';
import 'core/network_security_service.dart';
import 'core/encryption_service.dart';
import 'core/lite_mode.dart';
import 'core/file_log.dart';
import 'core/database_migration.dart';
import 'core/app_lock_service.dart';
import 'core/biometric_service.dart';
import 'core/secure_flag_service.dart';
import 'core/encrypted_file_storage.dart';
import 'core/password_key_service.dart';
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
import 'core/service_locator.dart';
import 'core/runtime/sandbox/wasm_sandbox_service.dart';
import 'core/runtime/sdk/omnivium_sdk.dart';
import 'core/database_persistence_backend.dart';
import 'core/app_data_gateway.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'presentation/views/home_view.dart';
import 'presentation/views/discover_view.dart';
import 'presentation/views/search_view.dart';
import 'presentation/views/settings_view.dart';
import 'presentation/views/matrix_login_view.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppErrorHandler.init();
  MediaKit.ensureInitialized();

  AppLogger.instance.info('Omnivium starting: ${AppConfig.toDiagnosticMap()}');

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger.instance.error(
      'Flutter error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.instance.error(
      'Uncaught platform error',
      error: error,
      stackTrace: stack,
    );
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
              Text(
                'Error occurred',
                style: TextStyle(color: AppColors.danger, fontSize: 16),
              ),
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
      AppLogger.instance.warning('Vodozemac init failed', error: e);
    }
  }
  await AnalyticsService.instance.init();
  try {
    final sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
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
          options.beforeSend = (event, hint) {
            final message = (event.message?.formatted ?? '').toLowerCase();
            final exception =
                event.exceptions?.firstOrNull?.value.toString().toLowerCase() ??
                '';
            final combined = '$message $exception';
            final sensitivePatterns = [
              'password',
              'token',
              'secret',
              'api_key',
              'apikey',
              'authorization',
              'bearer',
              'private_key',
              'access_token',
              'refresh_token',
              'session_id',
              'cookie',
            ];
            for (final pattern in sensitivePatterns) {
              if (combined.contains(pattern)) {
                return null;
              }
            }
            return event;
          };
        },
        appRunner: () async {
          await _initCritical();
          runApp(const OmniviumApp());
          _initDeferred();
        },
      );
    } else {
      await _initCritical();
      runApp(const OmniviumApp());
      _initDeferred();
    }
  } catch (e) {
    AppLogger.instance.warning('Sentry init failed', error: e);
    await _initCritical();
    runApp(const OmniviumApp());
    _initDeferred();
  }
}

final Set<String> _initFailures = {};
bool _criticalInitFailed = false;

Future<void> _initCritical() async {
  await _safeInit(
    () => SecureStorageService.instance.init(),
    'SecureStorage',
    critical: true,
  );
  if (_criticalInitFailed) return;

  await _safeInit(
    () => DatabaseService.instance.init(),
    'Database',
    critical: true,
  );
  if (_criticalInitFailed) return;

  await _safeInit(
    () => DatabaseService.instance.migrateFromSharedPreferences(),
    'DBMigration',
  );

  await _safeInit(() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final storage = SecureStorageService.instance;
    String? deviceId = await storage.read('omnivium_device_id');
    if (deviceId == null) {
      deviceId =
          'dev_${DateTime.now().millisecondsSinceEpoch}_${packageInfo.buildNumber}';
      await storage.write('omnivium_device_id', deviceId);
    }
    ApiProxyService.instance.setDeviceInfo(
      deviceId: deviceId,
      appVersion: '${packageInfo.version}+${packageInfo.buildNumber}',
    );
  }, 'DeviceInfo');

  await setupLocator();
  await _safeInit(
    () => OmniviumSDK.init(persistence: DatabasePersistenceBackend()),
    'RuntimeSDK',
  );
  AppDataGateway.instance.init();
}

void _initDeferred() {
  Future.wait([
    _safeInit(() => VoiceService.instance.init(), 'Voice'),
    _safeInit(() => ReminderService.instance.init(), 'Reminder'),
    _safeInit(() => ApiProxyService.instance.loadUserConfiguredUrl(), 'ApiProxyUserUrl'),
    _safeInit(() => ApiProxyService.instance.init(), 'ApiProxy'),
    _safeInit(
      () => NetworkSecurityService.instance.initWithDynamicPins(),
      'NetworkSecurity',
    ),
    _safeInit(() => EncryptionService.instance.init(), 'Encryption'),
    _safeInit(() => LiteMode.instance.init(), 'LiteMode'),
    _safeInit(() => FileLog.instance.init(), 'FileLog'),
    _safeInit(() => DatabaseMigration.instance.run(), 'DBMigration'),
    _safeInit(() => AppLockService.instance.init(), 'AppLock'),
    _safeInit(() => BiometricService.instance.init(), 'Biometric'),
    _safeInit(() => SecureFlagService.instance.init(), 'SecureFlag'),
    _safeInit(
      () => EncryptedFileStorage.instance.init(),
      'EncryptedFileStorage',
    ),
    _safeInit(() => PasswordKeyService.instance.init(), 'PasswordKey'),
    _safeInit(() => ConnectivityService.instance.init(), 'Connectivity'),
    _safeInit(
      () => PushNotificationService.instance.init(),
      'PushNotification',
    ),
    _safeInit(() => AgentMemoryService.instance.init(), 'AgentMemory'),
    _safeInit(() => EmbeddingService.instance.init(), 'Embedding'),
    _safeInit(() => RemoteConfigService.instance.init(), 'RemoteConfig'),
    _safeInit(() => AuthService.instance.initFromBackend(), 'Auth'),
    _safeInit(() => SupabaseSyncService.instance.init(), 'SupabaseSync'),
    _safeInit(() => WasmSandboxService.instance.init(), 'WasmSandbox'),
  ]).then((_) {});
}

Future<bool> _safeInit(
  Future<void> Function() init,
  String name, {
  bool critical = false,
}) async {
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

class _AppLockDialog extends StatefulWidget {
  final AppLockService lock;
  final VoidCallback onUnlocked;
  const _AppLockDialog({required this.lock, required this.onUnlocked});

  @override
  State<_AppLockDialog> createState() => _AppLockDialogState();
}

class _AppLockDialogState extends State<_AppLockDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() async {
    final input = _controller.text;
    final ok = await widget.lock.verify(input);
    if (ok) {
      widget.lock.recordUnlock();
      widget.onUnlocked();
    } else {
      setState(() {
        _error = localeProvider.t('incorrect_pin');
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '🔒',
          style: TextStyle(color: AppColors.textPrimary(context)),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              obscureText: true,
              keyboardType: TextInputType.number,
              autofocus: true,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: localeProvider.t('enter_pin'),
                errorText: _error,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: _submit,
            child: Text(localeProvider.t('unlock')),
          ),
        ],
      ),
    );
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
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.mode,
          locale: localeProvider.locale,
          localizationsDelegates: [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh'),
            Locale('en'),
            Locale('ja'),
            Locale('ko'),
          ],
          onGenerateRoute: AppNavigator.onGenerateRoute,
          home: const _AppShell(),
        );
      },
    );
  }
}

final themeProvider = AppProvider.instance?.theme ?? ThemeProvider();

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell>
    with TickerProviderStateMixin, WidgetsBindingObserver {
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              localeProvider.t('update_available'),
              style: TextStyle(color: AppColors.textPrimary(context)),
            ),
            content: Text(
              '${localeProvider.t('new_version')}: $latestVersion${minVersion != null ? '\n${localeProvider.t('min_version_required')}: $minVersion' : ''}',
              style: TextStyle(color: AppColors.textSecondary(context)),
            ),
            actions: [
              if (!forceUpdate)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    localeProvider.t('later'),
                    style: TextStyle(color: AppColors.sec(context)),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  localeProvider.t('update_now'),
                  style: TextStyle(color: AppColors.acc(context)),
                ),
              ),
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
    PushNotificationService.instance.dispose();
    VoiceService.instance.dispose();
    disposeFirebaseMessaging();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAppLock();
      if (!_provider.matrix.isLoggedIn) {
        _provider.matrix.tryRestoreSession().then((restored) {
          if (restored && mounted) {
            setState(() {
              _showLogin = false;
            });
          }
        });
      }
      SupabaseSyncService.instance.init();
    } else if (state == AppLifecycleState.paused) {
      VoiceService.instance.stopListening();
    }
  }

  void _checkAppLock() {
    final lock = AppLockService.instance;
    if (!lock.isEnabled || !lock.isLocked) return;
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _AppLockDialog(lock: lock, onUnlocked: () => Navigator.pop(context)),
    );
  }

  Future<void> _init() async {
    try {
      await SecurityCheckService.instance.check();
    } catch (e) {
      AppLogger.instance.warning('SecurityCheck init failed', error: e);
    }
    try {
      NetworkSecurityService.instance.enablePinning();
    } catch (e) {
      AppLogger.instance.warning(
        'NetworkSecurity enablePinning failed',
        error: e,
      );
    }
    bool restored = false;
    try {
      restored = await _provider.matrix.tryRestoreSession();
    } catch (e) {
      AppLogger.instance.warning('Matrix session restore failed', error: e);
    }
    try {
      await ApiProxyService.instance.init();
    } catch (e) {
      AppLogger.instance.warning('ApiProxy init failed', error: e);
    }
    try {
      await _provider.initSubProviders();
    } catch (e) {
      AppLogger.instance.warning('Provider init failed', error: e);
    }
    bool hasConsented = false;
    try {
      hasConsented = await _privacyService.hasConsented();
    } catch (e) {
      AppLogger.instance.warning('PrivacyConsent check failed', error: e);
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
      AppLogger.instance.warning('DeepLink init failed', error: e);
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
        AppNavigator.init(_provider);
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.security, color: AppColors.warn(context), size: 24),
              const SizedBox(width: 8),
              Text(
                localeProvider.t('security_warning'),
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 17,
                ),
              ),
            ],
          ),
          content: Text(
            localeProvider.t('security_warning_desc'),
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                localeProvider.t('understand'),
                style: TextStyle(color: AppColors.acc(context)),
              ),
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
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFFFFFFFF),
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFFFFFFFF),
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: const Color(0xFFFFFFFF),
          ),
          home: Scaffold(
            backgroundColor: const Color(0xFFFFFFFF),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/icon/app_icon.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.acc(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_showPrivacyConsent) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: themeProvider.overlayStyle,
        child: MaterialApp(
          theme: themeProvider.darkTheme,
          home: _PrivacyConsentScreen(onResult: _onPrivacyConsentResult),
        ),
      );
    }

    return ListenableBuilder(
      listenable: Listenable.merge([
        _provider.navigation,
        _provider.matrix,
        localeProvider,
        themeProvider,
      ]),
      builder: (context, _) {
        final isLoggedIn = _provider.matrix.isLoggedIn;
        if (!isLoggedIn && !_showLogin) {
          _showLogin = true;
        }

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: themeProvider.overlayStyle,
          child: PopScope(
            canPop:
                !_provider.navigation.isSettingsOpen &&
                _provider.navigation.currentView == ViewState.home,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              if (_provider.navigation.isSettingsOpen) {
                _provider.navigation.closeSettingsAndReturnToDrawer();
              } else if (_provider.navigation.currentView != ViewState.home) {
                _provider.navigation.goBack();
              }
            },
            child: AppErrorBoundary(
              child: Stack(
                children: [
                  HomeView(provider: _provider),
                  if (_showLogin && !isLoggedIn)
                    MatrixLoginView(
                      provider: _provider,
                      onLoginSuccess: _onLoginSuccess,
                    ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      );
                    },
                    child: _buildCurrentOverlay(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget? _buildCurrentOverlay() {
    if (_provider.navigation.isSettingsOpen) {
      return SettingsView(key: const ValueKey('settings'), provider: _provider);
    }
    switch (_provider.navigation.currentView) {
      case ViewState.discover:
        return DiscoverView(
          key: const ValueKey('discover'),
          provider: _provider,
        );
      case ViewState.search:
        return SearchView(key: const ValueKey('search'), provider: _provider);
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
      backgroundColor: AppColors.bg(context),
      body: Center(
        child: CircularProgressIndicator(color: AppColors.acc(context)),
      ),
    );
  }
}
