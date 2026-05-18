import '../../core/app_logger.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';

class VoiceRecorderButton extends StatefulWidget {
  final void Function(String path, Duration duration) onSend;
  const VoiceRecorderButton({super.key, required this.onSend});

  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton> {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  Duration _duration = Duration.zero;
  Timer? _timer;
  String? _recordPath;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) return;
      final dir = await getTemporaryDirectory();
      _recordPath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: _recordPath!);
      setState(() {
        _isRecording = true;
        _duration = Duration.zero;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _duration += const Duration(seconds: 1));
      });
    } catch (e, stackTrace) { AppLogger.instance.error('Operation failed', error: e, stackTrace: stackTrace); }
  }

  Future<void> _stopRecording(bool send) async {
    _timer?.cancel();
    try {
      final path = await _recorder.stop();
      if (send && path != null) {
        widget.onSend(path, _duration);
      } else if (path != null) {
        File(path).deleteSync();
      }
    } catch (e, stackTrace) { AppLogger.instance.error('Operation failed', error: e, stackTrace: stackTrace); }
    if (mounted) {
      setState(() {
        _isRecording = false;
        _duration = Duration.zero;
        _recordPath = null;
      });
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_isRecording) {
      return Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(label: localeProvider.t('cancel_recording'), child: GestureDetector(
              onTap: () => _stopRecording(false),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.dng(context).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(LucideIcons.x, size: 16, color: AppColors.dng(context)),
              ),
            )),
            const SizedBox(width: 10),
            Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.dng(context), borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 8),
            Text(_formatDuration(_duration), style: TextStyle(color: AppColors.textPrimary(context), fontSize: 14, fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()])),
            const SizedBox(width: 10),
            Semantics(label: localeProvider.t('send_recording'), child: GestureDetector(
              onTap: () => _stopRecording(true),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(LucideIcons.send, size: 14, color: AppColors.textPrimary(context)),
              ),
            )),
          ],
        ),
      );
    }

    return Semantics(label: localeProvider.t('voice_message_record'), child: GestureDetector(
      onLongPress: _startRecording,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppColors.sfAlt(context),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(LucideIcons.mic, size: 18, color: AppColors.sec(context)),
      ),
    ));
  }
}

class VoiceMessagePlayer extends StatefulWidget {
  final String url;
  final bool isMe;
  const VoiceMessagePlayer({super.key, required this.url, required this.isMe});

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  final _player = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _subs.add(_player.onDurationChanged.listen((d) { if (mounted) setState(() => _duration = d); }));
    _subs.add(_player.onPositionChanged.listen((p) { if (mounted) setState(() => _position = p); }));
    _subs.add(_player.onPlayerStateChanged.listen((s) { if (mounted) setState(() { _isPlaying = s == PlayerState.playing; }); }));
    _subs.add(_player.onPlayerComplete.listen((_) { if (mounted) setState(() { _position = Duration.zero; _isPlaying = false; }); }));
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_position > Duration.zero && _position < _duration) {
        await _player.resume();
      } else {
        await _player.play(UrlSource(widget.url));
      }
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0 ? _position.inMilliseconds / _duration.inMilliseconds : 0.0;
    final bgColor = widget.isMe ? AppColors.accent.withValues(alpha: 0.15) : AppColors.sfAlt(context);
    final iconColor = widget.isMe ? AppColors.accent : AppColors.sec(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(label: _isPlaying ? 'Pause voice message' : 'Play voice message', child: GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _isPlaying ? LucideIcons.pause : LucideIcons.play,
                size: 16, color: AppColors.textPrimary(context),
              ),
            ),
          )),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.divider(context),
                  valueColor: AlwaysStoppedAnimation(iconColor),
                  borderRadius: BorderRadius.circular(2),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(_isPlaying || _position > Duration.zero ? _position : _duration),
                  style: TextStyle(color: AppColors.textTertiary(context), fontSize: 11, fontFeatures: [FontFeature.tabularFigures()]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
