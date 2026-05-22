import 'runtime/sdk/omnivium_sdk.dart';
import 'runtime/plugin/plugin_handler.dart' show CapabilityResult, RuntimeError;
import 'app_logger.dart';

class AppCapabilityService {
  static final AppCapabilityService _instance = AppCapabilityService._();
  static AppCapabilityService get instance => _instance;
  AppCapabilityService._();

  OmniviumSDK? get _sdk {
    final sdk = OmniviumSDK.instance;
    return sdk.isInitialized ? sdk : null;
  }

  Future<CapabilityResult> invoke(
    String capabilityId, {
    Map<String, dynamic>? params,
    int timeoutMs = 10000,
  }) async {
    final sdk = _sdk;
    if (sdk == null) {
      return CapabilityResult.ok(_fallback(capabilityId, params));
    }

    try {
      final result = await sdk.invokeCapability(
        capabilityId,
        params: params,
        timeoutMs: timeoutMs,
      );
      return result;
    } catch (e) {
      AppLogger.instance.warning(
        'AppCapability: $capabilityId failed',
        error: e,
      );
      return CapabilityResult.fail(
        RuntimeError(code: 'CAPABILITY_ERROR', message: e.toString()),
      );
    }
  }

  Future<bool> checkPermission(String capabilityId) async {
    final sdk = _sdk;
    if (sdk == null) return true;

    await sdk.container.capabilityRouter.discover(capabilityId);
    return true;
  }

  Future<bool> isAllowed(String capabilityId) async {
    final sdk = _sdk;
    if (sdk == null) return true;

    await sdk.container.capabilityRouter.discover(capabilityId);
    return true;
  }

  Map<String, dynamic> _fallback(
    String capabilityId,
    Map<String, dynamic>? params,
  ) {
    AppLogger.instance.info(
      'AppCapability: fallback for $capabilityId (SDK not available)',
    );
    return {'capabilityId': capabilityId, 'fallback': true, ...?params};
  }
}
