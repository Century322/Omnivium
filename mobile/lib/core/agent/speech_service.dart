import '../app_logger.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../api_proxy_service.dart';

class SpeechService {
  static final SpeechService _instance = SpeechService._();
  static SpeechService get instance => _instance;
  SpeechService._();

  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _playerCompleteSub;
  bool _isPlaying = false;
  String? _currentTtsFilePath;
  bool get isPlaying => _isPlaying;

  Future<String?> transcribeWithWhisper(String audioPath, {String language = 'zh'}) async {
    final proxy = ApiProxyService.instance;
    if (!proxy.isConfigured) return null;

    try {
      final uri = Uri.parse('${proxy.backendUrl}/ai/transcribe');
      final file = File(audioPath);
      if (!await file.exists()) return null;

      final stream = http.ByteStream(file.openRead());
      final fileLength = await file.length();

      final multipartRequest = http.MultipartRequest('POST', uri);
      multipartRequest.headers.addAll({
        ...proxy.buildAuthHeaders(),
        ...proxy.buildDeviceHeaders(),
      });
      multipartRequest.files.add(http.MultipartFile(
        'file',
        stream,
        fileLength,
        filename: 'audio.wav',
      ));
      multipartRequest.fields['language'] = language;

      final streamedResponse = await proxy.secureClient.send(multipartRequest);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['text'] as String?;
      }
    } catch (e, stackTrace) {
      AppLogger.instance.warning('Whisper transcription failed', error: e, stackTrace: stackTrace);
    }
    return null;
  }

  Future<bool> speakWithOpenAI(String text, {String voice = 'alloy', String model = 'tts-1'}) async {
    final proxy = ApiProxyService.instance;
    if (!proxy.isConfigured) return false;

    try {
      final uri = Uri.parse('${proxy.backendUrl}/ai/tts');
      final response = await proxy.secureClient.post(uri, headers: {
        ...proxy.buildAuthHeaders(),
        ...proxy.buildDeviceHeaders(),
        'Content-Type': 'application/json',
      }, body: jsonEncode({
        'text': text,
        'voice': voice,
        'model': model,
      }));

      if (response.statusCode == 200) {
        await _cleanupCurrentTtsFile();

        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        _currentTtsFilePath = filePath;
        await _audioPlayer.play(DeviceFileSource(filePath));
        _isPlaying = true;

        _playerCompleteSub?.cancel();
        _playerCompleteSub = _audioPlayer.onPlayerComplete.listen((_) {
          _isPlaying = false;
          _cleanupCurrentTtsFile();
        });

        return true;
      }
    } catch (e, stackTrace) {
      AppLogger.instance.warning('OpenAI TTS failed', error: e, stackTrace: stackTrace);
    }
    return false;
  }

  Future<void> stopSpeaking() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    await _cleanupCurrentTtsFile();
  }

  Future<void> _cleanupCurrentTtsFile() async {
    if (_currentTtsFilePath != null) {
      final file = File(_currentTtsFilePath!);
      _currentTtsFilePath = null;
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
  }

  void dispose() {
    _playerCompleteSub?.cancel();
    _cleanupCurrentTtsFile();
    _audioPlayer.dispose();
  }
}
