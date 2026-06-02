import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:omnivium/core/secure_storage_service.dart';

bool _secureStorageInitialized = false;

Future<void> setupTestEnv() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
}

void mockSecureStorage() {
  final store = <String, String>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (MethodCall methodCall) async {
          final args = methodCall.arguments as Map<String, dynamic>;
          switch (methodCall.method) {
            case 'read':
              return store[args['key']];
            case 'write':
              store[args['key']] = args['value'] as String;
              return null;
            case 'delete':
              store.remove(args['key']);
              return null;
            case 'deleteAll':
              store.clear();
              return null;
            case 'containsKey':
              return store.containsKey(args['key']);
            case 'readAll':
              return store;
            default:
              return null;
          }
        },
      );
}

Future<bool> initSecureStorage() async {
  if (_secureStorageInitialized) return true;
  mockSecureStorage();
  try {
    await SecureStorageService.instance.init();
    _secureStorageInitialized = true;
    return true;
  } catch (_) {
    return false;
  }
}
