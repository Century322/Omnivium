import 'package:flutter/material.dart';
import '../../core/call_service.dart';
import '../theme/app_colors.dart';

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

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    CallService.instance.callStateStream.listen((call) {
      if (!mounted) return;
      setState(() {});
      if (call.state == CallState.connected) {
        _startTimer();
      } else if (call.state == CallState.ended) {
        Navigator.of(context).pop();
      }
    });
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && CallService.instance.isInCall) {
        setState(() => _callDuration += const Duration(seconds: 1));
        _startTimer();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
        return '正在呼叫...';
      case CallState.ringing:
        return '来电响铃中';
      case CallState.connecting:
        return '正在连接...';
      case CallState.connected:
        return _formatDuration(_callDuration);
      case CallState.ended:
        return '通话已结束';
    }
  }

  @override
  Widget build(BuildContext context) {
    final call = CallService.instance.currentCall;
    if (call == null) return const SizedBox.shrink();

    final isRinging = call.state == CallState.ringing;
    final isConnected = call.state == CallState.connected;
    final isConnecting =
        call.state == CallState.connecting || call.state == CallState.inviting;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            _buildAvatar(isConnected),
            const SizedBox(height: 24),
            Text(
              call.remoteUserId.replaceAll('@', '').split(':').first,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getStateText(call.state),
              style: TextStyle(
                fontSize: 16,
                color: isConnected
                    ? AppColors.success
                    : AppColors.textSecondary(context),
              ),
            ),
            const Spacer(flex: 3),
            if (isConnected) _buildInCallControls(context),
            if (isRinging) _buildIncomingCallControls(),
            if (isConnecting) _buildConnectingControls(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
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
          label: _isMuted ? '取消静音' : '静音',
          color: _isMuted ? AppColors.danger : AppColors.textSecondary(context),
          onTap: () => setState(() => _isMuted = !_isMuted),
        ),
        _buildControlButton(
          icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
          label: _isSpeakerOn ? '扬声器' : '听筒',
          color: _isSpeakerOn
              ? AppColors.accent
              : AppColors.textSecondary(context),
          onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
        ),
        _buildControlButton(
          icon: Icons.call_end,
          label: '挂断',
          color: AppColors.danger,
          onTap: () => CallService.instance.hangup(),
          isLarge: true,
        ),
      ],
    );
  }

  Widget _buildIncomingCallControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: Icons.call_end,
          label: '拒绝',
          color: AppColors.danger,
          onTap: () => CallService.instance.rejectCall(),
          isLarge: true,
        ),
        _buildControlButton(
          icon: Icons.phone,
          label: '接听',
          color: AppColors.success,
          onTap: () => CallService.instance.answerCall(),
          isLarge: true,
        ),
      ],
    );
  }

  Widget _buildConnectingControls() {
    return _buildControlButton(
      icon: Icons.call_end,
      label: '取消',
      color: AppColors.danger,
      onTap: () => CallService.instance.hangup(),
      isLarge: true,
    );
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
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: color, size: isLarge ? 32 : 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
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
          color: AppColors.accent.withValues(alpha: 0.2),
          border: Border.all(
            color: isConnected ? AppColors.success : AppColors.accent,
            width: 3,
          ),
        ),
        child: Icon(
          isConnected ? Icons.phone_in_talk : Icons.phone,
          size: 48,
          color: isConnected ? AppColors.success : AppColors.accent,
        ),
      ),
    );
  }
}
