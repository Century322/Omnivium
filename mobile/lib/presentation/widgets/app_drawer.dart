import 'package:flutter/material.dart';
import '../utils/format_utils.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';
import '../../core/app_provider.dart';
import '../../core/session_provider.dart';
import '../views/my_id_view.dart';
import 'incognito_icon.dart';

class AppDrawer extends StatefulWidget {
  final AppProvider provider;
  final VoidCallback onClose;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenSettings;

  const AppDrawer({
    super.key,
    required this.provider,
    required this.onClose,
    required this.onOpenNotifications,
    required this.onOpenSettings,
  });

  @override
  State<AppDrawer> createState() => AppDrawerState();
}

class AppDrawerState extends State<AppDrawer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slide = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void close() {
    _controller.reverse().then((_) {
      if (mounted) widget.onClose();
    });
  }



  void _showProfile() {
    close();
    Navigator.push(context, MaterialPageRoute(builder: (_) => MyIdView(provider: widget.provider)));
  }

  void _showSessionContextMenu(ConversationSession session) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.sf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(session.title, style: TextStyle(color: AppColors.textPrimary(context), fontSize: 16, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            ListTile(
              leading: Icon(LucideIcons.pencil, color: AppColors.sec(context), size: 18),
              title: Text(localeProvider.t('rename'), style: TextStyle(color: AppColors.textSecondary(context), fontSize: 15)),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(session);
              },
            ),
            if (!session.isArchived)
              ListTile(
                leading: Icon(LucideIcons.archive, color: AppColors.sec(context), size: 18),
                title: Text(localeProvider.t('archive'), style: TextStyle(color: AppColors.textSecondary(context), fontSize: 15)),
                onTap: () {
                  widget.provider.session.archiveSession(session.id);
                  Navigator.pop(context);
                },
              ),
            if (session.isArchived)
              ListTile(
                leading: Icon(LucideIcons.archiveRestore, color: AppColors.sec(context), size: 18),
                title: Text(localeProvider.t('unarchive'), style: TextStyle(color: AppColors.textSecondary(context), fontSize: 15)),
                onTap: () {
                  widget.provider.session.unarchiveSession(session.id);
                  Navigator.pop(context);
                },
              ),
            ListTile(
              leading: Icon(LucideIcons.trash2, color: AppColors.dng(context), size: 18),
              title: Text(localeProvider.t('delete'), style: TextStyle(color: AppColors.dng(context), fontSize: 15)),
              onTap: () {
                widget.provider.session.deleteSession(session.id);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(ConversationSession session) {
    final controller = TextEditingController(text: session.title);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(localeProvider.t('rename_conversation'), style: TextStyle(color: AppColors.textPrimary(context))),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AppColors.textPrimary(context)),
          decoration: InputDecoration(
            labelText:  localeProvider.t('enter_new_name'),
            hintStyle: TextStyle(color: AppColors.textDisabled(context)),
            filled: true,
            fillColor: AppColors.sfAlt(context),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localeProvider.t('cancel'), style: TextStyle(color: AppColors.sec(context))),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                widget.provider.session.updateSessionTitle(session.id, controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: Text(localeProvider.t('ok'), style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar({required double size, required double radius}) {
    final userId = widget.provider.matrix.userId ?? '';
    final cleaned = userId.replaceAll('@', '');
    final letter = cleaned.isNotEmpty ? cleaned.substring(0, 1).toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: Text(letter, style: TextStyle(color: AppColors.accent, fontSize: size * 0.4, fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = (screenWidth * 0.85).clamp(0.0, 360.0);

    return Stack(children: [
      FadeTransition(
          opacity: _fade,
          child: GestureDetector(
              onTap: close,
              child: Container(color: AppColors.bg(context).withValues(alpha: 0.6)))),
      SlideTransition(
          position: _slide,
          child: Container(
            width: drawerWidth,
            decoration: BoxDecoration(
              color: AppColors.bg(context),
              borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
            ),
            child: SafeArea(
              right: false,
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Semantics(
                      button: true,
                      label: localeProvider.t('my_profile'),
                      child: GestureDetector(
                      onTap: _showProfile,
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(color: AppColors.sfAlt(context), borderRadius: BorderRadius.circular(16)),
                        child: widget.provider.navigation.isIncognito
                            ? Center(child: IncognitoIcon(size: 18, color: AppColors.textPrimary(context)))
                            : _buildUserAvatar(size: 32, radius: 16),
                      ),
                    )),
                    const SizedBox(width: 12),
                    Semantics(label: localeProvider.t('user_profile'), child: GestureDetector(
                      onTap: _showProfile,
                      child: Text(
                          widget.provider.matrix.isLoggedIn
                              ? (widget.provider.matrix.userId?.split(':').first.replaceAll('@', '') ?? localeProvider.t('user'))
                              : localeProvider.t('user'),
                          style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.w500, fontSize: 15)),
                    )),
                    const Spacer(),
                    ListenableBuilder(
                      listenable: widget.provider.notification,
                      builder: (context, _) {
                        final unread = widget.provider.notification.unreadCount;
                        return Semantics(label: localeProvider.t('notifications'), child: GestureDetector(
                          onTap: widget.onOpenNotifications,
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(color: AppColors.sfAlt(context), borderRadius: BorderRadius.circular(16)),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(LucideIcons.bell, size: 18, color: AppColors.sec(context)),
                                if (unread > 0)
                                  Positioned(
                                    right: 2, top: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(6)),
                                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                                      child: Text('$unread', style: TextStyle(color: AppColors.textPrimary(context), fontSize: 7, fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ));
                      },
                    ),
                    const SizedBox(width: 8),
                    Semantics(label: localeProvider.t('settings'), child: GestureDetector(
                        onTap: widget.onOpenSettings,
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: AppColors.sfAlt(context), borderRadius: BorderRadius.circular(16)),
                          child: Icon(LucideIcons.settings, size: 18, color: AppColors.sec(context)),
                        ))),
                    const SizedBox(width: 12),
                    Semantics(label: localeProvider.t('close_drawer'), child: GestureDetector(
                        onTap: close,
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: AppColors.sfAlt(context), borderRadius: BorderRadius.circular(16)),
                          child: Icon(LucideIcons.arrowLeft, size: 18, color: AppColors.sec(context)),
                        ))),
                  ])),
                Expanded(
                  child: ListenableBuilder(
                    listenable: widget.provider.session,
                    builder: (context, _) {
                      final sessions = widget.provider.session.sessions;
                      final archived = widget.provider.session.archivedSessions;
                      final activeId = widget.provider.session.activeSessionId;
                      return Column(
                        children: [
                          Expanded(
                            child: sessions.isEmpty && archived.isEmpty
                                ? Center(child: Text(localeProvider.t('no_conversations'), style: TextStyle(color: AppColors.textDisabled(context), fontSize: 14)))
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    itemCount: sessions.length + (archived.isNotEmpty ? 1 + archived.length : 0),
                                    itemBuilder: (context, i) {
                                      if (archived.isNotEmpty && i == sessions.length) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Text(localeProvider.t('archived'), style: TextStyle(color: AppColors.textDisabled(context), fontSize: 12, fontWeight: FontWeight.w500)),
                                        );
                                      }
                                      final list = i < sessions.length ? sessions : archived;
                                      final idx = i < sessions.length ? i : i - sessions.length - 1;
                                      final s = list[idx];
                                      final isActive = s.id == activeId;
                                      return GestureDetector(
                                        onLongPress: () => _showSessionContextMenu(s),
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 4),
                                          decoration: BoxDecoration(
                                            color: isActive ? AppColors.sfActive(context) : Colors.transparent,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: ListTile(
                                            dense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                            title: Text(s.title,
                                                style: TextStyle(color: isActive ? AppColors.textPrimary(context) : AppColors.textSecondary(context), fontSize: 14, fontWeight: FontWeight.w500),
                                                maxLines: 1, overflow: TextOverflow.ellipsis),
                                            subtitle: Text(formatRelativeTime(s.lastActiveAt), style: TextStyle(color: AppColors.textDisabled(context), fontSize: 11)),
                                            onTap: () {
                                              if (s.isArchived) {
                                                widget.provider.session.unarchiveSession(s.id);
                                              }
                                              widget.provider.session.switchSession(s.id);
                                              close();
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ]),
            ),
          ),
          ),
    ]);
  }
}
