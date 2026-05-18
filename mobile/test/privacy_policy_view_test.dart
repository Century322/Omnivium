import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/views/privacy_policy_view.dart';

void main() {
  group('PrivacyPolicyView', () {
    testWidgets('renders privacy policy content', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyView()));
      expect(find.byType(PrivacyPolicyView), findsOneWidget);
    });
  });
}
