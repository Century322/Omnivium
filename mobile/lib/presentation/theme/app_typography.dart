import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  static TextStyle displayLarge(BuildContext context) => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary(context),
    height: 1.2);

  static TextStyle displayMedium(BuildContext context) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary(context),
    height: 1.25);

  static TextStyle headlineMedium(BuildContext context) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary(context),
    height: 1.3);

  static TextStyle titleLarge(BuildContext context) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary(context),
    height: 1.35);

  static TextStyle titleMedium(BuildContext context) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary(context),
    height: 1.4);

  static TextStyle titleSmall(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary(context),
    height: 1.4);

  static TextStyle bodyLarge(BuildContext context) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary(context),
    height: 1.5);

  static TextStyle bodyMedium(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary(context),
    height: 1.5);

  static TextStyle bodySmall(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary(context),
    height: 1.45);

  static TextStyle labelLarge(BuildContext context) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary(context),
    height: 1.4);

  static TextStyle labelMedium(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary(context),
    height: 1.4);

  static TextStyle labelSmall(BuildContext context) => TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary(context),
    height: 1.4);

  static TextStyle caption(BuildContext context) => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary(context),
    height: 1.35);

  static TextStyle chatMessage(BuildContext context) => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary(context),
    height: 1.45);

  static TextStyle chatTimestamp(BuildContext context) => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary(context),
    height: 1.3);

  static TextStyle chatSender(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.acc(context),
    height: 1.3);

  static TextStyle inputHint(BuildContext context) => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint(context),
    height: 1.4);

  static TextStyle badge(BuildContext context) => TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.bg(context),
    height: 1.2);

  static TextStyle sectionHeader(BuildContext context) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textTertiary(context),
    height: 1.3);
}
