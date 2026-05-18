import 'package:flutter/material.dart';
import 'package:omnivium/core/app_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/views/contacts_view.dart';

void main() {
  group('ContactsView', () {
    testWidgets('renders contacts view', (tester) async {
      await tester.pumpWidget(MaterialApp(home: ContactsView(provider: AppProvider())));
      expect(find.byType(ContactsView), findsOneWidget);
    });
  });
}
