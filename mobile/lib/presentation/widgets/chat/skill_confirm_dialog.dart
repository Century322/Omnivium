import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/locale_cubit.dart';

class SkillConfirmDialog extends StatelessWidget {
  final String title;
  final String description;
  final String? destructiveLabel;
  final String confirmLabel;
  final bool isDestructive;

  const SkillConfirmDialog({
    super.key,
    required this.title,
    required this.description,
    this.destructiveLabel,
    this.confirmLabel = 'Confirm',
    this.isDestructive = false,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String description,
    String? destructiveLabel,
    String confirmLabel = 'Confirm',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => SkillConfirmDialog(
        title: title,
        description: description,
        destructiveLabel: destructiveLabel,
        confirmLabel: confirmLabel,
        isDestructive: isDestructive,
      ),
    ).then((v) => v ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.sf(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            isDestructive ? LucideIcons.alertTriangle : LucideIcons.shieldCheck,
            size: 20,
            color: isDestructive ? AppColors.dng(context) : AppColors.acc(context),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        description,
        style: TextStyle(
          color: AppColors.textSecondary(context),
          fontSize: 14,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            localeProvider.t('cancel'),
            style: TextStyle(color: AppColors.textSecondary(context)),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: isDestructive
                ? AppColors.dng(context)
                : AppColors.acc(context),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(destructiveLabel ?? confirmLabel),
        ),
      ],
    );
  }
}
