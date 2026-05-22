import 'dart:io';
import 'package:flutter/foundation.dart';
import 'app_logger.dart';

class LiteMode {
  static final LiteMode _instance = LiteMode._();
  static LiteMode get instance => _instance;
  LiteMode._();

  static const int flagAnimatedStickers = 1 << 0;
  static const int flagAutoplayVideos = 1 << 1;
  static const int flagSmoothAnimations = 1 << 2;
  static const int flagBlurEffects = 1 << 3;
  static const int flagChatBlurs = 1 << 4;
  static const int flagAnimatedEmoji = 1 << 5;
  static const int flagStreamingPlayback = 1 << 6;
  static const int flagPreloadMedia = 1 << 7;
  static const int flagHqVoice = 1 << 8;
  static const int flagShadowEffects = 1 << 9;

  static const int presetLow = 0;
  static const int presetMedium = 1;
  static const int presetHigh = 2;

  static const List<int> _presetFlags = [
    flagSmoothAnimations | flagStreamingPlayback,
    flagSmoothAnimations | flagStreamingPlayback | flagAnimatedStickers | flagAutoplayVideos | flagAnimatedEmoji | flagPreloadMedia,
    flagAnimatedStickers | flagAutoplayVideos | flagSmoothAnimations | flagBlurEffects | flagChatBlurs | flagAnimatedEmoji | flagStreamingPlayback | flagPreloadMedia | flagHqVoice | flagShadowEffects,
  ];

  int _flags = _presetFlags[presetHigh];
  int _preset = presetHigh;

  int get flags => _flags;
  int get preset => _preset;
  bool get isLow => _preset == presetLow;
  bool get isMedium => _preset == presetMedium;
  bool get isHigh => _preset == presetHigh;

  bool isEnabled(int flag) => (_flags & flag) != 0;
  bool get animatedStickersEnabled => isEnabled(flagAnimatedStickers);
  bool get autoplayVideosEnabled => isEnabled(flagAutoplayVideos);
  bool get smoothAnimationsEnabled => isEnabled(flagSmoothAnimations);
  bool get blurEffectsEnabled => isEnabled(flagBlurEffects);
  bool get chatBlursEnabled => isEnabled(flagChatBlurs);
  bool get animatedEmojiEnabled => isEnabled(flagAnimatedEmoji);
  bool get streamingPlaybackEnabled => isEnabled(flagStreamingPlayback);
  bool get preloadMediaEnabled => isEnabled(flagPreloadMedia);
  bool get hqVoiceEnabled => isEnabled(flagHqVoice);
  bool get shadowEffectsEnabled => isEnabled(flagShadowEffects);

  Future<void> init() async {
    int performanceScore = 100;

    if (kDebugMode) performanceScore -= 10;
    if (kIsWeb) performanceScore -= 20;

    final processors = Platform.numberOfProcessors;
    if (processors <= 2) {
      performanceScore -= 30;
    } else if (processors <= 4) performanceScore -= 10;

    if (performanceScore < 50) {
      _preset = presetLow;
    } else if (performanceScore < 75) {
      _preset = presetMedium;
    } else {
      _preset = presetHigh;
    }
    _flags = _presetFlags[_preset];

    AppLogger.instance.info('LiteMode: preset=$_preset, score=$performanceScore, cores=$processors');
  }

  void setFlag(int flag, bool enabled) {
    if (enabled) {
      _flags |= flag;
    } else {
      _flags &= ~flag;
    }
  }

  void setPreset(int preset) {
    if (preset < 0 || preset > 2) return;
    _preset = preset;
    _flags = _presetFlags[preset];
  }
}
