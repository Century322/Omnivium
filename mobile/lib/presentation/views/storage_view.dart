import '../../core/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';
import '../widgets/skeleton_loader.dart';
import '../../core/app_provider.dart';
import '../../core/app_navigator.dart';
import '../../core/database_service.dart';

class StorageView extends StatefulWidget {
  final AppProvider provider;
  const StorageView({super.key, required this.provider});

  @override
  State<StorageView> createState() => _StorageViewState();
}

class _StorageViewState extends State<StorageView> {
  double _chatDataSize = 0;
  double _aiDataSize = 0;
  double _cacheSize = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _calculateSizes();
  }

  Future<void> _calculateSizes() async {
    double chatData = 0;
    double aiData = 0;
    double cache = 0;

    try {
      final db = DatabaseService.instance;
      if (db.isInitialized) {
        for (final key in db.sessions.keys) {
          final value = db.sessions.get(key);
          if (value != null) chatData += value.length;
        }
        for (final key in db.data.keys) {
          final value = db.data.get(key);
          if (value != null) aiData += value.length;
        }
        for (final key in db.cache.keys) {
          final value = db.cache.get(key);
          if (value != null) cache += value.length;
        }
        for (final key in db.memory.keys) {
          final value = db.memory.get(key);
          if (value != null) cache += value.length;
        }
      }
    } catch (e, stackTrace) { AppLogger.instance.error('Operation failed', error: e, stackTrace: stackTrace); }

    if (mounted) {
      setState(() {
        _chatDataSize = chatData / 1024 / 1024;
        _aiDataSize = aiData / 1024 / 1024;
        _cacheSize = cache / 1024 / 1024;
        _loading = false;
      });
    }
  }

  double get _totalSize => _chatDataSize + _aiDataSize + _cacheSize;

  String _formatSize(double mb) {
    if (mb < 0.01) return '0 MB';
    if (mb < 1) return '${(mb * 1024).toStringAsFixed(1)} KB';
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final t = localeProvider.t;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          tooltip: localeProvider.t('back'),
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.sec(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t('storage'), style: TextStyle(color: AppColors.textPrimary(context), fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: List.generate(6, (_) => const CardSkeleton())))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildOverview(context, t),
                  const SizedBox(height: 24),
                  _buildSection(context, t('chat_data'), [
                    _buildStorageItem(context, LucideIcons.messageCircle, t('chat_messages'), t('chat_messages_desc'), _formatSize(_chatDataSize * 0.6),
                      onTap: () => AppNavigator.go(context, '/files', args: {'tab': 2})),
                    _buildStorageItem(context, LucideIcons.image, t('images'), t('images_desc'), _formatSize(_chatDataSize * 0.25),
                      onTap: () => AppNavigator.go(context, '/files', args: {'tab': 0})),
                    _buildStorageItem(context, LucideIcons.file, t('files'), t('files_desc'), _formatSize(_chatDataSize * 0.15),
                      onTap: () => AppNavigator.go(context, '/files', args: {'tab': 2})),
                    _buildStorageItem(context, LucideIcons.video, t('videos'), t('videos_desc'), '0 MB',
                      onTap: () => AppNavigator.go(context, '/files', args: {'tab': 1})),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection(context, t('ai_data'), [
                    _buildStorageItem(context, LucideIcons.bot, t('ai_conversations'), t('ai_conversations_desc'), _formatSize(_aiDataSize * 0.8)),
                    _buildStorageItem(context, LucideIcons.image, t('ai_generated_images'), t('ai_generated_images_desc'), _formatSize(_aiDataSize * 0.2)),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection(context, t('cache'), [
                    _buildStorageItem(context, LucideIcons.database, t('matrix_cache'), t('matrix_cache_desc'), _formatSize(_cacheSize * 0.7)),
                    _buildStorageItem(context, LucideIcons.globe, t('web_cache'), t('web_cache_desc'), _formatSize(_cacheSize * 0.3)),
                  ]),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.dng(context).withValues(alpha: 0.15),
                        foregroundColor: AppColors.dng(context),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () => _showClearCacheDialog(context, t),
                      child: Text(t('clear_cache'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildOverview(BuildContext context, String Function(String) t) {
    final totalMB = _totalSize;
    final maxMB = 1024.0;
    final progress = (totalMB / maxMB).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.sf(context), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Text(t('storage_used'), style: TextStyle(color: AppColors.textHint(context), fontSize: 13)),
        const SizedBox(height: 8),
        Text(_formatSize(totalMB), style: TextStyle(color: AppColors.textPrimary(context), fontSize: 32, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: progress, backgroundColor: AppColors.sfAlt(context), valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent), minHeight: 8)),
        const SizedBox(height: 8),
        Text('${t('total_used')} / ${_formatSize(maxMB)}', style: TextStyle(color: AppColors.iconGray(context), fontSize: 12)),
      ]),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title, style: TextStyle(color: AppColors.iconGray(context), fontSize: 13, fontWeight: FontWeight.w600))),
      Container(decoration: BoxDecoration(color: AppColors.sf(context), borderRadius: BorderRadius.circular(14)),
        child: Column(children: children)),
    ]);
  }

  Widget _buildStorageItem(BuildContext context, IconData icon, String title, String subtitle, String size, {VoidCallback? onTap}) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.zero,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.sfAlt(context), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: AppColors.sec(context))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: AppColors.textPrimary(context), fontSize: 14, fontWeight: FontWeight.w500)),
            Text(subtitle, style: TextStyle(color: AppColors.iconGray(context), fontSize: 12)),
          ])),
          Text(size, style: TextStyle(color: AppColors.textHint(context), fontSize: 13, fontWeight: FontWeight.w500)),
          if (onTap != null) ...[const SizedBox(width: 8), Icon(LucideIcons.chevronRight, size: 16, color: AppColors.iconGray(context))],
        ])));
  }

  void _showClearCacheDialog(BuildContext context, String Function(String) t) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppColors.sf(context), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(t('clear_cache'), style: TextStyle(color: AppColors.textPrimary(context))),
      content: Text(t('clear_cache_confirm'), style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t('cancel'), style: TextStyle(color: AppColors.sec(context)))),
        TextButton(onPressed: () async {
          Navigator.pop(context);
          try {
            final db = DatabaseService.instance;
            if (db.isInitialized) {
              await db.cache.clear();
            }
          } catch (e, stackTrace) { AppLogger.instance.error('Operation failed', error: e, stackTrace: stackTrace); }
          if (mounted) {
            await _calculateSizes();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t('cache_cleared')), backgroundColor: AppColors.accent, duration: const Duration(seconds: 2)),
              );
            }
          }
        }, child: Text(t('clear'), style: TextStyle(color: AppColors.dng(context)))),
      ],
    ));
  }
}
