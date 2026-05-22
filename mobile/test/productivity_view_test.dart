import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/views/productivity_view.dart';
import 'package:omnivium/core/note_provider.dart';

void main() {
  group('ProductivityView', () {
    testWidgets('renders productivity view', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ProductivityView(provider: NoteProvider())),
      );
      expect(find.byType(ProductivityView), findsOneWidget);
    });
  });
}
