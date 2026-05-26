import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../core/agent/agent_state.dart';

class ChatMessageData {
  final String role;
  final String content;
  final bool isStreaming;
  final String? cardType;
  final Map<String, dynamic>? cardData;
  final List<ThoughtStep> thoughts;
  const ChatMessageData({
    required this.role,
    required this.content,
    this.isStreaming = false,
    this.cardType,
    this.cardData,
    this.thoughts = const [],
  });
}

class ListItemData {
  final Widget widget;
  final double bottomPadding;
  const ListItemData(this.widget, this.bottomPadding);
}

class ChatItemData {
  final String id;
  final String name;
  final String lastMsg;
  final String time;
  const ChatItemData(this.id, this.name, this.lastMsg, this.time);
}

class FriendMessageData {
  final bool isMe;
  final String content;
  final String? eventId;
  final String? msgType;
  final String? url;
  final int? audioDuration;
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSender;
  final String? formattedContent;
  final String? senderId;
  const FriendMessageData({
    required this.isMe,
    required this.content,
    this.eventId,
    this.msgType,
    this.url,
    this.audioDuration,
    this.replyToId,
    this.replyToContent,
    this.replyToSender,
    this.formattedContent,
    this.senderId,
  });
  bool get isVoice => msgType == 'm.audio' || content.startsWith('🎙️');
  bool get isImage => msgType == 'm.image';
  bool get isFile => msgType == 'm.file';
  bool get hasReply => replyToId != null && replyToContent != null;
}

class NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class SlidingSheet extends StatefulWidget {
  final Widget child;
  const SlidingSheet({super.key, required this.child});

  @override
  State<SlidingSheet> createState() => _SlidingSheetState();
}

class _SlidingSheetState extends State<SlidingSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            MediaQuery.of(context).size.height * (1 - _anim.value),
          ),
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bg(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: widget.child,
      ),
    );
  }
}

class VoiceBarsIcon extends StatefulWidget {
  const VoiceBarsIcon({super.key});

  @override
  State<VoiceBarsIcon> createState() => _VoiceBarsIconState();
}

class _VoiceBarsIconState extends State<VoiceBarsIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final v = _ctrl.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            final h = 8.0 + 8.0 * ((i % 2 == 0 ? v : 1 - v) * (i + 1) / 5);
            return Container(
              width: 3,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: AppColors.acc(context),
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        );
      },
    );
  }
}
