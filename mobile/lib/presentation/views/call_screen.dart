
import '../../core/di/app_di.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../core/app_logger.dart';
import '../../core/call_service.dart';
import '../theme/app_colors.dart';
import '../theme/locale_cubit.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Duration _callDuration = Duration.zero;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isCameraOff = false;
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;
  bool _renderersInitialized = false;
  StreamSubscription? _callStateSubscription;
  Timer? _callTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _callStateSubscription = getIt<CallService>().callStateStream.listen((
      call) {
      if (!mounted) return;
      setState(() {});
      if (call.state == CallState.connected) {
        _startTimer();
        _pulseController.stop();
        if (call.isVideo) _initRenderers();
      } else if (call.state == CallState.ended) {
        _callTimer?.cancel();
        _disposeRenderers();
        if (context.mounted) Navigator.of(context).pop();
      }
    });
  }

  void _startTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && getIt<CallService>().isInCall) {
        setState(() => _callDuration += const Duration(seconds: 1));
      } else {
        _callTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _callStateSubscription?.cancel();
    _disposeRenderers();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initRenderers() async {
    if (_renderersInitialized) return;
    final call = getIt<CallService>().currentCall;
    if (call == null) return;

    _localRenderer = RTCVideoRenderer();
    _remoteRenderer = RTCVideoRenderer();
    await _localRenderer!.initialize();
    if (!mounted) return;
    await _remoteRenderer!.initialize();
    if (!mounted) return;

    if (call.localStream != null) {
      _localRenderer?.srcObject = call.localStream;
    }
    if (call.remoteStream != null) {
      _remoteRenderer?.srcObject = call.remoteStream;
    }
    _renderersInitialized = true;
    if (mounted) setState(() {});
  }

  void _disposeRenderers() {
    _localRenderer?.srcObject = null;
    _remoteRenderer?.srcObject = null;
    _localRenderer?.dispose();
    _remoteRenderer?.dispose();
    _localRenderer = null;
    _remoteRenderer = null;
    _renderersInitialized = false;
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String _getStateText(CallState state) {
    switch (state) {
      case CallState.idle:
        return '';
      case CallState.inviting:
        return localeProvider.t('calling');
      case CallState.ringing:
        return localeProvider.t('ringing');
      case CallState.connecting:
        return localeProvider.t('connecting');
      case CallState.connected:
        return _formatDuration(_callDuration);
      case CallState.ended:
        return localeProvider.t('call_ended');
    }
  }

  @override
  Widget build(BuildContext context) {
    final call = getIt<CallService>().currentCall;
    if (call == null) return const SizedBox.shrink();

    final isRinging = call.state == CallState.ringing;
    final isConnected = call.state == CallState.connected;
    final isConnecting =
        call.state == CallState.connecting || call.state == CallState.inviting;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) getIt<CallService>().hangup();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg(context),
        body: SafeArea(
          child: call.isVideo && _renderersInitialized && isConnected
              ? _buildVideoLayout(context, call)
              : Column(
                  children: [
                    const Spacer(flex: 2),
                    _buildAvatar(isConnected),
                    const SizedBox(height: 24),
                    Text(
                      call.remoteUserId.replaceAll('@', '').split(':').first,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context))),
                    const SizedBox(height: 8),
                    Text(
                      _getStateText(call.state),
                      style: TextStyle(
                        fontSize: 16,
                        color: isConnected
                            ? AppColors.ok(context)
                            : AppColors.textSecondary(context))),
                    const Spacer(flex: 3),
                    if (isConnected) _buildInCallControls(context),
                    if (isRinging) _buildIncomingCallControls(),
                    if (isConnecting) _buildConnectingControls(),
                    SizedBox(
                      height: max(
                        48,
                        MediaQuery.of(context).padding.bottom + 16)),
                  ]))));
  }

  Widget _buildAvatar(bool isConnected) {
    return _PulseAvatar(animation: _pulseAnimation, isConnected: isConnected);
  }

  Widget _buildInCallControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: _isMuted ? Icons.mic_off : Icons.mic,
          label: _isMuted
              ? localeProvider.t('unmute')
              : localeProvider.t('mute'),
          color: _isMuted
              ? AppColors.dng(context)
              : AppColors.textSecondary(context),
          onTap: () {
            setState(() => _isMuted = !_isMuted);
            _toggleMute(_isMuted);
          }),
        _buildControlButton(
          icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
          label: _isSpeakerOn
              ? localeProvider.t('speaker')
              : localeProvider.t('earpiece'),
          color: _isSpeakerOn
              ? AppColors.acc(context)
              : AppColors.textSecondary(context),
          onTap: () {
            setState(() => _isSpeakerOn = !_isSpeakerOn);
            _toggleSpeaker(_isSpeakerOn);
          }),
        _buildControlButton(
          icon: Icons.call_end,
          label: localeProvider.t('hang_up'),
          color: AppColors.dng(context),
          onTap: () => getIt<CallService>().hangup(),
          isLarge: true),
      ]);
  }

  void _toggleMute(bool muted) {
    final call = getIt<CallService>().currentCall;
    if (call == null) return;
    final localStream = call.localStream;
    if (localStream == null) return;
    for (final track in localStream.getAudioTracks()) {
      track.enabled = !muted;
    }
  }

  void _toggleSpeaker(bool speakerOn) {
    final call = getIt<CallService>().currentCall;
    if (call == null) return;
    final localStream = call.localStream;
    if (localStream == null) return;
    for (final track in localStream.getAudioTracks()) {
      try {
        track.enableSpeakerphone(speakerOn);
      } catch (e) {
        AppLogger.instance.debug('Speakerphone toggle failed', error: e);
      }
    }
  }

  void _toggleCamera() {
    final call = getIt<CallService>().currentCall;
    if (call == null) return;
    final localStream = call.localStream;
    if (localStream == null) return;
    for (final track in localStream.getVideoTracks()) {
      track.enabled = !_isCameraOff;
    }
    if (mounted) setState(() {});
  }

  void _switchCamera() {
    final call = getIt<CallService>().currentCall;
    if (call == null) return;
    final localStream = call.localStream;
    if (localStream == null) return;
    for (final track in localStream.getVideoTracks()) {
      try {
        Helper.switchCamera(track);
      } catch (e) {
        AppLogger.instance.debug('Camera switch failed', error: e);
      }
    }
  }

  Widget _buildVideoLayout(BuildContext context, VoIPCall call) {
    return Stack(
      children: [
        if (_remoteRenderer != null && call.remoteStream != null)
          Positioned.fill(
            child: RTCVideoView(
              _remoteRenderer!,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)),
        if (_localRenderer != null && call.localStream != null && !_isCameraOff)
          Positioned(
            top: 60,
            right: 16,
            child: Container(
              width: 120,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.acc(context), width: 2)),
              clipBehavior: Clip.antiAlias,
              child: RTCVideoView(
                _localRenderer!,
                mirror: true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover))),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.bg(context).withValues(alpha: 0.7),
                ])),
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
            child: Column(
              children: [
                Text(
                  call.remoteUserId.replaceAll('@', '').split(':').first,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOnAccent(context))),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(_callDuration),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textOnAccent(
                      context).withValues(alpha: 0.8))),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      label: _isMuted
                          ? localeProvider.t('unmute')
                          : localeProvider.t('mute'),
                      color: _isMuted
                          ? AppColors.dng(context)
                          : AppColors.textOnAccent(context),
                      onTap: () {
                        setState(() => _isMuted = !_isMuted);
                        _toggleMute(_isMuted);
                      }),
                    _buildControlButton(
                      icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                      label: _isCameraOff
                          ? localeProvider.t('open_camera')
                          : localeProvider.t('close_camera'),
                      color: _isCameraOff
                          ? AppColors.dng(context)
                          : AppColors.textOnAccent(context),
                      onTap: () {
                        setState(() => _isCameraOff = !_isCameraOff);
                        _toggleCamera();
                      }),
                    _buildControlButton(
                      icon: Icons.flip_camera_ios,
                      label: localeProvider.t('flip_camera'),
                      color: AppColors.textOnAccent(context),
                      onTap: _switchCamera),
                    _buildControlButton(
                      icon: Icons.call_end,
                      label: localeProvider.t('hang_up'),
                      color: AppColors.dng(context),
                      onTap: () => getIt<CallService>().hangup(),
                      isLarge: true),
                  ]),
              ]))),
      ]);
  }

  Widget _buildIncomingCallControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: Icons.call_end,
          label: localeProvider.t('decline'),
          color: AppColors.dng(context),
          onTap: () => getIt<CallService>().rejectCall(),
          isLarge: true),
        _buildControlButton(
          icon: Icons.phone,
          label: localeProvider.t('answer'),
          color: AppColors.ok(context),
          onTap: () => getIt<CallService>().answerCall(),
          isLarge: true),
      ]);
  }

  Widget _buildConnectingControls() {
    return _buildControlButton(
      icon: Icons.call_end,
      label: localeProvider.t('cancel'),
      color: AppColors.dng(context),
      onTap: () => getIt<CallService>().hangup(),
      isLarge: true);
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isLarge = false,
  }) {
    final size = isLarge ? 72.0 : 56.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15)),
            child: Icon(icon, color: color, size: isLarge ? 32 : 24))),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ]);
  }
}

class _PulseAvatar extends StatelessWidget {
  final Animation<double> animation;
  final bool isConnected;

  const _PulseAvatar({required this.animation, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final scale = isConnected ? 1.0 : animation.value;
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.acc(context).withValues(alpha: 0.2),
          border: Border.all(
            color: isConnected ? AppColors.ok(context) : AppColors.acc(context),
            width: 3)),
        child: Icon(
          isConnected ? Icons.phone_in_talk : Icons.phone,
          size: 48,
          color: isConnected ? AppColors.ok(context) : AppColors.acc(context))));
  }
}
