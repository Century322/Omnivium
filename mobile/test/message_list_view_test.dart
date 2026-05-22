import 'package:flutter/material.dart';
import 'package:omnivium/core/app_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/views/message_list_view.dart';

void main() {
  group('MessageListView', () {
    testWidgets('renders message list view', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: MessageListView(provider: AppProvider())),
      );
      expect(find.byType(MessageListView), findsOneWidget);
    });
  });
}
