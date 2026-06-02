import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/di/app_di.dart';
import '../../../core/matrix/matrix_cubit.dart';
import '../../theme/app_colors.dart';
import '../../theme/locale_cubit.dart';

class ForwardSheet extends StatefulWidget {
  final String messageContent;
  final String fromRoomId;

  const ForwardSheet({
    super.key,
    required this.messageContent,
    required this.fromRoomId,
  });

  @override
  State<ForwardSheet> createState() => _ForwardSheetState();
}

class _ForwardSheetState extends State<ForwardSheet> {
  String _query = '';
  List<Room> _rooms = [];

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  void _loadRooms() {
    try {
      final matrix = getIt<MatrixCubit>();
      _rooms = matrix.rooms
          .where((r) => r.id != widget.fromRoomId)
          .toList();
    } catch (_) {}
  }

  List<Room> get _filtered {
    if (_query.isEmpty) return _rooms;
    final lower = _query.toLowerCase();
    return _rooms.where((r) =>
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  localeProvider.t('forward_message'),
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.sf(context),
                borderRadius: BorderRadius.circular(12),
              ),
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
                      horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
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
                          color: AppColors.textPrimary(context), fontSize: 16),
                    ),
                  ),
                  title: Text(
                    room.displayName ?? '',
                    style: TextStyle(
                        color: AppColors.textPrimary(context), fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.pop(context, room.id);
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
