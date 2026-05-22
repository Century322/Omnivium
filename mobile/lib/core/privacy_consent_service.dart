import 'package:flutter/material.dart';
import 'secure_storage_service.dart';
import '../presentation/theme/app_colors.dart';
import '../presentation/theme/locale_provider.dart';

class PrivacyConsentService {
  static const _consentKey = 'omnivium_privacy_consented';
  static const _consentVersionKey = 'omnivium_privacy_consent_version';
  static const _currentVersion = 1;

  Future<bool> hasConsented() async {
    final storage = SecureStorageService.instance;
    final consented = await storage.read(_consentKey);
    final version =
        int.tryParse(await storage.read(_consentVersionKey) ?? '0') ?? 0;
    return consented == 'true' && version >= _currentVersion;
  }

  Future<void> grantConsent() async {
    final storage = SecureStorageService.instance;
    await storage.write(_consentKey, 'true');
    await storage.write(_consentVersionKey, _currentVersion.toString());
  }

  Future<void> revokeConsent() async {
    final storage = SecureStorageService.instance;
    await storage.write(_consentKey, 'false');
    await storage.write(_consentVersionKey, '0');
  }
}

class PrivacyConsentDialog {
  static Future<bool> show(BuildContext context) async {
    final t = localeProvider.t;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        title: Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.accent, size: 24),
            const SizedBox(width: 8),
            Text(
              t('privacy_policy'),
              style: TextStyle(color: AppColors.secondary, fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('privacy_welcome'),
                style: TextStyle(color: AppColors.secondary, fontSize: 14),
              ),
              const SizedBox(height: 12),
              _buildItem(
                ctx,
                '🔒',
                t('privacy_e2e_title'),
                t('privacy_e2e_desc'),
              ),
              const SizedBox(height: 8),
              _buildItem(
                ctx,
                '🔑',
                t('privacy_key_title'),
                t('privacy_key_desc'),
              ),
              const SizedBox(height: 8),
              _buildItem(
                ctx,
                '📊',
                t('privacy_no_collect_title'),
                t('privacy_no_collect_desc'),
              ),
              const SizedBox(height: 8),
              _buildItem(
                ctx,
                '🤖',
                t('privacy_ai_title'),
                t('privacy_ai_desc'),
              ),
              const SizedBox(height: 16),
              Text(
                t('privacy_agree_notice'),
                style: TextStyle(color: AppColors.mut(context), fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              t('exit'),
              style: TextStyle(color: AppColors.mut(context)),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
            ),
            child: Text(t('agree_continue')),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Widget _buildItem(
    BuildContext context,
    String emoji,
    String title,
    String desc,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.sec(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                desc,
                style: TextStyle(
                  color: AppColors.mut(context),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
