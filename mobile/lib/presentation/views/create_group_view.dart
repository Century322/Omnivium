import 'dart:io' if (dart.library.html) '';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../theme/locale_cubit.dart';
import '../../core/di/app_di.dart';
import '../../core/matrix/matrix_cubit.dart';
import '../../core/matrix/matrix_dtos.dart';
import '../../core/app_logger.dart';


class CreateGroupView extends StatefulWidget { const CreateGroupView({super.key});

  @override
  State<CreateGroupView> createState() => _CreateGroupViewState();
}

class _CreateGroupViewState extends State<CreateGroupView> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final Set<String> _selectedMembers = {};
  String _searchQuery = '';
  String? _avatarPath;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<RoomInfo> get _directChats {
    return getIt<MatrixCubit>().getDirectChats();
  }

  List<RoomInfo> get _filteredChats {
    if (_searchQuery.isEmpty) return _directChats;
    final q = _searchQuery.toLowerCase();
    return _directChats
        .where(
          (r) =>
              r.displayName.toLowerCase().contains(q) ||
              (r.directChatMatrixId?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = localeProvider.t;
    final chats = _filteredChats;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.sec(context)),
          onPressed: () => Navigator.pop(context)),
        title: Text(
          t('new_group'),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed:
                _selectedMembers.isNotEmpty && _nameCtrl.text.trim().isNotEmpty
                ? _createGroup
                : null,
            child: Text(
              t('create'),
              style: TextStyle(
                color:
                    _selectedMembers.isNotEmpty &&
                        _nameCtrl.text.trim().isNotEmpty
                    ? AppColors.acc(context)
                    : AppColors.textDisabled(context),
                fontSize: 15,
                fontWeight: FontWeight.w600))),
        ]),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).padding.bottom + 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildGroupInfoSection(context),
                  const SizedBox(height: 24),
                  if (_selectedMembers.isNotEmpty) ...[
                    _buildSelectedMembersSection(context),
                    const SizedBox(height: 16),
                  ],
                  _buildSearchField(context),
                  const SizedBox(height: 12),
                  _buildMemberList(context, chats),
                  const SizedBox(height: 40),
                ]))),
        ]));
  }

  Widget _buildGroupInfoSection(BuildContext context) {
    final t = localeProvider.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () async {
                final picker = ImagePicker();
                final image = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 512,
                  maxHeight: 512);
                if (image != null && mounted) {
                  setState(() {
                    _avatarPath = image.path;
                  });
                }
              },
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.sfAlt(context),
                  borderRadius: BorderRadius.circular(20),
                  image: _avatarPath != null
                      ? DecorationImage(
                          image: FileImage(File(_avatarPath!)),
                          fit: BoxFit.cover)
                      : null),
                child: _avatarPath == null
                    ? Icon(
                        LucideIcons.camera,
                        size: 24,
                        color: AppColors.iconGray(context))
                    : null)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  TextField(
                    controller: _nameCtrl,
                    maxLength: 100,
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: t('group_name'),
                      filled: true,
                      fillColor: AppColors.sf(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12)),
                    onChanged: (_) => setState(() {})),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descCtrl,
                    maxLength: 512,
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 14),
                    maxLines: 2,
                    minLines: 1,
                    decoration: InputDecoration(
                      labelText: t('group_description'),
                      filled: true,
                      fillColor: AppColors.sf(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10))),
                ])),
          ]),
      ]);
  }

  Widget _buildSelectedMembersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedMembers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final userId = _selectedMembers.elementAt(index);
              final name = userId.split(':').first.replaceAll('@', '');
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.acc(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: AppColors.acc(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() => _selectedMembers.remove(userId));
                      },
                      child: Icon(
                        LucideIcons.x,
                        size: 14,
                        color: AppColors.acc(context))),
                  ]));
            })),
      ]);
  }

  Widget _buildSearchField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: _searchCtrl,
        maxLength: 128,
        style: TextStyle(color: AppColors.textPrimary(context), fontSize: 14),
        decoration: InputDecoration(
          labelText: localeProvider.t('search_friends'),
          prefixIcon: Icon(
            LucideIcons.search,
            size: 18,
            color: AppColors.iconGray(context)),
          filled: true,
          fillColor: AppColors.sf(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10)),
        onChanged: (v) => setState(() => _searchQuery = v.trim())));
  }

  Widget _buildMemberList(BuildContext context, List<RoomInfo> chats) {
    if (chats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            localeProvider.t('no_friends'),
            style: TextStyle(
              color: AppColors.textTertiary(context),
              fontSize: 14))));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${localeProvider.t('members')} (${_selectedMembers.length})',
          style: TextStyle(
            color: AppColors.textHint(context),
            fontSize: 12,
            fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...chats.map((room) {
          final userId = room.directChatMatrixId ?? '';
          if (userId.isEmpty) return const SizedBox.shrink();
          final isSelected = _selectedMembers.contains(userId);
          final name = room.displayName;
          final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedMembers.remove(userId);
                } else {
                  _selectedMembers.add(userId);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.divider(context),
                    width: 0.5))),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.acc(context).withValues(alpha: 0.15)
                          : AppColors.sfAlt(context),
                      borderRadius: BorderRadius.circular(20)),
                    child: Center(
                      child: isSelected
                          ? Icon(
                              LucideIcons.check,
                              size: 20,
                              color: AppColors.acc(context))
                          : Text(
                              initial,
                              style: TextStyle(
                                color: AppColors.sec(context),
                                fontSize: 16,
                                fontWeight: FontWeight.w600)))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w500)),
                        Text(
                          userId,
                          style: TextStyle(
                            color: AppColors.textTertiary(context),
                            fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                      ])),
                  if (isSelected)
                    Icon(
                      LucideIcons.checkCircle2,
                      size: 20,
                      color: AppColors.acc(context)),
                ])));
        }),
      ]);
  }

  Future<void> _createGroup() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _selectedMembers.isEmpty) return;

    final matrix = getIt<MatrixCubit>();
    try {
      final roomId = await matrix.createGroupChat(
        name,
        userIds: _selectedMembers.toList(),
        topic: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim());
      if (_avatarPath != null && roomId != null) {
        try {
          await getIt<MatrixCubit>().setRoomAvatar(roomId, _avatarPath!);
        } catch (e) {
          AppLogger.instance.warning('Failed to upload group avatar', error: e);
        }
      }
      if (mounted) {
        Navigator.pop(context, roomId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.dng(context)));
      }
    }
  }
}
