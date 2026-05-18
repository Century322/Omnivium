import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/views/about_view.dart';
import 'package:omnivium/core/app_provider.dart';

void main() {
  group('AboutView', () {
    testWidgets('renders app info', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: AboutView(provider: AppProvider()),
      ));
      expect(find.text('Omnivium'), findsWidgets);
    });
  });
}
