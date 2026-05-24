import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/app_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestAppWrapper extends StatelessWidget {
  final Widget child;
  final AppProvider? provider;

  const TestAppWrapper({super.key, required this.child, this.provider});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: child);
  }

  static Future<AppProvider> createProvider() async {
    SharedPreferences.setMockInitialValues({});
    return AppProvider();
  }
}

Future<void> pumpView(WidgetTester tester, Widget view) async {
  await tester.pumpWidget(MaterialApp(home: view));
  await tester.pumpAndSettle();
}
