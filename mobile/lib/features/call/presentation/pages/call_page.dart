import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../bloc/call_bloc.dart';
import '../bloc/call_event.dart';
import '../bloc/call_state.dart' as bloc_state;
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/locale_cubit.dart';
import '../../../../core/di/app_di.dart';

class CallPage extends StatelessWidget {
  final String? roomId;
  final String? userId;
  final bool isVideo;

  const CallPage({super.key, this.roomId, this.userId, this.isVideo = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = getIt<CallBloc>();
        if (roomId != null && userId != null) {
          bloc.add(CallStarted(roomId: roomId!, userId: userId!, isVideo: isVideo));
        }
        return bloc;
      },
      child: const _CallContent());
  }
}

class _CallContent extends StatefulWidget {
  const _CallContent();

  @override
  State<_CallContent> createState() => _CallContentState();
}

class _CallContentState extends State<_CallContent> {
  bool _isMuted = false;
  bool _isSpeaker = true;
  bool _isCameraOff = false;
  Duration _callDuration = Duration.zero;
  Timer? _durationTimer;

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callDuration += const Duration(seconds: 1));
    });
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
      body: SafeArea(
        child: BlocConsumer<CallBloc, bloc_state.CallBlocState>(
          listener: (context, state) {
            if (state is bloc_state.CallConnected) {
              _startTimer();
            }
            if (state is bloc_state.CallEnded) {
              _durationTimer?.cancel();
              Future<void>.delayed(const Duration(seconds: 2), () {
                if (mounted) Navigator.pop(context);
              });
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                const Spacer(flex: 2),
                _buildAvatar(state),
                const SizedBox(height: 24),
                _buildCallerInfo(state),
                const SizedBox(height: 8),
                _buildStatus(state),
                const Spacer(flex: 3),
                _buildControls(state),
                const SizedBox(height: 48),
              ]);
          })));
  }

  Widget _buildAvatar(bloc_state.CallBlocState state) {
    final name = _getRemoteName(state);
    final isVideo = _isVideoCall(state);
    if (isVideo && state is bloc_state.CallConnected) {
      return Container(
        width: 200,
        height: 280,
        decoration: BoxDecoration(
          color: AppColors.sfAlt(context),
          borderRadius: BorderRadius.circular(20)),
        child: Center(
          child: Icon(LucideIcons.video, size: 48, color: AppColors.textDisabled(context))));
    }
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.acc(context), AppColors.acc(context).withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.acc(context).withValues(alpha: 0.3),
            blurRadius: 32,
            offset: const Offset(0, 8)),
        ]),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: AppColors.bg(context),
            fontSize: 40,
            fontWeight: FontWeight.w700))));
  }

  Widget _buildCallerInfo(bloc_state.CallBlocState state) {
    final name = _getRemoteName(state);
    return Text(
      name.isNotEmpty ? name : localeProvider.t('unknown_caller'),
      style: TextStyle(
        color: AppColors.textPrimary(context),
        fontSize: 24,
        fontWeight: FontWeight.w600));
  }

  Widget _buildStatus(bloc_state.CallBlocState state) {
    String statusText;
    Color statusColor;

    if (state is bloc_state.CallRinging) {
      statusText = localeProvider.t('calling');
      statusColor = AppColors.acc(context);
    } else if (state is bloc_state.CallConnecting) {
      statusText = localeProvider.t('connecting');
      statusColor = AppColors.warn(context);
    } else if (state is bloc_state.CallConnected) {
      statusText = _formatDuration(_callDuration);
      statusColor = AppColors.ok(context);
    } else if (state is bloc_state.CallEnded) {
      statusText = localeProvider.t('call_ended');
      statusColor = AppColors.dng(context);
    } else {
      statusText = localeProvider.t('ready');
      statusColor = AppColors.textSecondary(context);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state is bloc_state.CallRinging || state is bloc_state.CallConnecting)
          Container(
            width: 8, height: 8,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle)),
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontSize: 16,
            fontWeight: FontWeight.w500)),
      ]);
  }

  Widget _buildControls(bloc_state.CallBlocState state) {
    final isInCall = state is bloc_state.CallRinging ||
        state is bloc_state.CallConnecting ||
        state is bloc_state.CallConnected;
    final isRinging = state is bloc_state.CallRinging;
    final isVideo = _isVideoCall(state);

    return Column(
      children: [
        if (isRinging) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: LucideIcons.phoneOff,
                label: localeProvider.t('decline'),
                color: AppColors.dng(context),
                onTap: () {
                  final callId = _getCallId(state);
                  if (callId != null) {
                    context.read<CallBloc>().add(CallDeclined(callId));
                  }
                }),
              _buildControlButton(
                icon: LucideIcons.phone,
                label: localeProvider.t('accept'),
                color: AppColors.ok(context),
                onTap: () {
                  final callId = _getCallId(state);
                  if (callId != null) {
                    context.read<CallBloc>().add(CallAnswered(callId));
                  }
                }),
            ]),
        ] else if (isInCall) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: _isMuted ? LucideIcons.micOff : LucideIcons.mic,
                label: _isMuted ? localeProvider.t('unmute') : localeProvider.t('mute'),
                color: _isMuted ? AppColors.dng(context) : AppColors.sf(context),
                iconColor: _isMuted ? AppColors.bg(context) : AppColors.textPrimary(context),
                onTap: () {
                  setState(() => _isMuted = !_isMuted);
                  context.read<CallBloc>().add(CallMuteToggled(_isMuted));
                }),
              if (isVideo)
                _buildControlButton(
                  icon: _isCameraOff ? LucideIcons.videoOff : LucideIcons.video,
                  label: _isCameraOff ? localeProvider.t('camera_on') : localeProvider.t('camera_off'),
                  color: _isCameraOff ? AppColors.dng(context) : AppColors.sf(context),
                  iconColor: _isCameraOff ? AppColors.bg(context) : AppColors.textPrimary(context),
                  onTap: () {
                    setState(() => _isCameraOff = !_isCameraOff);
                    context.read<CallBloc>().add(CallCameraToggled(!_isCameraOff));
                  }),
              _buildControlButton(
                icon: _isSpeaker ? LucideIcons.volume2 : LucideIcons.volumeX,
                label: localeProvider.t('speaker'),
                color: _isSpeaker ? AppColors.acc(context) : AppColors.sf(context),
                iconColor: _isSpeaker ? AppColors.bg(context) : AppColors.textPrimary(context),
                onTap: () {
                  setState(() => _isSpeaker = !_isSpeaker);
                  context.read<CallBloc>().add(CallSpeakerToggled(_isSpeaker));
                }),
              _buildControlButton(
                icon: LucideIcons.phoneOff,
                label: localeProvider.t('end_call'),
                color: AppColors.dng(context),
                onTap: () {
                  final callId = _getCallId(state);
                  if (callId != null) {
                    context.read<CallBloc>().add(CallEnded(callId));
                  } else {
                    Navigator.pop(context);
                  }
                }),
            ]),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: LucideIcons.phone,
                label: localeProvider.t('voice_call'),
                color: AppColors.ok(context),
                onTap: () => Navigator.pop(context)),
              _buildControlButton(
                icon: LucideIcons.video,
                label: localeProvider.t('video_call'),
                color: AppColors.acc(context),
                onTap: () => Navigator.pop(context)),
            ]),
        ],
      ]);
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle),
            child: Icon(icon, color: iconColor ?? AppColors.bg(context), size: 24)),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 11)),
        ]));
  }

  String _getRemoteName(bloc_state.CallBlocState state) {
    if (state is bloc_state.CallRinging) return state.call.remoteUserName;
    if (state is bloc_state.CallConnecting) return state.call.remoteUserName;
    if (state is bloc_state.CallConnected) return state.call.remoteUserName;
    if (state is bloc_state.CallEnded) return state.lastCall?.remoteUserName ?? '';
    return '';
  }

  bool _isVideoCall(bloc_state.CallBlocState state) {
    if (state is bloc_state.CallRinging) return state.call.isVideo;
    if (state is bloc_state.CallConnecting) return state.call.isVideo;
    if (state is bloc_state.CallConnected) return state.call.isVideo;
    return false;
  }

  String? _getCallId(bloc_state.CallBlocState state) {
    if (state is bloc_state.CallRinging) return state.call.callId;
    if (state is bloc_state.CallConnecting) return state.call.callId;
    if (state is bloc_state.CallConnected) return state.call.callId;
    return null;
  }
}
