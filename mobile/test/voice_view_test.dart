import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/app_provider.dart';
import 'package:omnivium/presentation/views/voice_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('VoiceView', () {
    testWidgets('renders voice view widget', (tester) async {
      final provider = AppProvider();
      await tester.pumpWidget(MaterialApp(home: VoiceView(provider: provider)));
      await tester.pump();
      expect(find.byType(VoiceView), findsOneWidget);
    });

    testWidgets('contains scaffold', (tester) async {
      final provider = AppProvider();
      await tester.pumpWidget(MaterialApp(home: VoiceView(provider: provider)));
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
