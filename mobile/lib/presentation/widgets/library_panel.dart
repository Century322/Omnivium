import 'package:flutter/material.dart';
import '../utils/format_utils.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';
import '../../core/app_provider.dart';
import '../../core/app_navigator.dart';
import 'home_components.dart';

class LibraryPanel extends StatefulWidget {
  final AppProvider provider;
  final VoidCallback onCreateGroupChat;
  final VoidCallback onAddContact;
  final bool showSearchBar;
  final VoidCallback onToggleSearch;
  final void Function(String id, String name)? onOpenFriendChat;

  const LibraryPanel({
    super.key,
    required this.provider,
    required this.onCreateGroupChat,
    required this.onAddContact,
    required this.showSearchBar,
    required this.onToggleSearch,
    this.onOpenFriendChat,
  });

  @override
  State<LibraryPanel> createState() => _LibraryPanelState();
}

class _LibraryPanelState extends State<LibraryPanel> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onCreateGroupChat,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sf(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider(context)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.users,
                          size: 16,
                          color: AppColors.sec(context),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          localeProvider.t('new_group'),
                          style: TextStyle(
                            color: AppColors.sec(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onAddContact,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sf(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider(context)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.userPlus,
                          size: 16,
                          color: AppColors.sec(context),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          localeProvider.t('add_contact'),
                          style: TextStyle(
                            color: AppColors.sec(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    AppNavigator.go(context, '/contacts');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sf(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider(context)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.contact,
                          size: 16,
                          color: AppColors.sec(context),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          localeProvider.t('contacts'),
                          style: TextStyle(
                            color: AppColors.sec(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.showSearchBar)
          AnimatedBuilder(
            animation: Listenable.merge([_searchFocus]),
            builder: (context, _) {
              final isFocused = _searchFocus.hasFocus;
              return Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.sf(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isFocused
                        ? AppColors.acc(context)
                        : AppColors.divider(context),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  autofocus: true,
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: localeProvider.t('search_id'),
                    hintStyle: TextStyle(
                      color: AppColors.textTertiary(context),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              );
            },
          ),
        Expanded(child: _buildChatList()),
      ],
    );
  }

  Widget _buildChatList() {
    final matrix = widget.provider.matrix;
    if (!matrix.isLoggedIn) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.messageCircle,
              size: 48,
              color: AppColors.textDisabled(context),
            ),
            const SizedBox(height: 16),
            Text(
              localeProvider.t('not_logged_in'),
              style: TextStyle(
                color: AppColors.textTertiary(context),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                await AppNavigator.go(context, '/login');
              },
              child: Text(
                localeProvider.t('go_login'),
                style: TextStyle(
                  color: AppColors.acc(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
    var rooms = matrix.rooms;
    final query = widget.showSearchBar
        ? _searchController.text.toLowerCase()
        : '';
    if (query.isNotEmpty) {
      rooms = rooms.where((r) {
        final name = r.getLocalizedDisplayname().toLowerCase();
        final id = r.id.toLowerCase();
        return name.contains(query) || id.contains(query);
      }).toList();
    }
    if (rooms.isEmpty) {
      return Center(
        child: Text(
          query.isEmpty
              ? localeProvider.t('no_chats')
              : localeProvider.t('no_match_chat'),
          style: TextStyle(
            color: AppColors.textTertiary(context),
            fontSize: 15,
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.acc(context),
      onRefresh: () async {
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: rooms.length,
        itemBuilder: (_, i) {
          final room = rooms[i];
          final lastEvent = room.lastEvent;
          final lastMsg = lastEvent?.body ?? '';
          final time = lastEvent != null
              ? formatRelativeTime(lastEvent.originServerTs)
              : '';
          final name = room.getLocalizedDisplayname();
          return _buildChatItem(ChatItemData(room.id, name, lastMsg, time));
        },
      ),
    );
  }

  Widget _buildChatItem(ChatItemData data) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final room = widget.provider.matrix.client?.getRoomById(data.id);
        if (room != null && room.isDirectChat) {
          widget.onOpenFriendChat?.call(data.id, data.name);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.sf(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.acc(context).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  data.name.isNotEmpty ? data.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: AppColors.acc(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.name,
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (data.lastMsg.isNotEmpty)
                    Text(
                      data.lastMsg,
                      style: TextStyle(
                        color: AppColors.textTertiary(context),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (data.time.isNotEmpty)
              Text(
                data.time,
                style: TextStyle(
                  color: AppColors.textDisabled(context),
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
