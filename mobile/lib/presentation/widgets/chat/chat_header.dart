import 'package:flutter/material.dart';
import '../../core/di/app_di.dart';
import '../../core/matrix/matrix_cubit.dart';
import '../../theme/app_colors.dart';
import '../../theme/locale_cubit.dart';

class ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  final String chatTargetId;
  final VoidCallback? onBack;
  final VoidCallback? onCall;
  final VoidCallback? onVideoCall;
  final VoidCallback? onInfo;

  const ChatHeader({
    super.key,
    required this.chatTargetId,
    this.onBack,
    this.onCall,
    this.onVideoCall,
    this.onInfo,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String get _displayName {
    try {
      final matrix = getIt<MatrixCubit>();
      final room = matrix.getRoom(chatTargetId);
      return room?.displayName ?? chatTargetId;
    } catch (_) {
      return chatTargetId;
    }
  }

  String? get _avatarUrl {
    try {
      final matrix = getIt<MatrixCubit>();
      final room = matrix.getRoom(chatTargetId);
      return room?.avatar;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppColors.textPrimary(context)),
        onPressed: onBack ?? () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage:
                _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
            child: _avatarUrl == null
                ? Text(_displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?')
                : null,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _displayName,
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 17,
                fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
          ),
        ]),
      actions: [
        if (onCall != null)
          IconButton(
            icon: Icon(Icons.phone, color: AppColors.sec(context)),
            onPressed: onCall),
        if (onVideoCall != null)
          IconButton(
            icon: Icon(Icons.videocam, color: AppColors.sec(context)),
            onPressed: onVideoCall),
        if (onInfo != null)
          IconButton(
            icon: Icon(Icons.info_outline, color: AppColors.sec(context)),
            onPressed: onInfo),
      ],
    );
  }
}
