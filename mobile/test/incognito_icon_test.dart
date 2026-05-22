import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/widgets/incognito_icon.dart';

void main() {
  group('IncognitoIcon', () {
    testWidgets('renders with default size', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: IncognitoIcon()),
      ));
      expect(find.byType(IncognitoIcon), findsOneWidget);
    });

    testWidgets('renders with custom size', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: IncognitoIcon(size: 24, strokeWidth: 3)),
      ));
      expect(find.byType(IncognitoIcon), findsOneWidget);
    });

    testWidgets('has Semantics label', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: IncognitoIcon()),
      ));
      expect(find.bySemanticsLabel('隐身模式'), findsOneWidget);
    });
  });
}
