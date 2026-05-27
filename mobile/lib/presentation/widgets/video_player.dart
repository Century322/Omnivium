import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';

class VideoPlayerView extends StatefulWidget {
  final String url;
  final String? title;
  const VideoPlayerView({super.key, required this.url, this.title});

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  late final Player _player;
  late final VideoController _controller;
  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _player.open(Media(widget.url));
    _subs.add(
      _player.stream.playing.listen((playing) {
        if (mounted) setState(() => _isPlaying = playing);
      }),
    );
    _subs.add(
      _player.stream.buffering.listen((buffering) {
        if (mounted) setState(() => _isBuffering = buffering);
      }),
    );
    _subs.add(
      _player.stream.position.listen((pos) {
        if (mounted) setState(() => _position = pos);
      }),
    );
    _subs.add(
      _player.stream.duration.listen((dur) {
        if (mounted) setState(() => _duration = dur);
      }),
    );
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        foregroundColor: AppColors.textPrimary(context),
        title: widget.title case final videoTitle?
            ? Text(
                videoTitle,
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 16,
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Video(controller: _controller),
                    if (_isBuffering)
                      CircularProgressIndicator(color: AppColors.acc(context)),
                    if (!_isPlaying && !_isBuffering)
                      Semantics(
                        label: localeProvider.t('play_video'),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _player.play(),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.textTertiary(context),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Icon(
                              LucideIcons.play,
                              color: AppColors.textPrimary(context),
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: AppColors.bg(context),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                _formatDuration(_position),
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    activeTrackColor: AppColors.acc(context),
                    inactiveTrackColor: AppColors.textDisabled(context),
                    thumbColor: AppColors.acc(context),
                  ),
                  child: Slider(
                    value: _duration.inMilliseconds > 0
                        ? _position.inMilliseconds / _duration.inMilliseconds
                        : 0,
                    onChanged: (v) {
                      _player.seek(
                        Duration(
                          milliseconds: (v * _duration.inMilliseconds).round(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(_duration),
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: localeProvider.t('rewind'),
                icon: Icon(
                  LucideIcons.skipBack,
                  color: AppColors.textSecondary(context),
                  size: 20,
                ),
                onPressed: () {
                  final newPos = _position - const Duration(seconds: 10);
                  _player.seek(newPos.isNegative ? Duration.zero : newPos);
                },
              ),
              const SizedBox(width: 16),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.acc(context),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  tooltip: localeProvider.t('play'),
                  icon: Icon(
                    _isPlaying ? LucideIcons.pause : LucideIcons.play,
                    color: AppColors.bg(context),
                    size: 24,
                  ),
                  onPressed: () =>
                      _isPlaying ? _player.pause() : _player.play(),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                tooltip: localeProvider.t('forward'),
                icon: Icon(
                  LucideIcons.skipForward,
                  color: AppColors.textSecondary(context),
                  size: 20,
                ),
                onPressed: () {
                  final newPos = _position + const Duration(seconds: 10);
                  _player.seek(newPos > _duration ? _duration : newPos);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
