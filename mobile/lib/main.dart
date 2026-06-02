import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
// omnivium
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'l10n/app_localizations.dart';
import 'presentation/theme/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'presentation/theme/theme_cubit.dart';
import 'presentation/theme/locale_cubit.dart';
import 'core/app_navigator.dart';
import 'core/app_router.dart';
import 'core/app_config.dart';
import 'core/analytics_service.dart';
import 'core/agent/agent_reminder_service.dart' show ReminderService;
import 'core/navigation_cubit.dart';
import 'core/session_cubit.dart';
import 'core/di/app_di.dart';
import 'core/matrix/matrix_cubit.dart';
import 'core/model_cubit.dart';
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
import 'core/agent/embedding_service.dart';
import 'core/agent/cognitive/cognitive_engine.dart';
import 'core/agent/cognitive/entity_store.dart';
import 'core/agent/cognitive/goal_store.dart';
import 'core/auth_service.dart';
import 'core/supabase_sync_service.dart';
import 'core/app_logger.dart';
import 'core/connectivity_service.dart';

import 'core/runtime/sandbox/wasm_sandbox_service.dart';
import 'core/runtime/sdk/omnivium_sdk.dart';
import 'core/database_persistence_backend.dart';
import 'core/app_data_gateway.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'presentation/views/home_view.dart';
import 'presentation/views/discover_view.dart';
import 'presentation/views/search_view.dart';
import 'features/auth/presentation/pages/unified_login_page.dart';
import 'presentation/widgets/friend_chat_panel.dart';
import 'features/settings/presentation/pages/settings_page.dart';

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
      stackTrace: details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.instance.error(
      'Uncaught platform error',
      error: error,
      stackTrace: stack);
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
                style: TextStyle(color: AppColors.danger, fontSize: 16)),
            ]))));
  };
  if (!kIsWeb) {
    try {
      await initVodozemac();
    } catch (e) {
      AppLogger.instance.warning('Vodozemac init failed', error: e);
    }
  }
  await getIt<AnalyticsService>().init();
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
        });
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
    () => getIt<SecureStorageService>().init(),
    'SecureStorage',
    critical: true);
  if (_criticalInitFailed) return;

  await _safeInit(
    () => getIt<DatabaseService>().init(),
    'Database',
    critical: true);
  if (_criticalInitFailed) return;

  await Future.wait([
    _safeInit(
      () => getIt<DatabaseService>().migrateFromSharedPreferences(),
      'DBMigration'),
    _safeInit(() async {
      final packageInfo = await PackageInfo.fromPlatform();
      final storage = getIt<SecureStorageService>();
      String? deviceId = await storage.read('omnivium_device_id');
      if (deviceId == null) {
        deviceId =
            'dev_${DateTime.now().millisecondsSinceEpoch}_${packageInfo.buildNumber}';
        await storage.write('omnivium_device_id', deviceId);
      }
      getIt<ApiProxyService>().setDeviceInfo(
        deviceId: deviceId,
        appVersion: '${packageInfo.version}+${packageInfo.buildNumber}');
    }, 'DeviceInfo'),
    _safeInit(() => setupDependencies(), 'Dependencies'),
  ]);

  await _safeInit(
    () => OmniviumSDK.init(persistence: DatabasePersistenceBackend()),
    'RuntimeSDK');
  getIt<AppDataGateway>().init();
}

void _initDeferred() {
  Future.wait([
    _safeInit(() => getIt<VoiceService>().init(), 'Voice'),
    _safeInit(() => ReminderService.instance.init(), 'Reminder'),
    _safeInit(
      () => getIt<ApiProxyService>().loadUserConfiguredUrl(),
      'ApiProxyUserUrl'),
    _safeInit(() => getIt<ApiProxyService>().init(), 'ApiProxy'),
    _safeInit(
      () => NetworkSecurityService.instance.initWithDynamicPins(),
      'NetworkSecurity'),
    _safeInit(() => getIt<EncryptionService>().init(), 'Encryption'),
    _safeInit(() => getIt<LiteMode>().init(), 'LiteMode'),
    _safeInit(() => FileLog.instance.init(), 'FileLog'),
    _safeInit(() => DatabaseMigration.instance.run(), 'DBMigration'),
    _safeInit(() => getIt<AppLockService>().init(), 'AppLock'),
    _safeInit(() => BiometricService.instance.init(), 'Biometric'),
    _safeInit(() => SecureFlagService.instance.init(), 'SecureFlag'),
    _safeInit(
      () => EncryptedFileStorage.instance.init(),
      'EncryptedFileStorage'),
    _safeInit(() => getIt<PasswordKeyService>().init(), 'PasswordKey'),
    _safeInit(() => ConnectivityService.instance.init(), 'Connectivity'),
    _safeInit(
      () => getIt<PushNotificationService>().init(),
      'PushNotification'),
    _safeInit(() => getIt<EmbeddingService>().init(), 'Embedding'),
    _safeInit(() => getIt<EntityStore>().init(), 'EntityStore'),
    _safeInit(() => getIt<GoalStore>().init(), 'GoalStore'),
    _safeInit(() => getIt<CognitiveEngine>().init(getIt()), 'CognitiveEngine'),
    _safeInit(() => getIt<RemoteConfigService>().init(), 'RemoteConfig'),
    _safeInit(() => getIt<AuthService>().initFromBackend(), 'Auth'),
    _safeInit(() => getIt<SupabaseSyncService>().init(), 'SupabaseSync'),
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
    if (!mounted) return;
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
          textAlign: TextAlign.center),
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
                errorText: _error)),
          ]),
        actions: [
          FilledButton(
            onPressed: _submit,
            child: Text(localeProvider.t('unlock'))),
        ]));
  }
}

class OmniviumApp extends StatelessWidget {
  const OmniviumApp({super.key});

  static final _router = createAppRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    shellChild: const _AppShell(),
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      bloc: themeCubit,
      builder: (context, themeState) {
        return BlocBuilder<LocaleCubit, LocaleState>(
          bloc: localeProvider,
          builder: (context, localeState) {
            return MaterialApp.router(
              title: 'Omnivium',
              routerConfig: _router,
              debugShowCheckedModeBanner: false,
              theme: themeState.lightTheme,
              darkTheme: themeState.darkTheme,
              themeMode: themeState.mode,
          locale: localeState.locale,
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
          ]);
      });
      });
  }
}

final themeCubit = ThemeCubit();

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell>
    with TickerProviderStateMixin, WidgetsBindingObserver {

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
      final status = await getIt<ApiProxyService>().checkAppStatus();
      final forceUpdate = status['force_update'] as bool? ?? false;
      final suggestUpdate = status['suggest_update'] as bool? ?? false;
      final minVersion = status['min_version'] as String?;
      final latestVersion = status['latest_version'] as String?;
      if ((forceUpdate || suggestUpdate) && latestVersion != null && mounted) {
        showDialog<void>(
          context: context,
          barrierDismissible: !forceUpdate,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.sf(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
            title: Text(
              localeProvider.t('update_available'),
              style: TextStyle(color: AppColors.textPrimary(context))),
            content: Text(
              '${localeProvider.t('new_version')}: $latestVersion${minVersion != null ? '\n${localeProvider.t('min_version_required')}: $minVersion' : ''}',
              style: TextStyle(color: AppColors.textSecondary(context))),
            actions: [
              if (!forceUpdate)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    localeProvider.t('later'),
                    style: TextStyle(color: AppColors.sec(context)))),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  localeProvider.t('update_now'),
                  style: TextStyle(color: AppColors.acc(context)))),
            ]));
      }
    } catch (e) {
      AppLogger.instance.warning('Auth event handling failed', error: e);
    }
  }

  @override
  void dispose() {
    _authEventSub?.cancel();
    getIt<SessionCubit>().saveCurrentSession();
    disposeAll();
    ConnectivityService.instance.dispose();
    DeepLinkService.instance.dispose();
    getIt<PushNotificationService>().dispose();
    getIt<VoiceService>().dispose();
    disposeFirebaseMessaging();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAppLock();
      if (!getIt<MatrixCubit>().isLoggedIn) {
        getIt<MatrixCubit>().tryRestoreSession().then((restored) {
          if (restored && mounted) {
            setState(() {
              _showLogin = false;
            });
          }
        });
      }
      getIt<SupabaseSyncService>().init();
    } else if (state == AppLifecycleState.paused) {
      getIt<VoiceService>().stopListening();
    }
  }

  void _checkAppLock() {
    final lock = getIt<AppLockService>();
    if (!lock.isEnabled || !lock.isLocked) return;
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _AppLockDialog(lock: lock, onUnlocked: () => Navigator.pop(context)));
  }

  Future<void> _init() async {
    final results = await Future.wait([
      Future(() async {
        try {
          await SecurityCheckService.instance.check();
        } catch (e) {
          AppLogger.instance.warning('SecurityCheck init failed', error: e);
        }
      }),
      Future(() async {
        try {
          NetworkSecurityService.instance.enablePinning();
        } catch (e) {
          AppLogger.instance.warning(
            'NetworkSecurity enablePinning failed',
            error: e);
        }
      }),
      getIt<MatrixCubit>().tryRestoreSession().catchError((Object e) {
        AppLogger.instance.warning('Matrix session restore failed', error: e);
        return false;
      }),
      Future(() async {
        try {
          await getIt<ApiProxyService>().init();
        } catch (e) {
          AppLogger.instance.warning('ApiProxy init failed', error: e);
        }
      }),
      Future(() async {
        try {
          await initSubProviders();
        } catch (e) {
          AppLogger.instance.warning('Provider init failed', error: e);
        }
      }),
      _privacyService.hasConsented().catchError((Object e) {
        AppLogger.instance.warning('PrivacyConsent check failed', error: e);
        return true;
      }),
      Future(() async {
        try {
          await DeepLinkService.instance.init();
          DeepLinkService.instance.onDeepLink = (uri) {
            final sessionId = DeepLinkService.instance.parseSessionId(uri);
            if (sessionId != null) {
              getIt<SessionCubit>().switchSession(sessionId);
            }
          };
          final initialLink = DeepLinkService.instance.initialLink;
          if (initialLink != null) {
            DeepLinkService.instance.onDeepLink?.call(initialLink);
          }
        } catch (e) {
          AppLogger.instance.warning('DeepLink init failed', error: e);
        }
      }),
    ]);

    final restored = results[2] as bool;
    final hasConsented = results[5] as bool;

    if (restored) {
      FriendChatPanel.flushOutbox();
      try {
        await getIt<ModelCubit>().loadModels();
      } catch (e) {
        AppLogger.instance.warning('ModelCubit loadModels failed', error: e);
      }
    }

    if (mounted) {
      getIt<SessionCubit>().startAutoSave();
      _authEventSub = ChatService.onAuthEvent.listen((event) {
        if (event == AuthEvent.tokenExpired && mounted) {
          if (!getIt<MatrixCubit>().isLoggedIn) {
            setState(() {
              _showLogin = true;
            });
          }
        }
      });
      setState(() {
          _initialized = true;
          _showPrivacyConsent = !hasConsented;
        _showLogin = !restored && !getIt<MatrixCubit>().isLoggedIn;
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
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.sf(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.security, color: AppColors.warn(context), size: 24),
              const SizedBox(width: 8),
              Text(
                localeProvider.t('security_warning'),
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 17)),
            ]),
          content: Text(
            localeProvider.t('security_warning_desc'),
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                localeProvider.t('understand'),
                style: TextStyle(color: AppColors.acc(context)))),
          ]));
    });
  }

  void _onLoginSuccess() async {
    getIt<AuthService>().onMatrixLogin();
    setState(() => _showLogin = false);
    try {
      await getIt<ModelCubit>().loadModels();
    } catch (e) {
      AppLogger.instance.warning('loadModels after login failed', error: e);
    }
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
      final isDark =
          MediaQuery.of(context).platformBrightness == Brightness.dark;
      final bgColor = isDark
          ? const Color(0xFF1C1C1E)
          : const Color(0xFFF5F5F7);
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: bgColor,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: bgColor,
          systemNavigationBarIconBrightness: isDark
              ? Brightness.light
              : Brightness.dark),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(scaffoldBackgroundColor: bgColor),
          home: Scaffold(
            backgroundColor: bgColor,
            body: Center(
              child: Image.asset(
                isDark
                    ? 'assets/icon/app_icon.png'
                    : 'assets/icon/app_icon_light_splash.png',
                width: 120,
                height: 120)))));
    }

    if (_showPrivacyConsent) {
      return MaterialApp(
        theme: themeCubit.state.darkTheme,
        home: _PrivacyConsentScreen(onResult: _onPrivacyConsentResult));
    }

    return BlocBuilder<ThemeCubit, ThemeState>(
      bloc: themeCubit,
      builder: (context, themeState) {
        return BlocBuilder<LocaleCubit, LocaleState>(
          bloc: localeProvider,
          builder: (context, localeState) {
            return BlocBuilder<NavigationCubit, NavigationState>(
              bloc: getIt<NavigationCubit>(),
              builder: (context, navState) {
                return BlocBuilder<MatrixCubit, MatrixState>(
                  bloc: getIt<MatrixCubit>(),
                  builder: (context, matrixState) {
            final isLoggedIn = getIt<MatrixCubit>().isLoggedIn;
            if (!isLoggedIn && !_showLogin) {
              _showLogin = true;
            }

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: themeState.overlayStyle,
          child: PopScope(
            canPop:
                !getIt<NavigationCubit>().isSettingsOpen &&
                getIt<NavigationCubit>().currentView == ViewState.home,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              if (getIt<NavigationCubit>().isSettingsOpen) {
                getIt<NavigationCubit>().closeSettingsAndReturnToDrawer();
              } else if (getIt<NavigationCubit>().currentView != ViewState.home) {
                getIt<NavigationCubit>().goBack();
              }
            },
            child: AppErrorBoundary(
              child: Stack(
                children: [
                  HomeView(),
                  if (_showLogin && !isLoggedIn)
                    UnifiedLoginPage(
                      onLoginSuccess: _onLoginSuccess),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero).animate(animation),
                        child: child);
                    },
                    child: _buildCurrentOverlay()),
                ]))));
              });
            });
          });
        });
  }

  Widget? _buildCurrentOverlay() {
    if (getIt<NavigationCubit>().isSettingsOpen) {
      return SettingsPage(
        key: const ValueKey('settings'),
        onClose: () => getIt<NavigationCubit>().closeSettingsAndReturnToDrawer());
    }
    switch (getIt<NavigationCubit>().currentView) {
      case ViewState.discover:
        return DiscoverView(
          key: const ValueKey('discover'));
      case ViewState.search:
        return SearchView(key: const ValueKey('search'));
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
        child: CircularProgressIndicator(color: AppColors.acc(context))));
  }
}
