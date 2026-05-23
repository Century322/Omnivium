import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:matrix/matrix.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';
import '../widgets/skeleton_loader.dart';
import '../../core/app_provider.dart';
import '../../core/app_navigator.dart';
import 'add_friend_view.dart';

class ContactsView extends StatefulWidget {
  final AppProvider provider;
  const ContactsView({super.key, required this.provider});

  @override
  State<ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView> {
  String _searchQuery = '';
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

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
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.sf(context),
        elevation: 0,
        leading: IconButton(
          tooltip: localeProvider.t('back'),
          icon: Icon(
            LucideIcons.arrowLeft,
            color: AppColors.textSecondary(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          localeProvider.t('contacts'),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: localeProvider.t('add_contact'),
            icon: Icon(LucideIcons.userPlus, color: AppColors.acc(context), size: 20),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddFriendView(provider: widget.provider),
                ),
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
                final client = widget.provider.matrix.client;
                final isLoggedIn = client != null && client.isLogged();
                if (!isLoggedIn) {
                  return _buildErrorState(
                    context,
                    localeProvider.t('connection_error'),
                    () => setState(() {}),
                  );
                }
                if (directChats.isEmpty && groupChats.isEmpty) {
                  final isSyncing = client.prevBatch == null;
                  if (isSyncing) {
                    return const SkeletonLoader();
                  }
                  return _buildEmptyState(context);
                }
                final items = <dynamic>[
                  if (directChats.isNotEmpty) ...[
                    '_header_direct',
                    ...directChats,
                  ],
                  if (groupChats.isNotEmpty) ...[
                    '_header_group',
                    ...groupChats,
                  ],
                ];
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item == '_header_direct')
                      return _buildSectionHeader(
                        context,
                        localeProvider.t('direct_chats'),
                        directChats.length,
                      );
                    if (item == '_header_group')
                      return _buildSectionHeader(
                        context,
                        localeProvider.t('group_chats'),
                        groupChats.length,
                      );
                    final room = item as Room;
                    return _buildContactTile(
                      context,
                      room,
                      isDirect: directChats.contains(room),
                    );
                  },
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
      child: AnimatedBuilder(
        animation: Listenable.merge([_searchFocus]),
        builder: (context, _) {
          final isFocused = _searchFocus.hasFocus;
          return Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.bg(context),
              borderRadius: BorderRadius.circular(20),
              border: isFocused ? Border.all(color: AppColors.acc(context)) : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(
                  LucideIcons.search,
                  size: 16,
                  color: isFocused
                      ? AppColors.acc(context)
                      : AppColors.textHint(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    focusNode: _searchFocus,
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      labelText: localeProvider.t('search_id'),
                      hintStyle: TextStyle(
                        color: AppColors.textDisabled(context),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.mut(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '($count)',
            style: TextStyle(
              color: AppColors.textDisabled(context),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(
    BuildContext context,
    Room room, {
    required bool isDirect,
  }) {
    final displayName = room.getLocalizedDisplayname();
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final lastEvent = room.lastEvent;
    final lastMessage = lastEvent?.plaintextBody ?? '';
    final time = lastEvent?.originServerTs;
    final timeStr = time != null ? _formatTime(time) : '';

    return Semantics(
      button: true,
      label:
          '$displayName${lastMessage.isNotEmpty ? ', $lastMessage' : ''}${timeStr.isNotEmpty ? ', $timeStr' : ''}',
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDirect
              ? AppColors.accBg(context)
              : AppColors.sfActive(context),
          child: isDirect
              ? Text(
                  initial,
                  style: TextStyle(
                    color: AppColors.acc(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                )
              : Icon(
                  LucideIcons.users,
                  size: 18,
                  color: AppColors.textSecondary(context),
                ),
        ),
        title: Text(
          displayName,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        subtitle: lastMessage.isNotEmpty
            ? Text(
                lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.mut(context), fontSize: 13),
              )
            : null,
        trailing: timeStr.isNotEmpty
            ? Text(
                timeStr,
                style: TextStyle(
                  color: AppColors.textDisabled(context),
                  fontSize: 11,
                ),
              )
            : null,
        onTap: () {
          AppNavigator.go(context, '/chat', args: {'roomId': room.id});
        },
        onLongPress: () => _showContactOptions(context, room),
      ),
    );
  }

  void _showContactOptions(BuildContext context, Room room) {
    final t = localeProvider.t;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.sf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                LucideIcons.messageCircle,
                color: AppColors.sec(context),
              ),
              title: Text(
                t('open_chat'),
                style: TextStyle(color: AppColors.textPrimary(context)),
              ),
              onTap: () {
                Navigator.pop(context);
                AppNavigator.go(context, '/chat', args: {'roomId': room.id});
              },
            ),
            ListTile(
              leading: Icon(
                LucideIcons.bellOff,
                color: AppColors.textSecondary(context),
              ),
              title: Text(
                t('mute'),
                style: TextStyle(color: AppColors.textPrimary(context)),
              ),
              onTap: () {
                Navigator.pop(context);
                room.setPushRuleState(PushRuleState.dontNotify);
              },
            ),
            if (!room.isDirectChat)
              ListTile(
                leading: Icon(
                  LucideIcons.logOut,
                  color: AppColors.dng(context),
                ),
                title: Text(
                  t('leave_group'),
                  style: TextStyle(color: AppColors.dng(context)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.sf(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        t('leave_group'),
                        style: TextStyle(color: AppColors.textPrimary(context)),
                      ),
                      content: Text(
                        t('leave_group_confirm'),
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(t('cancel')),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.dng(context),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            room.leave();
                          },
                          child: Text(t('leave')),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          children: [
            Icon(
              LucideIcons.users,
              size: 48,
              color: AppColors.textDisabled(context),
            ),
            const SizedBox(height: 16),
            Text(
              localeProvider.t('no_chats'),
              style: TextStyle(
                color: AppColors.textHint(context),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              localeProvider.t('add_contact_hint'),
              style: TextStyle(
                color: AppColors.textDisabled(context),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    String message,
    VoidCallback onRetry,
  ) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          children: [
            Icon(
              LucideIcons.wifiOff,
              size: 48,
              color: AppColors.textDisabled(context),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: AppColors.textHint(context),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(localeProvider.t('retry')),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.acc(context),
                foregroundColor: Colors.white,
              ),
            ),
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
      return localeProvider
          .t('days_ago')
          .replaceAll('{n}', diff.inDays.toString());
    } else {
      return '${dt.month}/${dt.day}';
    }
  }
}
