import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/audit_log_service.dart';
import '../../core/runtime/sdk/omnivium_sdk.dart';
import '../../core/runtime/event_bus.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';

class AiOperationLogView extends StatefulWidget {
  const AiOperationLogView({super.key});

  @override
  State<AiOperationLogView> createState() => _AiOperationLogViewState();
}

class _AiOperationLogViewState extends State<AiOperationLogView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AuditLogEntry> _entries = [];
  Map<String, dynamic> _summary = {};
  EventSubscription? _eventSub;
  String t(String key) => localeProvider.t(key);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _subscribeToEvents();
  }

  @override
  void dispose() {
    if (_eventSub != null) {
      OmniviumSDK.instance.container.eventBus.unsubscribe(_eventSub!.id);
    }
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    _entries = AuditLogService.instance.getRecentEntries();
    _summary = AuditLogService.instance.getSummary();
  }

  void _subscribeToEvents() {
    final sdk = OmniviumSDK.instance;
    if (!sdk.isInitialized) return;
    _eventSub = sdk.container.eventBus.subscribe('audit', (_) async {
      if (!mounted) return;
      setState(() {
        _entries = AuditLogService.instance.getRecentEntries();
        _summary = AuditLogService.instance.getSummary();
      });
    });
  }

  List<AuditLogEntry> get _filteredEntries {
    switch (_tabController.index) {
      case 1:
        return _entries
            .where((e) => e.type == 'capability.invoked' || e.type == 'capability.denied')
            .toList();
      case 2:
        return _entries.where((e) => !e.allowed).toList();
      default:
        return _entries;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = localeProvider.t;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: t('back'),
          icon: Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t('ai_operation_log'),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          labelColor: AppColors.acc(context),
          unselectedLabelColor: AppColors.textTertiary(context),
          indicatorColor: AppColors.acc(context),
          tabs: [
            Tab(text: t('all')),
            Tab(text: t('permissions')),
            Tab(text: t('violations')),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSummaryCards(context),
          Expanded(
            child: _filteredEntries.isEmpty
                ? _buildEmpty(context)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredEntries.length,
                    itemBuilder: (context, index) {
                      return _buildLogCard(context, _filteredEntries[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    final total = _summary['totalEntries'] as int? ?? 0;
    final allowed = _summary['allowed'] as int? ?? 0;
    final denied = _summary['denied'] as int? ?? 0;
    final available = _summary['available'] as bool? ?? false;

    if (!available) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _buildStatCard(context, t('total_ops'), total, LucideIcons.activity, AppColors.acc(context)),
          const SizedBox(width: 8),
          _buildStatCard(context, t('allowed'), allowed, LucideIcons.checkCircle2, AppColors.ok(context)),
          const SizedBox(width: 8),
          _buildStatCard(context, t('denied'), denied, LucideIcons.shieldAlert, AppColors.dng(context)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    int value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.sf(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(color: AppColors.textTertiary(context), fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.shieldCheck, size: 48, color: AppColors.iconGray(context)),
          const SizedBox(height: 12),
          Text(
            localeProvider.t('no_operation_logs'),
            style: TextStyle(color: AppColors.textSecondary(context), fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, AuditLogEntry entry) {
    final isAllowed = entry.allowed;
    final statusColor = isAllowed ? AppColors.ok(context) : AppColors.dng(context);
    final statusIcon = isAllowed ? LucideIcons.checkCircle2 : LucideIcons.xCircle;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerTheme: const DividerThemeData(color: Colors.transparent),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusIcon, size: 18, color: statusColor),
          ),
          title: Text(
            entry.operation,
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Row(
            children: [
              Text(
                entry.actor,
                style: TextStyle(color: AppColors.textTertiary(context), fontSize: 11),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTimestamp(entry.timestamp),
                style: TextStyle(color: AppColors.textDisabled(context), fontSize: 11),
              ),
            ],
          ),
          children: [
            _buildDetailRow(context, localeProvider.t('type'), entry.type, LucideIcons.tag, AppColors.acc(context)),
            _buildDetailRow(context, localeProvider.t('actor'), entry.actor, LucideIcons.user, AppColors.acc(context)),
            if (entry.target.isNotEmpty)
              _buildDetailRow(context, localeProvider.t('target'), entry.target, LucideIcons.target, AppColors.sec(context)),
            _buildDetailRow(
              context,
              localeProvider.t('status'),
              isAllowed ? localeProvider.t('allowed') : localeProvider.t('denied'),
              isAllowed ? LucideIcons.check : LucideIcons.ban,
              statusColor,
            ),
            if (entry.details.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(LucideIcons.fileText, size: 12, color: AppColors.textTertiary(context)),
                  const SizedBox(width: 4),
                  Text(
                    localeProvider.t('details'),
                    style: TextStyle(color: AppColors.textTertiary(context), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.sfAlt(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _formatDetails(entry.details),
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  String _formatDetails(Map<String, dynamic> details) {
    final buffer = StringBuffer();
    details.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    return buffer.toString().trimRight();
  }
}
