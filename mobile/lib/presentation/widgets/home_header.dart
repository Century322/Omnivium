import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';
import 'incognito_icon.dart';

class HomeHeader extends StatelessWidget {
  final bool hasSentMessage;
  final Animation<double> headerSwitch;
  final Animation<double> tabSwitch;
  final bool isLibraryMode;
  final bool isIncognito;
  final VoidCallback onCloseConversation;
  final VoidCallback onShowConversationMenu;
  final VoidCallback onOpenDrawer;
  final VoidCallback onCreateGroupChat;
  final VoidCallback onSwitchToChat;
  final VoidCallback onSwitchToLibrary;
  final VoidCallback onToggleSearch;
  final VoidCallback onOpenDiscover;
  final Widget userAvatar;

  const HomeHeader({
    super.key,
    required this.hasSentMessage,
    required this.headerSwitch,
    required this.tabSwitch,
    required this.isLibraryMode,
    required this.isIncognito,
    required this.onCloseConversation,
    required this.onShowConversationMenu,
    required this.onOpenDrawer,
    required this.onCreateGroupChat,
    required this.onSwitchToChat,
    required this.onSwitchToLibrary,
    required this.onToggleSearch,
    required this.onOpenDiscover,
    required this.userAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SizedBox(
          height: 44,
          child: AnimatedBuilder(
            animation: headerSwitch,
            builder: (context, _) {
              final progress = headerSwitch.value;

              if (hasSentMessage && progress > 0.5) {
                return _buildActiveHeader(context);
              }

              return _buildIdleHeader(context, progress);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActiveHeader(BuildContext context) {
    return Row(
      children: [
        Semantics(
          label: localeProvider.t('close_conversation'),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onCloseConversation,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.sfAlt(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                LucideIcons.x,
                size: 18,
                color: AppColors.sec(context),
              ),
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onShowConversationMenu,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.sfAlt(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              LucideIcons.moreVertical,
              size: 18,
              color: AppColors.sec(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdleHeader(BuildContext context, double progress) {
    return Opacity(
      opacity: 1.0 - progress,
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isLibraryMode ? onCreateGroupChat : onOpenDrawer,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.sfAlt(context),
                borderRadius: BorderRadius.circular(15),
              ),
              child: isLibraryMode
                  ? Center(
                      child: Icon(
                        LucideIcons.users,
                        size: 16,
                        color: AppColors.sec(context),
                      ),
                    )
                  : isIncognito
                  ? Center(
                      child: IncognitoIcon(
                        size: 18,
                        color: AppColors.textPrimary(context),
                      ),
                    )
                  : userAvatar,
            ),
          ),
          Expanded(child: Center(child: _buildTabSwitcher(context))),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isLibraryMode ? onToggleSearch : onOpenDiscover,
            child: isLibraryMode
                ? Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.sfAlt(context),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      LucideIcons.search,
                      size: 16,
                      color: AppColors.sec(context),
                    ),
                  )
                : Transform.rotate(
                    angle: 0.17,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.acc(context).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        LucideIcons.flame,
                        size: 16,
                        color: AppColors.acc(context),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher(BuildContext context) {
    return Container(
      height: 42,
      width: 140,
      decoration: BoxDecoration(
        color: AppColors.tab(context),
        borderRadius: BorderRadius.circular(21),
      ),
      padding: const EdgeInsets.all(4),
      child: AnimatedBuilder(
        animation: tabSwitch,
        builder: (context, _) {
          final t = tabSwitch.value;
          return Stack(
            children: [
              Positioned(
                left: t * 66,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 66,
                  decoration: BoxDecoration(
                    color: AppColors.sfActive(context),
                    borderRadius: BorderRadius.circular(19),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onSwitchToChat,
                      child: Center(
                        child: Icon(
                          LucideIcons.messageCircle,
                          size: 18,
                          color: t < 0.5
                              ? AppColors.textPrimary(context)
                              : AppColors.tabIn(context),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onSwitchToLibrary,
                      child: Center(
                        child: Icon(
                          LucideIcons.monitor,
                          size: 18,
                          color: t >= 0.5
                              ? AppColors.textPrimary(context)
                              : AppColors.tabIn(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
