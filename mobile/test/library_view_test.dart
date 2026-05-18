import 'package:flutter/material.dart';
import 'package:omnivium/core/app_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/views/library_view.dart';

void main() {
  group('LibraryView', () {
    testWidgets('renders library content', (tester) async {
      await tester.pumpWidget(MaterialApp(home: LibraryView(provider: AppProvider())));
      expect(find.byType(LibraryView), findsOneWidget);
    });
  });
}
