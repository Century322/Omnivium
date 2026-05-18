import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/views/terms_of_service_view.dart';

void main() {
  group('TermsOfServiceView', () {
    testWidgets('renders terms content', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TermsOfServiceView()));
      expect(find.byType(TermsOfServiceView), findsOneWidget);
    });
  });
}
