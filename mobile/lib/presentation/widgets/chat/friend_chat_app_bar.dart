import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:matrix/matrix.dart';
import '../../../core/di/app_di.dart';
import '../../../core/matrix/matrix_cubit.dart';
import '../../theme/app_colors.dart';
import '../../theme/locale_cubit.dart';

class FriendChatAppBar extends StatelessWidget {
  final String chatTargetId;
  final String chatTargetName;
  final VoidCallback onClose;
  final bool isOtherTyping;
  final Future<CachedPresence?>? presenceFuture;
  final VoidCallback? onEncryptionInfo;
  final VoidCallback? onMenu;

  const FriendChatAppBar({
    super.key,
    required this.chatTargetId,
    required this.chatTargetName,
    required this.onClose,
    this.isOtherTyping = false,
    this.presenceFuture,
    this.onEncryptionInfo,
    this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.sfAlt(context),
                    borderRadius: BorderRadius.circular(16)),
                  child: Icon(LucideIcons.arrowLeft,
                      size: 18, color: AppColors.sec(context)))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      chatTargetName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                    if (isOtherTyping)
                      Text(
                        localeProvider.t('typing'),
                        style: TextStyle(
                          color: AppColors.acc(context), fontSize: 11))
                    else
                      FutureBuilder<CachedPresence?>(
                        future: presenceFuture,
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return SizedBox(
                              width: 60, height: 14,
                              child: LinearProgressIndicator(
                                borderRadius: BorderRadius.circular(2),
                                backgroundColor: AppColors.sfActive(context)));
                          }
                          if (snap.hasError || !snap.hasData) {
                            return Text(
                              '@$chatTargetId',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textTertiary(context),
                                fontSize: 11));
                          }
                          final presence = snap.data;
                          if (presence == null) return const SizedBox.shrink();
                          final isOnline = presence.currentlyActive == true;
                          final status = isOnline
                              ? localeProvider.t('online')
                              : localeProvider.t('offline');
                          return Row(children: [
                            Container(
                              width: 6, height: 6,
                              decoration: BoxDecoration(
                                color: isOnline
                                    ? AppColors.acc(context)
                                    : AppColors.iconGray(context),
                                borderRadius: BorderRadius.circular(3))),
                            const SizedBox(width: 4),
                            Text(status,
                                style: TextStyle(
                                  color: isOnline
                                      ? AppColors.acc(context)
                                      : AppColors.iconGray(context),
                                  fontSize: 11)),
                          ]);
                        }),
                  ])),
              StreamBuilder<MatrixState>(
                stream: getIt<MatrixCubit>().stream,
                builder: (context, _) {
                  final isEncrypted = chatTargetId.isNotEmpty
                      && getIt<MatrixCubit>().isRoomEncrypted(chatTargetId);
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onEncryptionInfo,
                    child: Icon(
                      isEncrypted ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
                      size: 18,
                      color: isEncrypted
                          ? AppColors.acc(context)
                          : AppColors.warn(context)));
                }),
              const SizedBox(width: 12),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onMenu,
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.sfAlt(context),
                    borderRadius: BorderRadius.circular(16)),
                  child: Icon(LucideIcons.moreVertical,
                      size: 18, color: AppColors.sec(context)))),
            ])));
  }
}
