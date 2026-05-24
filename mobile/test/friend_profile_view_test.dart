import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/app_provider.dart';
import 'package:omnivium/presentation/views/friend_profile_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FriendProfileView', () {
    testWidgets('renders friend profile view', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FriendProfileView(
            provider: AppProvider(),
            roomId: '!test:matrix.org',
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(FriendProfileView), findsOneWidget);
    });

    testWidgets('has scaffold with app bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FriendProfileView(
            provider: AppProvider(),
            roomId: '!test:matrix.org',
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('has icon buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FriendProfileView(
            provider: AppProvider(),
            roomId: '!test:matrix.org',
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FriendProfileView(
            provider: AppProvider(),
            roomId: '!test:matrix.org',
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
