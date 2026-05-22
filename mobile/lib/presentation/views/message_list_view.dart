import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:matrix/matrix.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';
import '../../core/app_provider.dart';
import '../../core/app_navigator.dart';
import 'friend_profile_view.dart';

class MessageListView extends StatefulWidget {
  final AppProvider provider;
  const MessageListView({super.key, required this.provider});

  @override
  State<MessageListView> createState() => _MessageListViewState();
}

class _MessageListViewState extends State<MessageListView> {
  String _searchQuery = '';

  List<Room> get _filteredRooms {
    final rooms = widget.provider.matrix.rooms;
    if (_searchQuery.isEmpty) return rooms;
    return rooms.where((room) {
      final name = room.getLocalizedDisplayname().toLowerCase();
      final lastMsg = room.lastEvent?.plaintextBody.toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase()) || lastMsg.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.sf(context),
        elevation: 0,
        leading: IconButton(
          tooltip: localeProvider.t('back'),
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.textSecondary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(localeProvider.t('messages'), style: TextStyle(color: AppColors.textPrimary(context), fontSize: 17, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            tooltip: localeProvider.t('new_chat'),
            icon: Icon(LucideIcons.edit, color: AppColors.accent, size: 20),
            onPressed: () => _showNewChatOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(context),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.provider.matrix,
              builder: (context, _) {
                final rooms = _filteredRooms;
                if (rooms.isEmpty) {
                  return _buildEmptyState(context);
                }
                return ListView.builder(
                  itemCount: rooms.length,
                  itemBuilder: (context, index) => _buildChatTile(context, rooms[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatOptions(context),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.bg(context),
        child: const Icon(LucideIcons.messageSquarePlus, size: 22),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      color: AppColors.sf(context),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.bg(context),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(LucideIcons.search, size: 16, color: AppColors.textHint(context)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                style: TextStyle(color: AppColors.textPrimary(context), fontSize: 14),
                decoration: InputDecoration(
                  labelText:  localeProvider.t('search_messages'),
                  hintStyle: TextStyle(color: AppColors.textDisabled(context), fontSize: 14),
                  border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, Room room) {
    final displayName = room.getLocalizedDisplayname();
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final isDirect = room.isDirectChat;
    final lastEvent = room.lastEvent;
    final lastMessage = lastEvent?.plaintextBody ?? '';
    final time = lastEvent?.originServerTs;
    final timeStr = time != null ? _formatTime(time) : '';
    final unreadCount = room.notificationCount;
    final isEncrypted = room.encrypted;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        border: Border(bottom: BorderSide(color: AppColors.divider(context), width: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isDirect ? AppColors.accBg(context) : AppColors.sfActive(context),
              child: isDirect
                  ? Text(initial, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 18))
                  : Icon(LucideIcons.users, size: 20, color: AppColors.textSecondary(context)),
            ),
            if (isEncrypted)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.sf(context),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(LucideIcons.shieldCheck, size: 10, color: AppColors.accent),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(displayName, style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.w500, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (timeStr.isNotEmpty)
              Text(timeStr, style: TextStyle(color: unreadCount > 0 ? AppColors.accent : AppColors.textDisabled(context), fontSize: 11)),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.mut(context), fontSize: 13)),
            ),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
                child: Text('$unreadCount', style: TextStyle(color: AppColors.bg(context), fontSize: 10, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        onTap: () {
          widget.provider.matrix.setActiveRoom(room.id);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FriendProfileView(provider: widget.provider, roomId: room.id)),
          );
        },
        onLongPress: () => _showChatOptions(context, room),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.messageSquare, size: 56, color: AppColors.textDisabled(context)),
          const SizedBox(height: 16),
          Text(localeProvider.t('no_chats'), style: TextStyle(color: AppColors.textHint(context), fontWeight: FontWeight.w500, fontSize: 16)),
          const SizedBox(height: 4),
          Text(localeProvider.t('start_new_chat_hint'), style: TextStyle(color: AppColors.textDisabled(context), fontSize: 13)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _showNewChatOptions(context),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.bg(context), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(localeProvider.t('new_chat'), style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showNewChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.sf(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider(context), borderRadius: BorderRadius.circular(2))),
            ),
            ListTile(
              leading: CircleAvatar(backgroundColor: AppColors.accBg(context), child: Icon(LucideIcons.userPlus, color: AppColors.accent, size: 20)),
              title: Text(localeProvider.t('add_contact'), style: TextStyle(color: AppColors.textPrimary(context))),
              onTap: () {
                Navigator.pop(ctx);
                AppNavigator.go(context, '/add-friend');
              },
            ),
            ListTile(
              leading: CircleAvatar(backgroundColor: AppColors.accBg(context), child: Icon(LucideIcons.users, color: AppColors.accent, size: 20)),
              title: Text(localeProvider.t('new_group'), style: TextStyle(color: AppColors.textPrimary(context))),
              onTap: () {
                Navigator.pop(ctx);
                _showCreateGroup(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showCreateGroup(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        title: Text(localeProvider.t('new_group'), style: TextStyle(color: AppColors.textPrimary(context))),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: AppColors.textPrimary(context)),
          decoration: InputDecoration(
            labelText:  localeProvider.t('group_name'),
            hintStyle: TextStyle(color: AppColors.textDisabled(context)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.divider(context))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(localeProvider.t('cancel'), style: TextStyle(color: AppColors.mut(context)))),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final roomId = await widget.provider.matrix.createGroupChat(name);
                widget.provider.matrix.setActiveRoom(roomId);
              } catch (e) {
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.isEmpty ? localeProvider.t('error') : '$e'), backgroundColor: AppColors.dng(context)));
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.bg(context)),
            child: Text(localeProvider.t('create')),
          ),
        ],
      ),
    );
  }

  void _showChatOptions(BuildContext context, Room room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.sf(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: const EdgeInsets.all(16), child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider(context), borderRadius: BorderRadius.circular(2)))),
            ListTile(
              leading: Icon(LucideIcons.pin, color: AppColors.textSecondary(context)),
              title: Text(localeProvider.t('pin_chat'), style: TextStyle(color: AppColors.textPrimary(context))),
              onTap: () {
                Navigator.pop(ctx);
                widget.provider.session.togglePinSession(widget.provider.session.activeSessionId ?? '');
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.bellOff, color: AppColors.textSecondary(context)),
              title: Text(localeProvider.t('mute'), style: TextStyle(color: AppColors.textPrimary(context))),
              onTap: () {
                Navigator.pop(ctx);
                widget.provider.session.toggleMuteSession(widget.provider.session.activeSessionId ?? '');
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.archive, color: AppColors.textSecondary(context)),
              title: Text(localeProvider.t('archive'), style: TextStyle(color: AppColors.textPrimary(context))),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: Icon(LucideIcons.trash2, color: AppColors.dng(context)),
              title: Text(localeProvider.t('delete_chat'), style: TextStyle(color: AppColors.dng(context))),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(context: context, builder: (_) => AlertDialog(
                  backgroundColor: AppColors.sf(context), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text(localeProvider.t('delete_chat'), style: TextStyle(color: AppColors.textPrimary(context))),
                  content: Text(localeProvider.t('delete_chat_confirm'), style: TextStyle(color: AppColors.textSecondary(context))),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: Text(localeProvider.t('cancel'))),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.dng(context)),
                      onPressed: () { Navigator.pop(context); room.leave(); },
                      child: Text(localeProvider.t('delete')),
                    ),
                  ],
                ));
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return localeProvider.t('just_now');
    if (diff.inHours < 1) return '${diff.inMinutes}${localeProvider.t('minutes_ago')}';
    if (diff.inDays == 0) return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 1) return localeProvider.t('yesterday');
    if (diff.inDays < 7) return '${diff.inDays}${localeProvider.t('days_ago')}';
    return '${dt.month}/${dt.day}';
  }
}
