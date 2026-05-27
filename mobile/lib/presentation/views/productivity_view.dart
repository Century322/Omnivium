import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/note_service.dart';
import '../../core/note_provider.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';

class ProductivityView extends StatefulWidget {
  final NoteProvider provider;
  const ProductivityView({super.key, required this.provider});

  @override
  State<ProductivityView> createState() => _ProductivityViewState();
}

class _ProductivityViewState extends State<ProductivityView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String t(String key) => localeProvider.t(key);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          t('productivity'),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.acc(context),
          unselectedLabelColor: AppColors.textSecondary(context),
          indicatorColor: AppColors.acc(context),
          tabs: [
            Tab(text: t('notes')),
            Tab(text: t('todos')),
            Tab(text: t('schedules')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildNotesList(), _buildTodosList(), _buildSchedulesList()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(_tabController.index),
        backgroundColor: AppColors.acc(context),
        child: Icon(
          LucideIcons.plus,
          color: AppColors.textPrimary(context),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildNotesList() {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) {
        final notes = widget.provider.notes;
        if (notes.isEmpty) {
          return _buildEmptyState(LucideIcons.fileText, t('no_notes'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return _buildNoteCard(note);
          },
        );
      },
    );
  }

  Widget _buildTodosList() {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) {
        final todos = widget.provider.todos;
        if (todos.isEmpty) {
          return _buildEmptyState(LucideIcons.checkSquare, t('no_todos'));
        }
        final pending = todos.where((t) => !t.isDone).toList();
        final done = todos.where((t) => t.isDone).toList();
        final items = <dynamic>[
          if (pending.isNotEmpty) ...['_header_pending', ...pending],
          if (done.isNotEmpty) ...['_header_done', ...done],
        ];
        if (items.isEmpty)
          return Center(
            child: Text(
              t('no_todos'),
              style: TextStyle(color: AppColors.textTertiary(context)),
            ),
          );
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            if (item == '_header_pending')
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  t('pending'),
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            if (item == '_header_done')
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  t('completed'),
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            return _buildTodoCard(item);
          },
        );
      },
    );
  }

  Widget _buildSchedulesList() {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) {
        final schedules = widget.provider.schedules;
        if (schedules.isEmpty) {
          return _buildEmptyState(LucideIcons.calendar, t('no_schedules'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final schedule = schedules[index];
            return _buildScheduleCard(schedule);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.iconGray(context)),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(NoteItem note) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          note.title,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: note.content.isNotEmpty
            ? Text(
                note.content,
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
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
              onPressed: () => _showEditDialog(note),
            ),
            IconButton(
              tooltip: localeProvider.t('delete'),
              icon: Icon(
                LucideIcons.trash2,
                size: 16,
                color: AppColors.dng(context).withValues(alpha: 0.7),
              ),
              onPressed: () => widget.provider.deleteItem(note.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoCard(NoteItem todo) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Semantics(
          label: localeProvider.t('toggle_completion'),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.provider.toggleDone(todo.id),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: todo.isDone
                    ? AppColors.acc(context)
                    : Colors.transparent,
                border: Border.all(
                  color: todo.isDone
                      ? AppColors.acc(context)
                      : AppColors.textSecondary(context),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: todo.isDone
                  ? Icon(
                      LucideIcons.check,
                      size: 14,
                      color: AppColors.textPrimary(context),
                    )
                  : null,
            ),
          ),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            color: todo.isDone
                ? AppColors.textDisabled(context)
                : AppColors.textPrimary(context),
            fontSize: 15,
            fontWeight: FontWeight.w500,
            decoration: todo.isDone ? TextDecoration.lineThrough : null,
          ),
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
              onPressed: () => _showEditTodoDialog(todo),
            ),
            IconButton(
              tooltip: localeProvider.t('delete'),
              icon: Icon(
                LucideIcons.trash2,
                size: 16,
                color: AppColors.dng(context).withValues(alpha: 0.7),
              ),
              onPressed: () => widget.provider.deleteItem(todo.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(NoteItem schedule) {
    final dueDate = schedule.dueDate;
    final isOverdue =
        dueDate != null && dueDate.isBefore(DateTime.now());
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(12),
        border: isOverdue
            ? Border.all(
                color: AppColors.dng(context).withValues(alpha: 0.3),
                width: 1,
              )
            : null,
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isOverdue
                ? AppColors.dng(context).withValues(alpha: 0.1)
                : AppColors.acc(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dueDate != null ? '${dueDate.day}' : '-',
                style: TextStyle(
                  color: isOverdue
                      ? AppColors.dng(context)
                      : AppColors.acc(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                dueDate != null
                    ? _monthShort(dueDate.month)
                    : '',
                style: TextStyle(
                  color: isOverdue
                      ? AppColors.dng(context).withValues(alpha: 0.7)
                      : AppColors.acc(context).withValues(alpha: 0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          schedule.title,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: dueDate != null
            ? Text(
                _formatDateTime(dueDate),
                style: TextStyle(
                  color: isOverdue
                      ? AppColors.dng(context)
                      : AppColors.textSecondary(context),
                  fontSize: 12,
                ),
              )
            : null,
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
              onPressed: () => _showEditScheduleDialog(schedule),
            ),
            IconButton(
              tooltip: localeProvider.t('delete'),
              icon: Icon(
                LucideIcons.trash2,
                size: 16,
                color: AppColors.dng(context).withValues(alpha: 0.7),
              ),
              onPressed: () => widget.provider.deleteItem(schedule.id),
            ),
          ],
        ),
      ),
    );
  }

  String _monthShort(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showAddDialog(int tabIndex) {
    final type = tabIndex == 0
        ? NoteType.text
        : tabIndex == 1
        ? NoteType.todo
        : NoteType.schedule;
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    DateTime? dueDate;
    TimeOfDay? dueTime;

    try {
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
                  tabIndex == 0
                      ? t('add_note')
                      : tabIndex == 1
                      ? t('add_todo')
                      : t('add_schedule'),
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
                        TextField(
                          controller: titleCtrl,
                          maxLength: 200,
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            labelText: t('title_hint'),
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
                        const SizedBox(height: 12),
                        if (type == NoteType.text)
                          TextField(
                            controller: contentCtrl,
                            maxLength: 8192,
                            maxLines: 4,
                            style: TextStyle(
                              color: AppColors.textPrimary(context),
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              labelText: t('content_hint'),
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
                        if (type == NoteType.schedule) ...[
                          const SizedBox(height: 8),
                          Semantics(
                            label: localeProvider.t('select_date'),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (date != null)
                                  setDialogState(() => dueDate = date);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.sfAlt(context),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.calendar,
                                      size: 16,
                                      color: AppColors.textSecondary(context),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      dueDate != null
                                          ? _formatDateTime(dueDate!)
                                          : t('select_date'),
                                      style: TextStyle(
                                        color: dueDate != null
                                            ? AppColors.textPrimary(context)
                                            : AppColors.textDisabled(context),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Semantics(
                            label: localeProvider.t('select_time'),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (time != null)
                                  setDialogState(() => dueTime = time);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.sfAlt(context),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.clock,
                                      size: 16,
                                      color: AppColors.textSecondary(context),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      dueTime != null
                                          ? '${dueTime!.hour.toString().padLeft(2, '0')}:${dueTime!.minute.toString().padLeft(2, '0')}'
                                          : t('select_time'),
                                      style: TextStyle(
                                        color: dueTime != null
                                            ? AppColors.textPrimary(context)
                                            : AppColors.textDisabled(context),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
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
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) return;
                      final now = DateTime.now();
                      DateTime? finalDueDate;
                      if (type == NoteType.schedule && dueDate != null) {
                        finalDueDate = DateTime(
                          dueDate!.year,
                          dueDate!.month,
                          dueDate!.day,
                          dueTime?.hour ?? 0,
                          dueTime?.minute ?? 0,
                        );
                      }
                      final item = NoteItem(
                        id: 'note_${now.millisecondsSinceEpoch}',
                        title: title,
                        content: contentCtrl.text.trim(),
                        type: type,
                        dueDate: finalDueDate,
                        createdAt: now,
                        updatedAt: now,
                      );
                      await widget.provider.addItem(item);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(
                      t('create'),
                      style: TextStyle(color: AppColors.acc(context)),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      titleCtrl.dispose();
      contentCtrl.dispose();
    }
  }

  void _showEditDialog(NoteItem note) {
    final titleCtrl = TextEditingController(text: note.title);
    final contentCtrl = TextEditingController(text: note.content);

    try {
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: AppColors.sf(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              t('edit_note'),
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    maxLength: 200,
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      labelText: t('title_hint'),
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentCtrl,
                    maxLength: 8192,
                    maxLines: 4,
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      labelText: t('content_hint'),
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
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(t('cancel')),
              ),
              TextButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) return;
                  final updated = note.copyWith(
                    title: title,
                    content: contentCtrl.text.trim(),
                  );
                  await widget.provider.updateItem(updated);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(
                  t('save'),
                  style: TextStyle(color: AppColors.acc(context)),
                ),
              ),
            ],
          );
        },
      );
    } finally {
      titleCtrl.dispose();
      contentCtrl.dispose();
    }
  }

  void _showEditTodoDialog(NoteItem todo) {
    final titleCtrl = TextEditingController(text: todo.title);
    try {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.sf(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            localeProvider.t('edit'),
            style: TextStyle(color: AppColors.textPrimary(context)),
          ),
          content: TextField(
            controller: titleCtrl,
            maxLength: 200,
            autofocus: true,
            style: TextStyle(color: AppColors.textPrimary(context)),
            decoration: InputDecoration(hintText: localeProvider.t('title')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localeProvider.t('cancel')),
            ),
            FilledButton(
              onPressed: () {
                widget.provider.updateItem(
                  todo.copyWith(title: titleCtrl.text),
                );
                Navigator.pop(context);
              },
              child: Text(localeProvider.t('save')),
            ),
          ],
        ),
      );
    } finally {
      titleCtrl.dispose();
    }
  }

  void _showEditScheduleDialog(NoteItem schedule) {
    final titleCtrl = TextEditingController(text: schedule.title);
    DateTime? newDate = schedule.dueDate;
    try {
      showDialog(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: AppColors.sf(ctx),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              localeProvider.t('edit'),
              style: TextStyle(color: AppColors.textPrimary(ctx)),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  maxLength: 200,
                  autofocus: true,
                  style: TextStyle(color: AppColors.textPrimary(ctx)),
                  decoration: InputDecoration(
                    hintText: localeProvider.t('title'),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: newDate ?? DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setDialogState(() => newDate = d);
                  },
                  child: Text(
                    newDate != null
                        ? _formatDateTime(newDate!)
                        : localeProvider.t('select_date'),
                    style: TextStyle(color: AppColors.acc(ctx)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(localeProvider.t('cancel')),
              ),
              FilledButton(
                onPressed: () {
                  widget.provider.updateItem(
                    schedule.copyWith(title: titleCtrl.text, dueDate: newDate),
                  );
                  Navigator.pop(ctx);
                },
                child: Text(localeProvider.t('save')),
              ),
            ],
          ),
        ),
      );
    } finally {
      titleCtrl.dispose();
    }
  }
}
