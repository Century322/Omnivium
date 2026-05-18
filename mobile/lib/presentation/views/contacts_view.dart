import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:matrix/matrix.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';
import '../../core/app_provider.dart';
import 'add_friend_view.dart';
import 'friend_profile_view.dart';

class ContactsView extends StatefulWidget {
  final AppProvider provider;
  const ContactsView({super.key, required this.provider});

  @override
  State<ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView> {
  String _searchQuery = '';

  List<Room> get _filteredDirectChats {
    final chats = widget.provider.matrix.directChats;
    if (_searchQuery.isEmpty) return chats;
    return chats.where((room) {
      final name = room.getLocalizedDisplayname().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<Room> get _filteredGroupChats {
    final chats = widget.provider.matrix.groupChats;
    if (_searchQuery.isEmpty) return chats;
    return chats.where((room) {
      final name = room.getLocalizedDisplayname().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final directChats = _filteredDirectChats;
    final groupChats = _filteredGroupChats;

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
        title: Text(localeProvider.t('contacts'), style: TextStyle(color: AppColors.textPrimary(context), fontSize: 17, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            tooltip: localeProvider.t('add_contact'),
            icon: Icon(LucideIcons.userPlus, color: AppColors.accent, size: 20),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddFriendView(provider: widget.provider)),
              );
              if (result != null && result is String && mounted) {
                if (context.mounted) Navigator.pop(context, result);
              }
            },
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
                return ListView(
                  children: [
                    if (directChats.isNotEmpty) ...[
                      _buildSectionHeader(context, localeProvider.t('direct_chats'), directChats.length),
                      ...directChats.map((room) => _buildContactTile(context, room, isDirect: true)),
                    ],
                    if (groupChats.isNotEmpty) ...[
                      _buildSectionHeader(context, localeProvider.t('group_chats'), groupChats.length),
                      ...groupChats.map((room) => _buildContactTile(context, room, isDirect: false)),
                    ],
                    if (directChats.isEmpty && groupChats.isEmpty)
                      _buildEmptyState(context),
                  ],
                );
              },
            ),
          ),
        ],
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
          color: AppColors.background,
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
                  labelText:  localeProvider.t('search_id'),
                  hintStyle: TextStyle(color: AppColors.textDisabled(context), fontSize: 14),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Text(title, style: TextStyle(color: AppColors.mut(context), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(width: 6),
          Text('($count)', style: TextStyle(color: AppColors.textDisabled(context), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildContactTile(BuildContext context, Room room, {required bool isDirect}) {
    final displayName = room.getLocalizedDisplayname();
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final lastEvent = room.lastEvent;
    final lastMessage = lastEvent?.plaintextBody ?? '';
    final time = lastEvent?.originServerTs;
    final timeStr = time != null ? _formatTime(time) : '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isDirect ? AppColors.accBg(context) : AppColors.sfActive(context),
        child: isDirect
            ? Text(initial, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 16))
            : Icon(LucideIcons.users, size: 18, color: AppColors.textSecondary(context)),
      ),
      title: Text(displayName, style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: lastMessage.isNotEmpty
          ? Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.mut(context), fontSize: 13))
          : null,
      trailing: timeStr.isNotEmpty
          ? Text(timeStr, style: TextStyle(color: AppColors.textDisabled(context), fontSize: 11))
          : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FriendProfileView(provider: widget.provider, roomId: room.id)),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          children: [
            Icon(LucideIcons.users, size: 48, color: AppColors.textDisabled(context)),
            const SizedBox(height: 16),
            Text(localeProvider.t('no_chats'), style: TextStyle(color: AppColors.textHint(context), fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(localeProvider.t('add_contact_hint'), style: TextStyle(color: AppColors.textDisabled(context), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return localeProvider.t('yesterday');
    } else if (diff.inDays < 7) {
      return localeProvider.t('days_ago').replaceAll('{n}', diff.inDays.toString());
    } else {
      return '${dt.month}/${dt.day}';
    }
  }
}
