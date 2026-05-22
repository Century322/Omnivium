import 'package:flutter/material.dart';
import 'package:omnivium/core/app_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/views/matrix_login_view.dart';

void main() {
  group('MatrixLoginView', () {
    testWidgets('renders login form', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: MatrixLoginView(provider: AppProvider())),
      );
      expect(find.byType(MatrixLoginView), findsOneWidget);
    });
  });
}
