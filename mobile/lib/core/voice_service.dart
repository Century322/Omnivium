import 'app_logger.dart';
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'permission_service.dart';

enum STTEngine { system, whisper, google }
enum TTSVoice { alloy, echo, fable, onyx, nova, shimmer }
enum VoiceMode { handsFree, pushToTalk, off }

class VoiceService {
  static final VoiceService _instance = VoiceService._();
  static VoiceService get instance => _instance;
  VoiceService._();

  final stt.SpeechToText _stt = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _sttInitialized = false;
  bool _ttsInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isSTTAvailable => _sttInitialized;

  STTEngine _sttEngine = STTEngine.system;
  TTSVoice _ttsVoice = TTSVoice.alloy;
  VoiceMode _voiceMode = VoiceMode.handsFree;

  STTEngine get sttEngine => _sttEngine;
  TTSVoice get ttsVoice => _ttsVoice;
  VoiceMode get voiceMode => _voiceMode;

  final _onSpeechResult = StreamController<String>.broadcast();
  Stream<String> get onSpeechResult => _onSpeechResult.stream;

  final _onFinalResult = StreamController<String>.broadcast();
  Stream<String> get onFinalResult => _onFinalResult.stream;

  final _onListeningStateChanged = StreamController<bool>.broadcast();
  Stream<bool> get onListeningStateChanged => _onListeningStateChanged.stream;

  final _onSpeakingStateChanged = StreamController<bool>.broadcast();
  Stream<bool> get onSpeakingStateChanged => _onSpeakingStateChanged.stream;

  Future<void> init() async {
    await _initSTT();
    await _initTTS();
    await _loadPreferences();
  }

  Future<void> _initSTT() async {
    try {
      _sttInitialized = await _stt.initialize(
        onError: (error) => AppLogger.instance.info('STT Error: $error'),
        onStatus: (status) {
          if (status == stt.SpeechToText.notListeningStatus) {
            _isListening = false;
            _onListeningStateChanged.add(false);
          }
        },
        debugLogging: false,
      );
    } catch (e) {
      AppLogger.instance.info('STT init failed: $e');
      _sttInitialized = false;
    }
  }

  Future<void> _initTTS() async {
    try {
      await _tts.setLanguage('zh-CN');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _tts.setStartHandler(() {
        _isSpeaking = true;
        _onSpeakingStateChanged.add(true);
      });
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        _onSpeakingStateChanged.add(false);
      });
      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        _onSpeakingStateChanged.add(false);
      });
      _ttsInitialized = true;
    } catch (e) {
      AppLogger.instance.info('TTS init failed: $e');
      _ttsInitialized = false;
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final sttName = prefs.getString('omnivium_stt_engine') ?? STTEngine.system.name;
    final ttsName = prefs.getString('omnivium_tts_voice') ?? TTSVoice.alloy.name;
    final modeName = prefs.getString('omnivium_voice_mode') ?? VoiceMode.handsFree.name;
    _sttEngine = STTEngine.values.where((e) => e.name == sttName).firstOrNull ?? STTEngine.system;
    _ttsVoice = TTSVoice.values.where((e) => e.name == ttsName).firstOrNull ?? TTSVoice.alloy;
    _voiceMode = VoiceMode.values.where((e) => e.name == modeName).firstOrNull ?? VoiceMode.handsFree;
  }

  Future<void> setSTTEngine(STTEngine engine) async {
    _sttEngine = engine;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('omnivium_stt_engine', engine.name);
  }

  void setSttEngine(String name) {
    _sttEngine = STTEngine.values.where((e) => e.name == name).firstOrNull ?? STTEngine.system;
  }

  Future<void> setTTSVoice(TTSVoice voice) async {
    _ttsVoice = voice;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('omnivium_tts_voice', voice.name);
  }

  Future<void> setVoiceMode(VoiceMode mode) async {
    _voiceMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('omnivium_voice_mode', mode.name);
  }

  void setVoiceModeByName(String name) {
    _voiceMode = VoiceMode.values.where((e) => e.name == name).firstOrNull ?? VoiceMode.handsFree;
  }

  Future<bool> startListening() async {
    if (!_sttInitialized || _isListening) return false;
    if (_voiceMode == VoiceMode.off) return false;

    final granted = await PermissionService.instance.requestMicrophone();
    if (!granted) return false;

    try {
      _isListening = true;
      _onListeningStateChanged.add(true);
      await _stt.listen(
        onResult: (result) {
          _onSpeechResult.add(result.recognizedWords);
          if (result.finalResult) {
            _isListening = false;
            _onListeningStateChanged.add(false);
            _onFinalResult.add(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        listenOptions: stt.SpeechListenOptions(partialResults: true),
        localeId: 'zh_CN',
      );
      return true;
    } catch (e) {
      AppLogger.instance.info('Start listening failed: $e');
      _isListening = false;
      _onListeningStateChanged.add(false);
      return false;
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    try {
      await _stt.stop();
    } catch (e) {
      AppLogger.instance.info('Stop listening failed: $e');
    }
    _isListening = false;
    _onListeningStateChanged.add(false);
  }

  Future<void> speak(String text) async {
    if (!_ttsInitialized || text.isEmpty) return;
    await stopSpeaking();
    try {
      await _tts.speak(text);
    } catch (e) {
      AppLogger.instance.info('TTS speak failed: $e');
    }
  }

  Future<void> stopSpeaking() async {
    if (!_isSpeaking) return;
    try {
      await _tts.stop();
    } catch (e) {
      AppLogger.instance.info('TTS stop failed: $e');
    }
    _isSpeaking = false;
    _onSpeakingStateChanged.add(false);
  }

  void dispose() {
    _onSpeechResult.close();
    _onFinalResult.close();
    _onListeningStateChanged.close();
    _onSpeakingStateChanged.close();
  }
}
