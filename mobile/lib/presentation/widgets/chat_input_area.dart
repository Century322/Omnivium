import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';

class ChatInputArea extends StatelessWidget {
  final TextEditingController textController;
  final FocusNode focusNode;
  final Animation<double> listeningGlow;
  final bool hasSentMessage;
  final bool isListening;
  final bool isEditing;
  final bool isIncognito;
  final bool isFriendChat;
  final bool isGenerating;
  final double maxWidth;
  final VoidCallback onSend;
  final VoidCallback onToggleListening;
  final VoidCallback onCancelEdit;
  final VoidCallback onToggleIncognito;
  final VoidCallback onShowOptions;
  final VoidCallback onShowModels;
  final VoidCallback onChanged;
  final VoidCallback? onStopGeneration;

  const ChatInputArea({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.listeningGlow,
    required this.hasSentMessage,
    required this.isListening,
    required this.isEditing,
    required this.isIncognito,
    required this.isFriendChat,
    this.isGenerating = false,
    required this.maxWidth,
    required this.onSend,
    required this.onToggleListening,
    required this.onCancelEdit,
    required this.onToggleIncognito,
    required this.onShowOptions,
    required this.onShowModels,
    required this.onChanged,
    this.onStopGeneration,
  });

  String t(String key) => localeProvider.t(key);

  @override
  Widget build(BuildContext context) {
    final showQuickCmds = !isFriendChat && textController.text.isEmpty;
    final viewBottom = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, viewBottom > 0 ? viewBottom : max(24, safeBottom)),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth - 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showQuickCmds) const SizedBox.shrink(),
              AnimatedBuilder(
                animation: listeningGlow,
                builder: (context, _) {
                  final g = listeningGlow.value;
                  final hasText = textController.text.trim().isNotEmpty;
                  final glowShadows = _buildGlowShadows(g, context);
                  final isFocused = focusNode.hasFocus;
                  final borderColor = isFocused
                      ? AppColors.acc(context)
                      : Color.lerp(
                          AppColors.divider(context),
                          AppColors.acc(context).withValues(alpha: 0.4),
                          g,
                        )!;
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.sf(context),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: borderColor),
                      boxShadow: glowShadows,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isEditing)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.sfAlt(context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.pencil,
                                  size: 13,
                                  color: AppColors.sec(context),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    t('edit_query'),
                                    style: TextStyle(
                                      color: AppColors.sec(context),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: onCancelEdit,
                                  child: Icon(
                                    LucideIcons.x,
                                    size: 14,
                                    color: AppColors.textHint(context),
                                  ),
                                ),
                              ],
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
                              fontWeight: FontWeight.w500,
                            ),
                            onSubmitted: (_) => onSend(),
                            onChanged: (_) => onChanged(),
                            decoration: InputDecoration(
                              labelText: hasSentMessage
                                  ? t('follow_up')
                                  : t('ask_anything'),
                              hintStyle: TextStyle(
                                color: AppColors.textHint(context),
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            maxLines: null,
                          ),
                        ),
                        _buildInputButtons(context, hasText),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<BoxShadow> _buildGlowShadows(double g, BuildContext context) {
    if (g > 0.01) {
      return [
        BoxShadow(
          color: AppColors.acc(context).withValues(alpha: 0.5 * g),
          blurRadius: 24,
          offset: Offset.zero,
        ),
        BoxShadow(
          color: AppColors.acc(context).withValues(alpha: 0.3 * g),
          blurRadius: 8,
        ),
      ];
    }
    return [];
  }

  Widget _buildInputButtons(BuildContext context, bool hasText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => SizeTransition(
              sizeFactor: anim,
              axis: Axis.horizontal,
              axisAlignment: -1,
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: isListening
                ? SizedBox(
                    key: const ValueKey('listening-left'),
                    width: 34,
                    height: 34,
                    child: Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  )
                : Row(
                    key: const ValueKey('normal-left'),
                    children: [
                      _circleBtn(
                        context,
                        LucideIcons.plus,
                        onTap: onShowOptions,
                      ),
                      const SizedBox(width: 8),
                      _pillBtn(context, t('model'), onTap: onShowModels),
                    ],
                  ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => SizeTransition(
              sizeFactor: anim,
              axis: Axis.horizontal,
              axisAlignment: 1,
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: isListening
                ? Row(
                    key: const ValueKey('listening-right'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onToggleListening,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.acc(context),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Icon(
                            LucideIcons.check,
                            size: 18,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    key: const ValueKey('normal-right'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onToggleIncognito,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isIncognito
                                ? AppColors.accBg(context)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Icon(
                            LucideIcons.glasses,
                            size: 20,
                            color: isIncognito
                                ? AppColors.acc(context)
                                : AppColors.sec(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: isGenerating
                            ? (onStopGeneration ?? () {})
                            : (hasText ? onSend : onToggleListening),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.acc(context),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: isGenerating
                                ? Icon(
                                    LucideIcons.square,
                                    size: 16,
                                    color: AppColors.textPrimary(context),
                                    key: const ValueKey('stop'),
                                  )
                                : hasText
                                ? Icon(
                                    LucideIcons.arrowUp,
                                    size: 18,
                                    color: AppColors.textPrimary(context),
                                    key: const ValueKey('send'),
                                  )
                                : Icon(
                                    LucideIcons.mic,
                                    size: 18,
                                    color: AppColors.textPrimary(context),
                                    key: const ValueKey('mic'),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(
    BuildContext context,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.sfHover(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, size: 18, color: AppColors.sec(context)),
      ),
    );
  }

  Widget _pillBtn(BuildContext context, String text, {VoidCallback? onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.sfHover(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.sec(context),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
