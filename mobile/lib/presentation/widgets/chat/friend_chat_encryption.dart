import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/di/app_di.dart';
import '../../core/matrix/matrix_cubit.dart';
import '../../core/app_logger.dart';
import '../../theme/app_colors.dart';
import '../../theme/locale_cubit.dart';
import '../../views/key_verification_view.dart';

mixin FriendChatEncryption on State {
  String get chatTargetId;

  void showEncryptionInfo(BuildContext context) {
    final matrix = getIt<MatrixCubit>();
    final isEncrypted = chatTargetId.isNotEmpty && matrix.isRoomEncrypted(chatTargetId);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isEncrypted ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
              color: isEncrypted ? AppColors.acc(context) : AppColors.warn(context),
              size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isEncrypted ? localeProvider.t('e2e_encrypted_short') : localeProvider.t('not_encrypted_short'),
                style: TextStyle(color: AppColors.textPrimary(context), fontSize: 18))),
          ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isEncrypted) ...[
              Text(localeProvider.t('e2e_detail'),
                  style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14, height: 1.5)),
              const SizedBox(height: 16),
              Text(localeProvider.t('encrypt_verify'),
                  style: TextStyle(color: AppColors.textPrimary(context), fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              FutureBuilder<String?>(
                future: _getDeviceVerificationEmojis(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
                  }
                  if (snap.hasError) {
                    return Text(localeProvider.t('verify_unavailable'), style: TextStyle(color: AppColors.textHint(context), fontSize: 13));
                  }
                  final emojis = snap.data;
                  if (emojis == null || emojis.isEmpty) {
                    return Text(localeProvider.t('verify_unavailable'), style: TextStyle(color: AppColors.textHint(context), fontSize: 13));
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(emojis, style: const TextStyle(fontSize: 28, letterSpacing: 4)),
                      const SizedBox(height: 6),
                      Text(localeProvider.t('verify_instruction'), style: TextStyle(color: AppColors.textHint(context), fontSize: 12)),
                    ]);
                }),
            ] else ...[
              Text(localeProvider.t('no_e2e_detail'),
                  style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14, height: 1.5)),
            ],
            const SizedBox(height: 12),
            Text(localeProvider.t('e2e_benefits'),
                style: TextStyle(color: AppColors.textHint(context), fontSize: 12, height: 1.5)),
          ]),
        actions: [
          if (isEncrypted)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _startKeyVerification(context);
              },
              child: Text(localeProvider.t('verify_device'), style: TextStyle(color: AppColors.acc(context)))),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localeProvider.t('got_it'), style: TextStyle(color: AppColors.acc(context)))),
        ]));
  }

  void _startKeyVerification(BuildContext context) async {
    try {
      final matrix = getIt<MatrixCubit>();
      if (!matrix.isLoggedIn || chatTargetId.isEmpty) return;
      final memberIds = matrix.getRoomMemberIds(chatTargetId);
      final otherMemberId = memberIds.where((id) => id != matrix.userId).firstOrNull;
      if (otherMemberId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localeProvider.t('verify_unavailable')), backgroundColor: AppColors.sf(context)));
        }
        return;
      }
      final client = getIt<MatrixCubit>().client;
      final deviceKeysList = client?.userDeviceKeys[otherMemberId];
      if (deviceKeysList == null || deviceKeysList.deviceKeys.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localeProvider.t('verify_unavailable')), backgroundColor: AppColors.sf(context)));
        }
        return;
      }
      final verification = await deviceKeysList.startVerification();
      if (mounted) {
        Navigator.push(context, MaterialPageRoute<void>(builder: (_) => KeyVerificationView(verification: verification)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localeProvider.t('verification_error')), backgroundColor: AppColors.sf(context)));
      }
    }
  }

  Future<String?> _getDeviceVerificationEmojis() async {
    try {
      final matrix = getIt<MatrixCubit>();
      final client = matrix.client;
      if (client == null || chatTargetId.isEmpty) return null;
      if (!matrix.isRoomEncrypted(chatTargetId)) return null;
      final fingerprint = matrix.getFingerprintKey() ?? '';
      final identity = client.identityKey;
      if (fingerprint.isEmpty && identity.isEmpty) return null;
      final parts = <String>[];
      if (fingerprint.isNotEmpty) {
        final fp = StringBuffer();
        for (var i = 0; i < fingerprint.length; i += 4) {
          if (i > 0) fp.write(' ');
          fp.write(fingerprint.substring(i, i + 4 > fingerprint.length ? fingerprint.length : i + 4));
        }
        parts.add('${localeProvider.t('fingerprint_key')}: $fp');
      }
      if (identity.isNotEmpty) {
        final id = StringBuffer();
        for (var i = 0; i < identity.length; i += 4) {
          if (i > 0) id.write(' ');
          id.write(identity.substring(i, i + 4 > identity.length ? identity.length : i + 4));
        }
        parts.add('${localeProvider.t('identity_key')}: $id');
      }
      return parts.join('\n');
    } catch (e, stackTrace) {
      AppLogger.instance.warning('App error', error: e, stackTrace: stackTrace);
      return null;
    }
  }
}
