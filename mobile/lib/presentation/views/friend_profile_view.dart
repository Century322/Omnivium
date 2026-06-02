import '../../core/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/locale_cubit.dart';
import '../../core/di/app_di.dart';
import '../../core/matrix/matrix_cubit.dart';
import '../../core/matrix/matrix_dtos.dart';


class FriendProfileView extends StatelessWidget { final String roomId;
  const FriendProfileView({
    super.key,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    final t = localeProvider.t;
    final matrix = getIt<MatrixCubit>();
    final roomInfo = matrix.getRoomInfo(roomId);
    if (roomInfo == null) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            tooltip: localeProvider.t('back'),
            icon: Icon(LucideIcons.arrowLeft, color: AppColors.sec(context)),
            onPressed: () => Navigator.pop(context))),
        body: Center(
          child: Text(
            t('room_not_found'),
            style: TextStyle(color: AppColors.textTertiary(context)))));
    }
    final displayName = roomInfo.displayName;
    final isEncrypted = roomInfo.isEncrypted;
    final isDirect = roomInfo.isDirectChat;
    final memberCount = roomInfo.memberCount;
    final members = matrix.getRoomMembers(roomId);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          tooltip: localeProvider.t('back'),
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.sec(context)),
          onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            tooltip: localeProvider.t('more'),
            icon: Icon(
              LucideIcons.moreVertical,
              color: AppColors.sec(context),
              size: 20),
            onPressed: () => _showMoreOptions(context, roomId)),
        ]),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).padding.bottom + 40),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.sfAlt(context),
                  borderRadius: BorderRadius.circular(28)),
                child: Center(
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 32,
                      fontWeight: FontWeight.w700))))),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 22,
                fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              roomId,
              style: TextStyle(
                color: AppColors.textTertiary(context),
                fontSize: 12),
              overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4),
                  decoration: BoxDecoration(
                    color: isEncrypted
                        ? AppColors.acc(context).withValues(alpha: 0.15)
                        : AppColors.warn(context).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isEncrypted
                            ? LucideIcons.shieldCheck
                            : LucideIcons.shieldAlert,
                        size: 14,
                        color: isEncrypted
                            ? AppColors.acc(context)
                            : AppColors.warn(context)),
                      const SizedBox(width: 4),
                      Text(
                        isEncrypted ? t('encrypted') : t('not_encrypted'),
                        style: TextStyle(
                          color: isEncrypted
                              ? AppColors.acc(context)
                              : AppColors.warn(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                    ])),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.sf(context),
                    borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.users,
                        size: 14,
                        color: AppColors.sec(context)),
                      const SizedBox(width: 4),
                      Text(
                        isDirect
                            ? t('private_chat')
                            : '${t('group_chat')} · $memberCount',
                        style: TextStyle(
                          color: AppColors.sec(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                    ])),
              ]),
            const SizedBox(height: 32),
            _buildSection(context, t('members'), [
              for (final member in members.take(20))
                _buildMemberTile(context, member, matrix.userId, t),
              if (members.length > 20)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '${members.length - 20} ${t('more_members')}',
                    style: TextStyle(
                      color: AppColors.iconGray(context),
                      fontSize: 13))),
            ]),
            if (!isDirect) ...[
              const SizedBox(height: 20),
              _buildSection(context, t('group_settings'), [
                _buildActionTile(
                  context,
                  LucideIcons.edit3,
                  t('edit_group_name'),
                  () => _showEditGroupName(context, roomId, t)),
                _buildActionTile(
                  context,
                  LucideIcons.userPlus,
                  t('invite_member'),
                  () => _showInviteMember(context, roomId, t)),
                _buildActionTile(
                  context,
                  LucideIcons.logOut,
                  t('leave_group'),
                  () => _leaveGroup(context, roomId)),
              ]),
            ],
            const SizedBox(height: 20),
            _buildSection(context, t('actions'), [
              _buildActionTile(
                context,
                LucideIcons.search,
                t('search_chat_history'),
                () => Navigator.pop(context)),
              _buildActionTile(
                context,
                LucideIcons.share,
                t('share_conversation'),
                () {
                  Navigator.pop(context);
                  _showComingSoon(context);
                }),
              _buildActionTile(
                context,
                LucideIcons.bell,
                t('mute_notifications'),
                () => _toggleMute(context, roomId)),
              _buildActionTile(
                context,
                LucideIcons.trash2,
                t('clear_chat'),
                () => _clearChat(context, roomId),
                isDanger: true),
            ]),
            const SizedBox(height: 40),
          ])));
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.iconGray(context),
              fontSize: 13,
              fontWeight: FontWeight.w600))),
        Container(
          decoration: BoxDecoration(
            color: AppColors.sf(context),
            borderRadius: BorderRadius.circular(14)),
          child: Column(children: children)),
      ]);
  }

  Widget _buildMemberTile(
    BuildContext context,
    MemberInfo member,
    String? currentUserId,
    String Function(String) t) {
    final isMe = member.id == currentUserId;
    final name = member.displayName;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.sfAlt(context),
              borderRadius: BorderRadius.circular(18)),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w600)))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name + (isMe ? t('you') : ''),
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
                Text(
                  member.id,
                  style: TextStyle(
                    color: AppColors.iconGray(context),
                    fontSize: 11),
                  overflow: TextOverflow.ellipsis),
              ])),
        ]));
  }

  Widget _buildActionTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDanger = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isDanger ? AppColors.dng(context) : AppColors.sec(context)),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isDanger
                    ? AppColors.dng(context)
                    : AppColors.textPrimary(context),
                fontSize: 15,
                fontWeight: FontWeight.w500)),
          ])));
  }

  void _showEditGroupName(
    BuildContext context,
    String roomId,
    String Function(String) t) {
    final matrix = getIt<MatrixCubit>();
    final roomInfo = matrix.getRoomInfo(roomId);
    final ctrl = TextEditingController(text: roomInfo?.displayName ?? '');
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('edit_group_name'),
          style: TextStyle(color: AppColors.textPrimary(context))),
        content: TextField(
          controller: ctrl,
          maxLength: 100,
          style: TextStyle(color: AppColors.textPrimary(context)),
          decoration: InputDecoration(
            labelText: t('enter_new_group_name'),
            hintStyle: TextStyle(color: AppColors.textDisabled(context)),
            filled: true,
            fillColor: AppColors.sfAlt(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none))),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ctrl.dispose();
            },
            child: Text(
              t('cancel'),
              style: TextStyle(color: AppColors.sec(context)))),
          TextButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context);
              ctrl.dispose();
              try {
                await getIt<MatrixCubit>().setRoomName(roomId, name);
              } catch (e, stackTrace) {
                AppLogger.instance.error(
                  'App error',
                  error: e,
                  stackTrace: stackTrace);
              }
            },
            child: Text(
              t('confirm'),
              style: TextStyle(color: AppColors.acc(context)))),
        ]));
  }

  void _showInviteMember(
    BuildContext context,
    String roomId,
    String Function(String) t) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('invite_member'),
          style: TextStyle(color: AppColors.textPrimary(context))),
        content: TextField(
          controller: ctrl,
          maxLength: 512,
          style: TextStyle(color: AppColors.textPrimary(context), fontSize: 14),
          decoration: InputDecoration(
            labelText: t('enter_matrix_id'),
            hintStyle: TextStyle(
              color: AppColors.textDisabled(context),
              fontSize: 13),
            filled: true,
            fillColor: AppColors.sfAlt(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none))),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ctrl.dispose();
            },
            child: Text(
              t('cancel'),
              style: TextStyle(color: AppColors.sec(context)))),
          TextButton(
            onPressed: () async {
              final userId = ctrl.text.trim();
              if (userId.isEmpty) return;
              Navigator.pop(context);
              ctrl.dispose();
              try {
                await getIt<MatrixCubit>().inviteToRoom(roomId, userId);
              } catch (e, stackTrace) {
                AppLogger.instance.error(
                  'App error',
                  error: e,
                  stackTrace: stackTrace);
              }
            },
            child: Text(
              t('invite'),
              style: TextStyle(color: AppColors.acc(context)))),
        ]));
  }

  void _leaveGroup(BuildContext context, String roomId) async {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          localeProvider.t('leave_group'),
          style: TextStyle(color: AppColors.textPrimary(context))),
        content: Text(
          localeProvider.t('leave_group_confirm'),
          style: TextStyle(color: AppColors.textSecondary(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localeProvider.t('cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await getIt<MatrixCubit>().leaveRoom(roomId);
                if (context.mounted) Navigator.pop(context);
              } catch (e, stackTrace) {
                AppLogger.instance.error(
                  'App error',
                  error: e,
                  stackTrace: stackTrace);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localeProvider.t('operation_failed')),
                      backgroundColor: AppColors.dng(context),
                      duration: const Duration(seconds: 2)));
                }
              }
            },
            child: Text(
              localeProvider.t('confirm'),
              style: TextStyle(color: AppColors.dng(context)))),
        ]));
  }

  void _toggleMute(BuildContext context, String roomId) async {
    final matrix = getIt<MatrixCubit>();
    final isMuted = matrix.isRoomMuted(roomId);
    await matrix.setMuteRoom(roomId, !isMuted);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isMuted ? localeProvider.t('unmuted') : localeProvider.t('muted')),
          backgroundColor: AppColors.acc(context),
          duration: const Duration(seconds: 1)));
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localeProvider.t('coming_soon')),
        backgroundColor: AppColors.acc(context),
        duration: const Duration(seconds: 2)));
  }

  void _showMoreOptions(BuildContext context, String roomId) {
    final matrix = getIt<MatrixCubit>();
    final t = localeProvider.t;
    final isDirect = matrix.isRoomDirectChat(roomId);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.sf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(LucideIcons.flag, color: AppColors.sec(context)),
              title: Text(
                t('report'),
                style: TextStyle(color: AppColors.textPrimary(context))),
              onTap: () {
                Navigator.pop(context);
                _reportUser(context, roomId);
              }),
            ListTile(
              leading: Icon(LucideIcons.ban, color: AppColors.dng(context)),
              title: Text(
                t('block'),
                style: TextStyle(color: AppColors.dng(context))),
              onTap: () {
                Navigator.pop(context);
                _blockUser(context, roomId);
              }),
            if (isDirect)
              ListTile(
                leading: Icon(
                  LucideIcons.userMinus,
                  color: AppColors.dng(context)),
                title: Text(
                  t('remove_friend'),
                  style: TextStyle(color: AppColors.dng(context))),
                onTap: () {
                  Navigator.pop(context);
                  _removeFriend(context, roomId);
                }),
          ])));
  }

  void _reportUser(BuildContext context, String roomId) async {
    final t = localeProvider.t;
    final matrix = getIt<MatrixCubit>();
    final client = matrix.client;
    if (client == null) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('report'),
          style: TextStyle(color: AppColors.textPrimary(context))),
        content: Text(
          t('report_confirm_msg'),
          style: TextStyle(color: AppColors.textSecondary(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel'))),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await client.reportRoom(roomId, t('report'));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t('report_submitted')),
                      backgroundColor: AppColors.acc(context),
                      duration: const Duration(seconds: 2)));
                }
              } catch (e, stackTrace) {
                AppLogger.instance.error(
                  'Report failed',
                  error: e,
                  stackTrace: stackTrace);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t('operation_failed')),
                      backgroundColor: AppColors.dng(context),
                      duration: const Duration(seconds: 2)));
                }
              }
            },
            child: Text(t('report'))),
        ]));
  }

  void _blockUser(BuildContext context, String roomId) async {
    final t = localeProvider.t;
    final matrix = getIt<MatrixCubit>();
    final client = matrix.client;
    if (client == null) return;
    final room = client.getRoomById(roomId);
    if (room == null) return;
    final otherUserId = room.directChatMatrixID;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('block'),
          style: TextStyle(color: AppColors.textPrimary(context))),
        content: Text(
          t('block_confirm_msg'),
          style: TextStyle(color: AppColors.textSecondary(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.dng(context)),
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (otherUserId != null) {
                  await client.ignoreUser(otherUserId);
                }
                await room.leave();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t('user_blocked')),
                      backgroundColor: AppColors.dng(context),
                      duration: const Duration(seconds: 2)));
                  Navigator.pop(context);
                }
              } catch (e, stackTrace) {
                AppLogger.instance.error(
                  'Block failed',
                  error: e,
                  stackTrace: stackTrace);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t('operation_failed')),
                      backgroundColor: AppColors.dng(context),
                      duration: const Duration(seconds: 2)));
                }
              }
            },
            child: Text(t('block'))),
        ]));
  }

  void _removeFriend(BuildContext context, String roomId) async {
    final t = localeProvider.t;
    final matrix = getIt<MatrixCubit>();
    final client = matrix.client;
    if (client == null) return;
    final room = client.getRoomById(roomId);
    if (room == null) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('remove_friend'),
          style: TextStyle(color: AppColors.textPrimary(context))),
        content: Text(
          t('remove_friend_confirm'),
          style: TextStyle(color: AppColors.textSecondary(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.dng(context)),
            onPressed: () {
              Navigator.pop(context);
              room.leave().then((_) {
                if (context.mounted) Navigator.pop(context);
              });
            },
            child: Text(t('remove'))),
        ]));
  }

  void _clearChat(BuildContext context, String roomId) async {
    final matrix = getIt<MatrixCubit>();
    final client = matrix.client;
    if (client == null) return;
    final room = client.getRoomById(roomId);
    if (room == null) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          localeProvider.t('clear_chat'),
          style: TextStyle(color: AppColors.textPrimary(context))),
        content: Text(
          localeProvider.t('clear_chat_confirm'),
          style: TextStyle(color: AppColors.textSecondary(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localeProvider.t('cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final timeline = await room.getTimeline();
                for (final event in timeline.events) {
                  if (event.senderId == client.userID) {
                    try {
                      await room.redactEvent(event.eventId);
                    } catch (e) {
                      AppLogger.instance.debug('Redact event failed', error: e);
                    }
                  }
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localeProvider.t('chat_cleared')),
                      backgroundColor: AppColors.acc(context),
                      duration: const Duration(seconds: 2)));
                }
              } catch (e, stackTrace) {
                AppLogger.instance.error(
                  'Clear chat failed',
                  error: e,
                  stackTrace: stackTrace);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localeProvider.t('operation_failed')),
                      backgroundColor: AppColors.dng(context),
                      duration: const Duration(seconds: 2)));
                }
              }
            },
            child: Text(
              localeProvider.t('confirm'),
              style: TextStyle(color: AppColors.dng(context)))),
        ]));
  }
}
