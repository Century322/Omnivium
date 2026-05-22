import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/widgets/setting_item.dart';

void main() {
  group('SettingItem', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingItem(title: 'Test Setting', onTap: () {}),
          ),
        ),
      );
      expect(find.text('Test Setting'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingItem(title: 'Tap me', onTap: () => tapped = true),
          ),
        ),
      );
      await tester.tap(find.text('Tap me'));
      expect(tapped, isTrue);
    });

    testWidgets('renders with subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingItem(
              title: 'Title',
              subtitle: 'Subtitle',
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Subtitle'), findsOneWidget);
    });

    testWidgets('renders with rightContent', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingItem(
              title: 'With content',
              onTap: () {},
              rightContent: Text('Extra'),
            ),
          ),
        ),
      );
      expect(find.text('Extra'), findsOneWidget);
    });
  });
}
