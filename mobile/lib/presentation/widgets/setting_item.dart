import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SettingItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? rightContent;
  final Color? textColor;
  final VoidCallback? onTap;

  const SettingItem({
    super.key,
    required this.title,
    this.subtitle,
    this.rightContent,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ?? AppColors.textPrimary(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, color: effectiveTextColor)),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle!,
                        style: TextStyle(fontSize: 13, color: AppColors.mut(context), height: 1.4),
                      ),
                    ),
                ],
              ),
            ),
            rightContent ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
