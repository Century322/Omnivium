import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/lite_mode.dart';

void main() {
  group('LiteMode', () {
    late LiteMode liteMode;

    setUp(() {
      liteMode = LiteMode.instance;
      liteMode.setPreset(LiteMode.presetHigh);
    });

    test('default preset is high', () {
      expect(liteMode.preset, LiteMode.presetHigh);
      expect(liteMode.isHigh, isTrue);
    });

    test('setPreset low', () {
      liteMode.setPreset(LiteMode.presetLow);
      expect(liteMode.isLow, isTrue);
      expect(liteMode.preset, LiteMode.presetLow);
    });

    test('setPreset medium', () {
      liteMode.setPreset(LiteMode.presetMedium);
      expect(liteMode.isMedium, isTrue);
    });

    test('setPreset invalid value ignored', () {
      liteMode.setPreset(-1);
      expect(liteMode.preset, LiteMode.presetHigh);
      liteMode.setPreset(3);
      expect(liteMode.preset, LiteMode.presetHigh);
    });

    test('high preset enables all flags', () {
      liteMode.setPreset(LiteMode.presetHigh);
      expect(liteMode.animatedStickersEnabled, isTrue);
      expect(liteMode.autoplayVideosEnabled, isTrue);
      expect(liteMode.smoothAnimationsEnabled, isTrue);
      expect(liteMode.blurEffectsEnabled, isTrue);
      expect(liteMode.chatBlursEnabled, isTrue);
      expect(liteMode.animatedEmojiEnabled, isTrue);
      expect(liteMode.streamingPlaybackEnabled, isTrue);
      expect(liteMode.preloadMediaEnabled, isTrue);
      expect(liteMode.hqVoiceEnabled, isTrue);
      expect(liteMode.shadowEffectsEnabled, isTrue);
    });

    test('low preset disables most flags', () {
      liteMode.setPreset(LiteMode.presetLow);
      expect(liteMode.animatedStickersEnabled, isFalse);
      expect(liteMode.autoplayVideosEnabled, isFalse);
      expect(liteMode.blurEffectsEnabled, isFalse);
      expect(liteMode.chatBlursEnabled, isFalse);
      expect(liteMode.animatedEmojiEnabled, isFalse);
      expect(liteMode.smoothAnimationsEnabled, isTrue);
      expect(liteMode.streamingPlaybackEnabled, isTrue);
    });

    test('setFlag toggles individual flag', () {
      liteMode.setPreset(LiteMode.presetHigh);
      expect(liteMode.animatedStickersEnabled, isTrue);
      liteMode.setFlag(LiteMode.flagAnimatedStickers, false);
      expect(liteMode.animatedStickersEnabled, isFalse);
      liteMode.setFlag(LiteMode.flagAnimatedStickers, true);
      expect(liteMode.animatedStickersEnabled, isTrue);
    });

    test('isEnabled checks flag correctly', () {
      liteMode.setPreset(LiteMode.presetHigh);
      expect(liteMode.isEnabled(LiteMode.flagAnimatedStickers), isTrue);
      expect(liteMode.isEnabled(1 << 20), isFalse);
    });

    test('medium preset has partial flags', () {
      liteMode.setPreset(LiteMode.presetMedium);
      expect(liteMode.animatedStickersEnabled, isTrue);
      expect(liteMode.autoplayVideosEnabled, isTrue);
      expect(liteMode.blurEffectsEnabled, isFalse);
      expect(liteMode.hqVoiceEnabled, isFalse);
    });
  });
}
