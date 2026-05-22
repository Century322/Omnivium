import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/quick_command_service.dart';
import '../../core/quick_command_provider.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';

class QuickCommandsView extends StatefulWidget {
  final QuickCommandProvider provider;
  const QuickCommandsView({super.key, required this.provider});

  @override
  State<QuickCommandsView> createState() => _QuickCommandsViewState();
}

class _QuickCommandsViewState extends State<QuickCommandsView>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  String t(String key) => localeProvider.t(key);

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: localeProvider.t('back'),
          icon: Icon(
            LucideIcons.chevronLeft,
            color: AppColors.textPrimary(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t('quick_commands'),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              LucideIcons.moreVertical,
              color: AppColors.textSecondary(context),
              size: 20,
            ),
            color: AppColors.sf(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) async {
              if (value == 'reset') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.sf(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      t('reset_commands'),
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontSize: 16,
                      ),
                    ),
                    content: Text(
                      t('reset_commands_confirm'),
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 14,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(t('cancel')),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          t('confirm'),
                          style: TextStyle(color: AppColors.accent),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await widget.provider.resetToDefaults();
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'reset',
                child: Text(
                  t('reset_commands'),
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: ListenableBuilder(
          listenable: widget.provider,
          builder: (context, _) {
            final commands = widget.provider.commands;
            if (commands.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.zapOff,
                      size: 48,
                      color: AppColors.iconGray(context),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t('no_quick_commands'),
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              proxyDecorator: (child, index, animation) =>
                  Material(color: Colors.transparent, child: child),
              itemCount: commands.length,
              onReorder: (oldIndex, newIndex) {
                widget.provider.reorderCommands(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final cmd = commands[index];
                return _buildCommandTile(cmd, index);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context),
        backgroundColor: AppColors.accent,
        child: Icon(
          LucideIcons.plus,
          color: AppColors.textPrimary(context),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildCommandTile(QuickCommand cmd, int index) {
    return Container(
      key: ValueKey(cmd.id),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.sfAlt(context),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(cmd.emoji, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(
          cmd.name,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          cmd.prompt,
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: localeProvider.t('edit'),
              icon: Icon(
                LucideIcons.pencil,
                size: 16,
                color: AppColors.textSecondary(context),
              ),
              onPressed: () => _showEditDialog(context, existing: cmd),
            ),
            IconButton(
              tooltip: localeProvider.t('delete'),
              icon: Icon(
                LucideIcons.trash2,
                size: 16,
                color: AppColors.dng(context).withValues(alpha: 0.7),
              ),
              onPressed: () => _deleteCommand(cmd),
            ),
            Icon(
              LucideIcons.gripVertical,
              size: 18,
              color: AppColors.iconGray(context),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCommand(QuickCommand cmd) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('delete_command'),
          style: TextStyle(color: AppColors.textPrimary(context), fontSize: 16),
        ),
        content: Text(
          t('delete_command_confirm'),
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              t('delete'),
              style: TextStyle(color: AppColors.dng(context)),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.provider.deleteCommand(cmd.id);
    }
  }

  void _showEditDialog(BuildContext context, {QuickCommand? existing}) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final emojiCtrl = TextEditingController(text: existing?.emoji ?? '?');
    final promptCtrl = TextEditingController(text: existing?.prompt ?? '');
    String selectedCategory = existing?.category ?? 'general';

    final emojiOptions = [
      '??',
      '??',
      '??',
      '??',
      '??',
      '??',
      '?',
      '??',
      '??',
      '??',
      '??',
      '??',
      '??',
      '??',
      '?',
      '??',
    ];
    final categoryOptions = [
      ('general', t('category_general')),
      ('tool', t('category_tool')),
      ('creative', t('category_creative')),
      ('work', t('category_work')),
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.sf(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                isEdit ? t('edit_command') : t('add_command'),
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('command_emoji'),
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: emojiOptions.map((emoji) {
                          final isSelected = emojiCtrl.text == emoji;
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              emojiCtrl.text = emoji;
                              setDialogState(() {});
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.accent.withValues(alpha: 0.15)
                                    : AppColors.sfAlt(context),
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected
                                    ? Border.all(
                                        color: AppColors.accent,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t('command_name'),
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameCtrl,
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          labelText: t('command_name_hint'),
                          hintStyle: TextStyle(
                            color: AppColors.textDisabled(context),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: AppColors.sfAlt(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t('command_prompt'),
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: promptCtrl,
                        maxLines: 3,
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          labelText: t('command_prompt_hint'),
                          hintStyle: TextStyle(
                            color: AppColors.textDisabled(context),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: AppColors.sfAlt(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t('command_category'),
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: categoryOptions.map((opt) {
                          final (value, label) = opt;
                          final isSelected = selectedCategory == value;
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              selectedCategory = value;
                              setDialogState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.accent.withValues(alpha: 0.15)
                                    : AppColors.sfAlt(context),
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected
                                    ? Border.all(
                                        color: AppColors.accent,
                                        width: 1.5,
                                      )
                                    : null,
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.accent
                                      : AppColors.textSecondary(context),
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(t('cancel')),
                ),
                TextButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final emoji = emojiCtrl.text.trim();
                    final prompt = promptCtrl.text.trim();
                    if (name.isEmpty || prompt.isEmpty) return;

                    final now = DateTime.now();
                    if (isEdit) {
                      final updated = existing.copyWith(
                        name: name,
                        emoji: emoji,
                        prompt: prompt,
                        category: selectedCategory,
                      );
                      await widget.provider.updateCommand(updated);
                    } else {
                      final cmd = QuickCommand(
                        id: 'qc_${now.millisecondsSinceEpoch}',
                        name: name,
                        emoji: emoji.isEmpty ? '?' : emoji,
                        prompt: prompt,
                        category: selectedCategory,
                        createdAt: now,
                        updatedAt: now,
                      );
                      await widget.provider.addCommand(cmd);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(
                    isEdit ? t('save') : t('create'),
                    style: TextStyle(color: AppColors.accent),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
