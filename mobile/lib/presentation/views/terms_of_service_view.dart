import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/locale_cubit.dart';

class TermsOfServiceView extends StatelessWidget {
  const TermsOfServiceView({super.key});

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
          t('terms_of_service'),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w600))),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          buildTosSection(
            context,
            title: t('tos_acceptance'),
            content: t('tos_acceptance_content')),
          buildTosSection(
            context,
            title: t('tos_description'),
            content: t('tos_description_content')),
          buildTosSection(
            context,
            title: t('tos_conduct'),
            content: t('tos_conduct_content')),
          buildTosSection(
            context,
            title: t('tos_ip'),
            content: t('tos_ip_content')),
          buildTosSection(
            context,
            title: t('tos_disclaimer'),
            content: t('tos_disclaimer_content')),
          buildTosSection(
            context,
            title: t('tos_termination'),
            content: t('tos_termination_content')),
          buildTosSection(
            context,
            title: t('tos_dispute'),
            content: t('tos_dispute_content')),
          buildTosSection(
            context,
            title: t('tos_update'),
            content: t('tos_update_content')),
        ]));
  }
}

Widget buildTosSection(
  BuildContext context, {
  required String title,
  required String content,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.sf(context),
      borderRadius: BorderRadius.circular(14)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 15,
            fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            color: AppColors.textHint(context),
            fontSize: 13,
            height: 1.6)),
      ]));
}
