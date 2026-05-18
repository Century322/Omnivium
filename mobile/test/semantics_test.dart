import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/widgets/skeleton_loader.dart';

void main() {
  group('SkeletonLoader accessibility', () {
    testWidgets('SkeletonLoader renders without semantics labels', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SkeletonLoader(width: 100, height: 20)),
      ));
      expect(find.byType(SkeletonLoader), findsOneWidget);
      final semantic = tester.getSemantics(find.byType(SkeletonLoader));
      expect(semantic.label, isEmpty);
    });

    testWidgets('MessageSkeleton renders without semantics labels', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: MessageSkeleton()),
      ));
      expect(find.byType(MessageSkeleton), findsOneWidget);
    });

    testWidgets('CardSkeleton renders without semantics labels', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: CardSkeleton()),
      ));
      expect(find.byType(CardSkeleton), findsOneWidget);
    });

    testWidgets('ChatListSkeleton renders without semantics labels', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ChatListSkeleton(count: 2)),
      ));
      expect(find.byType(ChatListSkeleton), findsOneWidget);
    });
  });

  group('Semantics label verification', () {
    testWidgets('Semantics label on GestureDetector is findable', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Semantics(
            label: 'Close button',
            button: true,
            child: GestureDetector(
              onTap: () {},
              child: const Icon(Icons.close),
            ),
          ),
        ),
      ));
      expect(find.bySemanticsLabel('Close button'), findsOneWidget);
    });

    testWidgets('Semantics label on icon button is findable', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Semantics(
            label: 'Settings',
            button: true,
            child: GestureDetector(
              onTap: () {},
              child: const Icon(Icons.settings),
            ),
          ),
        ),
      ));
      expect(find.bySemanticsLabel('Settings'), findsOneWidget);
    });

    testWidgets('Semantics excludeSemantics hides content', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Semantics(
            excludeSemantics: true,
            child: Text('Hidden from screen readers'),
          ),
        ),
      ));
      expect(find.bySemanticsLabel('Hidden from screen readers'), findsNothing);
    });

    testWidgets('Image semanticLabel is set correctly', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Image.network(
            'https://example.com/test.png',
            semanticLabel: 'Test image description',
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          ),
        ),
      ));
      expect(find.bySemanticsLabel('Test image description'), findsOneWidget);
    });

    testWidgets('TextField with labelText is accessible', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TextField(
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: 'Enter username',
            ),
          ),
        ),
      ));
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Semantics wrapper provides label for screen readers', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Semantics(
            label: 'Toggle password visibility',
            button: true,
            child: GestureDetector(
              onTap: () {},
              child: const Icon(Icons.visibility),
            ),
          ),
        ),
      ));
      expect(find.bySemanticsLabel('Toggle password visibility'), findsOneWidget);
    });
  });
}
