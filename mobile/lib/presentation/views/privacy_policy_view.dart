import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    final t = localeProvider.t;
    return Scaffold(
      appBar: AppBar(elevation: 0,
        leading: IconButton(tooltip: localeProvider.t('back'), icon: Icon(LucideIcons.arrowLeft, color: AppColors.sec(context)), onPressed: () => Navigator.pop(context)),
        title: Text(t('privacy_policy'), style: TextStyle(color: AppColors.textPrimary(context), fontSize: 18, fontWeight: FontWeight.w600))),
      body: ListView(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), children: [
        buildSection(context, title: t('pp_data_collection'), content: t('pp_data_collection_content')),
        buildSection(context, title: t('pp_data_usage'), content: t('pp_data_usage_content')),
        buildSection(context, title: t('pp_data_storage'), content: t('pp_data_storage_content')),
        buildSection(context, title: t('pp_data_protection'), content: t('pp_data_protection_content')),
        buildSection(context, title: t('pp_data_deletion'), content: t('pp_data_deletion_content')),
        buildSection(context, title: t('pp_third_party'), content: t('pp_third_party_content')),
        buildSection(context, title: t('pp_cookie'), content: t('pp_cookie_content')),
        buildSection(context, title: t('pp_policy_update'), content: t('pp_policy_update_content')),
        buildSection(context, title: t('pp_contact'), content: t('pp_contact_content')),
      ]),
    );
  }
}

Widget buildSection(BuildContext context, {required String title, required String content}) {
  return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.sf(context), borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: AppColors.textPrimary(context), fontSize: 15, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text(content, style: TextStyle(color: AppColors.textHint(context), fontSize: 13, height: 1.6)),
    ]));
}
