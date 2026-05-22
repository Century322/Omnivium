import 'package:flutter/material.dart';
import 'package:omnivium/core/app_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/views/search_view.dart';

void main() {
  group('SearchView', () {
    testWidgets('renders search view', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: SearchView(provider: AppProvider())),
      );
      expect(find.byType(SearchView), findsOneWidget);
    });
  });
}
