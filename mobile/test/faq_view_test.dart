import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/views/faq_view.dart';

void main() {
  group('FaqView', () {
    testWidgets('renders FAQ content', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: FaqView()));
      expect(find.byType(FaqView), findsOneWidget);
    });
  });
}
