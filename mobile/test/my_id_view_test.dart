import 'package:flutter/material.dart';
import 'package:omnivium/core/app_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/views/my_id_view.dart';

void main() {
  group('MyIdView', () {
    testWidgets('renders my id view', (tester) async {
      await tester.pumpWidget(MaterialApp(home: MyIdView(provider: AppProvider())));
      expect(find.byType(MyIdView), findsOneWidget);
    });
  });
}
