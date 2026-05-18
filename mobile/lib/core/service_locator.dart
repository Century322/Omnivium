import 'package:get_it/get_it.dart';
import 'app_logger.dart';
import 'secure_storage_service.dart';
import 'database_service.dart';
import 'connectivity_service.dart';
import 'offline_service.dart';
import 'network_security_service.dart';
import 'api_proxy_service.dart';
import 'auth_service.dart';
import 'supabase_sync_service.dart';
import 'remote_config_service.dart';
import 'push_notification_service.dart';
import 'deep_link_service.dart';
import 'voice_service.dart';
import 'agent/agent_memory_service.dart';
import 'agent/embedding_service.dart';
import 'ab_test_service.dart';
import 'crash_recovery_service.dart';
import 'performance_monitor_service.dart';

final locator = GetIt.instance;

Future<void> setupLocator() async {
  locator.registerLazySingleton<SecureStorageService>(() => SecureStorageService.instance);
  locator.registerLazySingleton<DatabaseService>(() => DatabaseService.instance);
  locator.registerLazySingleton<ConnectivityService>(() => ConnectivityService.instance);
  locator.registerLazySingleton<OfflineService>(() => OfflineService.instance);
  locator.registerLazySingleton<NetworkSecurityService>(() => NetworkSecurityService.instance);
  locator.registerLazySingleton<ApiProxyService>(() => ApiProxyService.instance);
  locator.registerLazySingleton<AuthService>(() => AuthService.instance);
  locator.registerLazySingleton<SupabaseSyncService>(() => SupabaseSyncService.instance);
  locator.registerLazySingleton<RemoteConfigService>(() => RemoteConfigService.instance);
  locator.registerLazySingleton<PushNotificationService>(() => PushNotificationService.instance);
  locator.registerLazySingleton<DeepLinkService>(() => DeepLinkService.instance);
  locator.registerLazySingleton<VoiceService>(() => VoiceService.instance);
  locator.registerLazySingleton<AgentMemoryService>(() => AgentMemoryService.instance);
  locator.registerLazySingleton<EmbeddingService>(() => EmbeddingService.instance);
  locator.registerLazySingleton<ABTestService>(() => ABTestService.instance);
  locator.registerLazySingleton<CrashRecoveryService>(() => CrashRecoveryService.instance);
  locator.registerLazySingleton<PerformanceMonitorService>(() => PerformanceMonitorService.instance);

  AppLogger.instance.info('Service locator initialized');
}

Future<void> resetLocator() async {
  await locator.reset();
  AppLogger.instance.info('Service locator reset');
}
