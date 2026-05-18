import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/widgets/skeleton_loader.dart';

void main() {
  group('SkeletonLoader', () {
    testWidgets('renders with default dimensions', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SkeletonLoader()),
      ));
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('renders with custom dimensions', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SkeletonLoader(width: 200, height: 30)),
      ));
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('renders with custom borderRadius', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SkeletonLoader(
          width: 100,
          height: 20,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        )),
      ));
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('animation controller repeats', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SkeletonLoader()),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });
  });

  group('MessageSkeleton', () {
    testWidgets('renders user message skeleton', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: MessageSkeleton(isUser: true)),
      ));
      expect(find.byType(MessageSkeleton), findsOneWidget);
      expect(find.byType(SkeletonLoader), findsNWidgets(3));
    });

    testWidgets('renders AI message skeleton with avatar', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: MessageSkeleton(isUser: false)),
      ));
      expect(find.byType(MessageSkeleton), findsOneWidget);
      expect(find.byType(SkeletonLoader), findsNWidgets(4));
    });
  });

  group('ChatListSkeleton', () {
    testWidgets('renders with default count', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ChatListSkeleton()),
      ));
      expect(find.byType(ChatListSkeleton), findsOneWidget);
      expect(find.byType(MessageSkeleton), findsNWidgets(5));
    });

    testWidgets('renders with custom count', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ChatListSkeleton(count: 3)),
      ));
      expect(find.byType(MessageSkeleton), findsNWidgets(3));
    });
  });

  group('CardSkeleton', () {
    testWidgets('renders card skeleton', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: CardSkeleton()),
      ));
      expect(find.byType(CardSkeleton), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(SkeletonLoader), findsNWidgets(4));
    });
  });
}
