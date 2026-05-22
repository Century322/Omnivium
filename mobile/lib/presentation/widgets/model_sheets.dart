import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/app_provider.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';

class OptionsContent extends StatelessWidget {
  final VoidCallback onClose;
  final AppProvider provider;
  const OptionsContent({super.key, required this.onClose, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textDisabled(context), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.start, children: [
            Text(localeProvider.t('options'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.textPrimary(context))),
          ]),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _optItem(context, LucideIcons.image, localeProvider.t('image'), onTap: () => _pickImage(context)),
            _optItem(context, LucideIcons.camera, localeProvider.t('camera'), onTap: () => _takePhoto(context)),
            _optItem(context, LucideIcons.fileText, localeProvider.t('file'), onTap: () => _pickFile(context)),
            _optItem(context, LucideIcons.plug, localeProvider.t('source_info'), onTap: () {
              final logs = provider.orchestrator.executionLogs;
              if (logs.isEmpty) return;
              showModalBottomSheet(
                context: context,
                backgroundColor: AppColors.sf(context),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(height: 8),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textDisabled(context), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 12),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Align(alignment: Alignment.centerLeft, child: Text(localeProvider.t('source_info'), style: TextStyle(color: AppColors.textPrimary(context), fontSize: 16, fontWeight: FontWeight.w600)))),
                  const SizedBox(height: 8),
                  for (final log in logs) ...[
                    ListTile(
                      leading: Icon(log.success == true ? LucideIcons.checkCircle2 : LucideIcons.xCircle, size: 18, color: log.success == true ? AppColors.ok(context) : AppColors.dng(context)),
                      title: Text(log.skillName, style: TextStyle(color: AppColors.textPrimary(context), fontSize: 14)),
                      subtitle: Text('${log.duration.inMilliseconds}ms', style: TextStyle(color: AppColors.textTertiary(context), fontSize: 12)),
                    ),
                  ],
                  const SizedBox(height: 8),
                ])),
              );
            }),
          ]),
          Divider(color: AppColors.divider(context), height: 32),
          ListTile(leading: Icon(LucideIcons.search, color: AppColors.sec(context)), title: Text(localeProvider.t('search'), style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.w500)), trailing: Icon(LucideIcons.check, color: AppColors.accent, size: 20)),
          ListTile(leading: Icon(LucideIcons.radar, color: AppColors.sec(context)), title: Text(localeProvider.t('deep_research'), style: TextStyle(color: AppColors.textSecondary(context), fontWeight: FontWeight.w500)), subtitle: Text(localeProvider.t('deep_research_desc'), style: TextStyle(fontSize: 12, color: AppColors.textHint(context))), trailing: Icon(LucideIcons.chevronRight, color: AppColors.textDisabled(context), size: 16)),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isEmpty) return;
    for (final img in images) { _send('${localeProvider.t('photo_msg')} ${img.name}'); }
  }

  Future<void> _takePhoto(BuildContext context) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;
    _send('${localeProvider.t('camera_msg')} ${photo.name}');
  }

  Future<void> _pickFile(BuildContext context) async {
    Navigator.pop(context);
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return;
    for (final file in result.files) { _send('${localeProvider.t('file_msg')} ${file.name}'); }
  }

  void _send(String content) {
    final orchestrator = provider.orchestrator;
    if (orchestrator.isIdle) { orchestrator.sendMessage(content); }
  }

  Widget _optItem(BuildContext context, IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(onTap: onTap, child: Column(children: [
      Container(width: 72, height: 64, decoration: BoxDecoration(color: AppColors.sf(context), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: AppColors.textSecondary(context))),
      const SizedBox(height: 8),
      Text(label, style: TextStyle(fontSize: 12, color: AppColors.textTertiary(context), fontWeight: FontWeight.w500)),
    ]));
  }
}

class ModelsContent extends StatelessWidget {
  final VoidCallback onClose;
  final AppProvider provider;
  const ModelsContent({super.key, required this.onClose, required this.provider});

  @override
  Widget build(BuildContext context) {
    final models = provider.model.models;
    final activeId = provider.model.activeModelId;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textDisabled(context), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          Text(localeProvider.t('model'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.textPrimary(context))),
        ]),
        const SizedBox(height: 20),
        if (models.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Center(child: Text(localeProvider.t('no_models'), style: TextStyle(color: AppColors.textDisabled(context), fontSize: 14)))),
        if (models.isNotEmpty) ConstrainedBox(constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4), child: ListView.builder(shrinkWrap: true, itemCount: models.length, itemBuilder: (context, i) {
          final m = models[i];
          final isActive = m.id == activeId;
          return ListTile(
            leading: Icon(isActive ? LucideIcons.checkCircle2 : LucideIcons.circle, size: 18, color: isActive ? AppColors.accent : AppColors.textDisabled(context)),
            title: Text(m.name, style: TextStyle(color: isActive ? AppColors.textPrimary(context) : AppColors.textSecondary(context), fontWeight: FontWeight.w500, fontSize: 15)),
            subtitle: Text(m.provider, style: TextStyle(fontSize: 11, color: AppColors.textDisabled(context))),
            onTap: () {
              provider.model.switchModel(m.id);
              Navigator.pop(context);
            },
          );
        })),
      ]),
    );
  }
}
