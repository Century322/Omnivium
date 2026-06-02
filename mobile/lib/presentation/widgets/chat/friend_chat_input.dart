import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/locale_cubit.dart';
import '../voice_message.dart';
import 'chat_components.dart';

class FriendChatInput extends StatelessWidget {
  final TextEditingController textController;
  final FocusNode focusNode;
  final Animation<double> listeningGlow;
  final bool isListening;
  final String? replyContent;
  final String replyLabel;
  final VoidCallback onSend;
  final VoidCallback onToggleEmoji;
  final VoidCallback onToggleListening;
  final VoidCallback onPlusMenu;
  final VoidCallback onCancelReply;
  final void Function(String path, Duration duration) onSendVoice;

  const FriendChatInput({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.listeningGlow,
    required this.isListening,
    this.replyContent,
    this.replyLabel = 'Replying',
    required this.onSend,
    required this.onToggleEmoji,
    required this.onToggleListening,
    required this.onPlusMenu,
    required this.onCancelReply,
    required this.onSendVoice,
  });

  List<BoxShadow> _buildGlowShadows(double g) {
    if (g <= 0) return [];
    return [
      BoxShadow(
        color: AppColors.acc(listeningGlow.isDisposed ? null : listeningGlow.value > 0 ? Colors.blue : Colors.transparent)
            .withValues(alpha: 0.15 * g),
        blurRadius: 12 * g,
        spreadRadius: 2 * g),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final hasText = textController.text.trim().isNotEmpty;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16, 0, 16, bottomPadding > 0 ? bottomPadding : max(24, safeBottom)),
      child: Center(
        child: AnimatedBuilder(
          animation: listeningGlow,
          builder: (context, _) {
            final g = listeningGlow.value;
            final glowShadows = _buildGlowShadows(g);
            final isFocused = focusNode.hasFocus;
            final borderColor = isFocused
                ? AppColors.acc(context)
                : g > 0.5
                ? AppColors.acc(context).withValues(alpha: 0.3)
                : AppColors.divider(context);
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: glowShadows),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.sf(context),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: borderColor)),
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (replyContent != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                        child: ReplyPreview(
                          senderName: replyLabel,
                          content: replyContent!,
                          onCancel: onCancelReply,
                        ),
                      ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: TextField(
                        controller: textController,
                        focusNode: focusNode,
                        maxLength: 4096,
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                        onSubmitted: (_) => onSend(),
                        onChanged: (_) {},
                        decoration: InputDecoration(
                          labelText: localeProvider.t('input_message'),
                          hintStyle: TextStyle(
                            color: AppColors.textHint(context),
                            fontWeight: FontWeight.w500),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12)),
                        maxLines: null)),
                    _buildButtons(context, hasText),
                  ])));
          })));
  }

  Widget _buildButtons(BuildContext context, bool hasText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: FadeTransition(opacity: anim, child: child)),
            child: isListening
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    key: const ValueKey('stop'),
                    onTap: onToggleListening,
                    child: Semantics(
                      button: true,
                      label: localeProvider.t('stop_listening'),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary(context),
                            borderRadius: BorderRadius.circular(2))))))
                : Row(
                    key: const ValueKey('normal-left'),
                    children: [
                      _circleBtn(context, LucideIcons.plus, onTap: onPlusMenu),
                    ])),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) {
              if (child.key == const ValueKey('confirm')) {
                return ScaleTransition(
                  scale: CurvedAnimation(
                    parent: anim, curve: Curves.elasticOut),
                  child: RotationTransition(
                    turns: Tween(begin: -0.12, end: 0.0).animate(anim),
                    child: FadeTransition(opacity: anim, child: child)));
              }
              return ScaleTransition(
                scale: anim,
                child: FadeTransition(opacity: anim, child: child));
            },
            child: isListening
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    key: const ValueKey('confirm'),
                    onTap: onToggleListening,
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.acc(context),
                        borderRadius: BorderRadius.circular(17)),
                      child: Icon(LucideIcons.check,
                          size: 18, color: AppColors.textPrimary(context))))
                : Row(
                    key: const ValueKey('normal-right'),
                    children: [
                      IconButton(
                        icon: Icon(LucideIcons.smile,
                            size: 22, color: AppColors.sec(context)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: onToggleEmoji),
                      const SizedBox(width: 4),
                      VoiceRecorderButton(
                        onSend: onSendVoice),
                      const SizedBox(width: 6),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: hasText ? onSend : () {},
                        child: Semantics(
                          button: true,
                          label: hasText
                              ? localeProvider.t('send_message_semantic')
                              : localeProvider.t('voice_input_semantic'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.acc(context),
                              borderRadius: BorderRadius.circular(17)),
                            child: hasText
                                ? Icon(LucideIcons.arrowUp,
                                    size: 18, color: AppColors.textPrimary(context))
                                : const VoiceBarsIcon()))),
                    ])),
        ]));
  }

  Widget _circleBtn(BuildContext context, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: AppColors.sfHover(context),
          borderRadius: BorderRadius.circular(16)),
        child: Icon(icon, size: 18, color: AppColors.sec(context))));
  }
}
