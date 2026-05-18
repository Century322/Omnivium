import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/views/add_friend_view.dart';
import 'package:omnivium/core/app_provider.dart';

void main() {
  group('AddFriendView', () {
    testWidgets('renders add friend form', (tester) async {
      await tester.pumpWidget(MaterialApp(home: AddFriendView(provider: AppProvider())));
      expect(find.byType(AddFriendView), findsOneWidget);
    });
  });
}
