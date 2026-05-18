import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';
import 'home_components.dart';

class ChatInputArea extends StatelessWidget {
  final TextEditingController textController;
  final FocusNode focusNode;
  final Animation<double> listeningGlow;
  final bool hasSentMessage;
  final bool isListening;
  final bool isEditing;
  final bool showCopied;
  final bool isIncognito;
  final bool isFriendChat;
  final double maxWidth;
  final VoidCallback onSend;
  final VoidCallback onToggleListening;
  final VoidCallback onCancelEdit;
  final VoidCallback onToggleIncognito;
  final VoidCallback onShowOptions;
  final VoidCallback onShowModels;
  final VoidCallback onOpenVoice;
  final VoidCallback onChanged;

  const ChatInputArea({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.listeningGlow,
    required this.hasSentMessage,
    required this.isListening,
    required this.isEditing,
    required this.showCopied,
    required this.isIncognito,
    required this.isFriendChat,
    required this.maxWidth,
    required this.onSend,
    required this.onToggleListening,
    required this.onCancelEdit,
    required this.onToggleIncognito,
    required this.onShowOptions,
    required this.onShowModels,
    required this.onOpenVoice,
    required this.onChanged,
  });

  String t(String key) => localeProvider.t(key);

  @override
  Widget build(BuildContext context) {
    final showQuickCmds = !isFriendChat && textController.text.isEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth - 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showQuickCmds) const SizedBox.shrink(),
              AnimatedOpacity(
                opacity: showCopied ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: showCopied
                    ? Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.sf(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.divider(context)),
                        ),
                        child: Text(t('copied'), style: TextStyle(color: AppColors.sec(context), fontSize: 13, fontWeight: FontWeight.w500)),
                      )
                    : const SizedBox.shrink(),
              ),
              AnimatedBuilder(
                animation: listeningGlow,
                builder: (context, _) {
                  final g = listeningGlow.value;
                  final hasText = textController.text.trim().isNotEmpty;
                  final glowShadows = _buildGlowShadows(g);
                  final borderColor = g > 0.5 ? AppColors.accent : AppColors.divider(context);
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: glowShadows,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.sf(context),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: borderColor),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isEditing)
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.sfAlt(context),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(LucideIcons.pencil, size: 13, color: AppColors.sec(context)),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(t('edit_query'), style: TextStyle(color: AppColors.sec(context), fontSize: 12, fontWeight: FontWeight.w500))),
                                  GestureDetector(
                                    onTap: onCancelEdit,
                                    child: Icon(LucideIcons.x, size: 14, color: AppColors.textHint(context)),
                                  ),
                                ],
                              ),
                            ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 120),
                            child: TextField(
                              controller: textController,
                              focusNode: focusNode,
                              style: TextStyle(color: AppColors.textPrimary(context), fontSize: 16, fontWeight: FontWeight.w500),
                              onSubmitted: (_) => onSend(),
                              onChanged: (_) => onChanged(),
                              decoration: InputDecoration(
                                labelText: hasSentMessage ? t('follow_up') : t('ask_anything'),
                                hintStyle: TextStyle(color: AppColors.textHint(context), fontWeight: FontWeight.w500),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              maxLines: null,
                            ),
                          ),
                          _buildInputButtons(context, hasText),
                        ],
                      ),
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

  List<BoxShadow> _buildGlowShadows(double g) {
    if (g > 0.01) {
      return [
        BoxShadow(color: AppColors.accent.withValues(alpha: 0.5 * g), blurRadius: 24, offset: const Offset(0, -4)),
        BoxShadow(color: AppColors.accent.withValues(alpha: 0.3 * g), blurRadius: 8),
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
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
            child: isListening
                ? GestureDetector(
                    key: const ValueKey('stop'),
                    onTap: onToggleListening,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: AppColors.textPrimary(context), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                  )
                : Row(key: const ValueKey('normal-left'), children: [
                    _circleBtn(context, LucideIcons.plus, onTap: onShowOptions),
                    const SizedBox(width: 8),
                    _pillBtn(context, t('model'), onTap: onShowModels),
                  ]),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) {
              if (child.key == const ValueKey('confirm')) {
                return ScaleTransition(
                    scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
                    child: RotationTransition(
                        turns: Tween(begin: -0.12, end: 0.0).animate(anim),
                        child: FadeTransition(opacity: anim, child: child)));
              }
              return ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child));
            },
            child: isListening
                ? GestureDetector(
                    key: const ValueKey('confirm'),
                    onTap: onToggleListening,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(17)),
                      child: Icon(LucideIcons.check, size: 18, color: AppColors.textPrimary(context)),
                    ),
                  )
                : Row(key: const ValueKey('normal-right'), children: [
                    GestureDetector(
                      onTap: onToggleIncognito,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isIncognito ? AppColors.accBg(context) : Colors.transparent,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Icon(LucideIcons.glasses, size: 20, color: isIncognito ? AppColors.accent : AppColors.sec(context)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onToggleListening,
                      child: SizedBox(width: 34, height: 34, child: Center(child: Icon(LucideIcons.mic, size: 20, color: AppColors.sec(context)))),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: hasText ? onSend : onOpenVoice,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(17)),
                        child: hasText
                            ? Icon(LucideIcons.arrowUp, size: 18, color: AppColors.textPrimary(context))
                            : const VoiceBarsIcon(),
                      ),
                    ),
                  ]),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(BuildContext context, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: AppColors.sfHover(context), borderRadius: BorderRadius.circular(16)),
        child: Icon(icon, size: 18, color: AppColors.sec(context)),
      ),
    );
  }

  Widget _pillBtn(BuildContext context, String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: AppColors.sfHover(context), borderRadius: BorderRadius.circular(16)),
        child: Center(child: Text(text, style: TextStyle(color: AppColors.sec(context), fontSize: 13, fontWeight: FontWeight.w500))),
      ),
    );
  }
}
