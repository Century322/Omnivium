import 'package:flutter/material.dart';
import 'package:omnivium/core/app_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/views/notification_view.dart';

void main() {
  group('NotificationView', () {
    testWidgets('renders notification list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: NotificationView(provider: AppProvider())),
      );
      expect(find.byType(NotificationView), findsOneWidget);
    });
  });
}
