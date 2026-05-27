import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/agent/agent_orchestrator.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';

class AgentReplayView extends StatelessWidget {
  final AgentOrchestrator orchestrator;
  const AgentReplayView({super.key, required this.orchestrator});

  @override
  Widget build(BuildContext context) {
    final logs = orchestrator.executionLogs;
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
          localeProvider.t('agent_replay'),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: logs.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.bot,
                    size: 48,
                    color: AppColors.iconGray(context),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    localeProvider.t('no_agent_logs'),
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return _buildLogCard(context, log, index);
              },
            ),
    );
  }

  Widget _buildLogCard(BuildContext context, AgentLogEntry log, int index) {
    final isSuccess = log.success == true;
    final isRunning = log.isRunning;
    final statusColor = isRunning
        ? AppColors.warn(context)
        : isSuccess
        ? AppColors.ok(context)
        : AppColors.dng(context);

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
            child: isRunning
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: statusColor,
                    ),
                  )
                : Icon(
                    isSuccess ? LucideIcons.checkCircle2 : LucideIcons.xCircle,
                    size: 18,
                    color: statusColor,
                  ),
          ),
          title: Text(
            log.skillName,
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Row(
            children: [
              Text(
                '${log.duration.inMilliseconds}ms',
                style: TextStyle(
                  color: AppColors.textTertiary(context),
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTime(log.startTime),
                style: TextStyle(
                  color: AppColors.textDisabled(context),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          children: [
            _buildSection(
              context,
              localeProvider.t('input'),
              log.input,
              LucideIcons.arrowRight,
              AppColors.acc(context),
            ),
            if (log.output case final output?)
              _buildSection(
                context,
                localeProvider.t('output'),
                output,
                LucideIcons.arrowLeft,
                AppColors.ok(context),
              ),
            if (log.error case final err?)
              _buildSection(
                context,
                localeProvider.t('error'),
                err,
                LucideIcons.alertTriangle,
                AppColors.dng(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String label,
    String content,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
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
              content,
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}
