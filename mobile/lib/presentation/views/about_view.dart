import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/app_colors.dart';
import '../theme/locale_cubit.dart';


class AboutView extends StatefulWidget { const AboutView({super.key});

  @override
  State<AboutView> createState() => _AboutViewState();
}

class _AboutViewState extends State<AboutView> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    }
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
          onPressed: () => Navigator.pop(context)),
        title: Text(
          t('about'),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w600))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.acc(context), AppColors.accentPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.acc(context).withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8)),
                  ]),
                child: Icon(
                  LucideIcons.messageCircle,
                  size: 40,
                  color: AppColors.textPrimary(context)))),
            const SizedBox(height: 16),
            Text(
              'Omnivium',
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 24,
                fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              t('about_subtitle'),
              style: TextStyle(
                color: AppColors.textHint(context),
                fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              'v$_version',
              style: TextStyle(
                color: AppColors.iconGray(context),
                fontSize: 13)),
            const SizedBox(height: 32),
            _buildInfoCard(context, [
              _infoRow(context, t('project'), 'Omnivium'),
              _infoRow(context, t('version'), '$_version ($_buildNumber)'),
              _infoRow(context, t('protocol'), 'Matrix (E2EE)'),
              _infoRow(context, t('ai_engine'), t('multi_model')),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard(context, [
              _infoRow(context, t('tech_stack'), 'Flutter + Matrix SDK'),
              _infoRow(context, t('encryption'), t('encryption_algo')),
              _infoRow(context, t('architecture'), t('arch_detail')),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard(context, [
              _infoRow(context, t('open_source'), t('view_components')),
              _infoRow(context, t('privacy_policy'), t('view_privacy')),
              _infoRow(context, t('terms_of_service'), t('view_terms')),
            ]),
            const SizedBox(height: 32),
            Text(
              '© 2025 Omnivium Team',
              style: TextStyle(
                color: AppColors.textDisabled(context),
                fontSize: 12)),
            const SizedBox(height: 40),
          ])));
  }

  Widget _buildInfoCard(BuildContext context, List<Widget> children) {
    final List<Widget> rows = [];
    for (int i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(
          Divider(
            height: 1,
            color: AppColors.divider(context),
            indent: 16,
            endIndent: 16));
      }
    }
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(14)),
      child: Column(children: rows));
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textHint(context), fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 14,
              fontWeight: FontWeight.w500)),
        ]));
  }
}
