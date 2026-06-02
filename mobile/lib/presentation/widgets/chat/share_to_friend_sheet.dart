import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/di/app_di.dart';
import '../../../core/matrix/matrix_cubit.dart';
import '../../theme/app_colors.dart';
import '../../theme/locale_cubit.dart';

class ShareToFriendSheet extends StatefulWidget {
  final String content;
  final String? sourceLabel;

  const ShareToFriendSheet({
    super.key,
    required this.content,
    this.sourceLabel,
  });

  @override
  State<ShareToFriendSheet> createState() => _ShareToFriendSheetState();
}

class _ShareToFriendSheetState extends State<ShareToFriendSheet> {
  String _query = '';

  List<Room> get _rooms {
    try {
      final matrix = getIt<MatrixCubit>();
      return matrix.rooms;
    } catch (_) {
      return [];
    }
  }

  List<Room> get _filtered {
    final rooms = _rooms;
    if (_query.isEmpty) return rooms;
    final lower = _query.toLowerCase();
    return rooms.where((r) =>
        (r.displayName ?? '').toLowerCase().contains(lower)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rooms = _filtered;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  localeProvider.t('share_to_friend'),
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(LucideIcons.x,
                      size: 20, color: AppColors.iconGray(context)),
                ),
              ],
            ),
          ),
          if (widget.sourceLabel != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.sfAlt(context),
                  borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(LucideIcons.quote, size: 14, color: AppColors.sec(context)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.content.length > 100
                            ? '${widget.content.substring(0, 100)}...'
                            : widget.content,
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 13),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis)),
                  ])),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.sf(context),
                borderRadius: BorderRadius.circular(12)),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(
                    color: AppColors.textPrimary(context), fontSize: 15),
                decoration: InputDecoration(
                  hintText: localeProvider.t('search_friends'),
                  hintStyle: TextStyle(color: AppColors.textHint(context)),
                  prefixIcon: Icon(LucideIcons.search,
                      size: 18, color: AppColors.iconGray(context)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10)),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.35),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.sfAlt(context),
                    child: Text(
                      (room.displayName ?? '?')[0].toUpperCase(),
                      style: TextStyle(
                          color: AppColors.textPrimary(context), fontSize: 16)),
                    ),
                  ),
                  title: Text(
                    room.displayName ?? '',
                    style: TextStyle(
                        color: AppColors.textPrimary(context), fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                  onTap: () async {
                    try {
                      await getIt<MatrixCubit>().sendMessage(room.id, widget.content);
                      if (context.mounted) {
                        Navigator.pop(context, true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(localeProvider.t('shared')),
                            backgroundColor: AppColors.ok(context),
                            duration: const Duration(milliseconds: 1500)),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: AppColors.dng(context)),
                        );
                      }
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
