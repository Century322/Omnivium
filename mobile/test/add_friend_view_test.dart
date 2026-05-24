import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/views/add_friend_view.dart';
import 'package:omnivium/core/app_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AddFriendView', () {
    testWidgets('renders add friend form', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AddFriendView(provider: AppProvider())),
      );
      await tester.pump();
      expect(find.byType(AddFriendView), findsOneWidget);
    });

    testWidgets('has two text input fields', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AddFriendView(provider: AppProvider())),
      );
      await tester.pump();
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('has add button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AddFriendView(provider: AppProvider())),
      );
      await tester.pump();
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('has search button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AddFriendView(provider: AppProvider())),
      );
      await tester.pump();
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('has scaffold with app bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AddFriendView(provider: AppProvider())),
      );
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('can enter text in ID field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AddFriendView(provider: AppProvider())),
      );
      await tester.pump();
      final idField = find.byType(TextField).first;
      await tester.enterText(idField, '@user:matrix.org');
      await tester.pump();
      expect(find.text('@user:matrix.org'), findsOneWidget);
    });

    testWidgets('can enter text in search field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AddFriendView(provider: AppProvider())),
      );
      await tester.pump();
      final searchField = find.byType(TextField).at(1);
      await tester.enterText(searchField, 'test');
      await tester.pump();
      expect(find.text('test'), findsOneWidget);
    });

    testWidgets('has icon buttons in app bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AddFriendView(provider: AppProvider())),
      );
      await tester.pump();
      expect(find.byType(IconButton), findsWidgets);
    });
  });
}
