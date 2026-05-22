import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';
import '../../core/app_provider.dart';
import '../../core/identity_bridge.dart';
import '../../core/runtime/stability/security.dart';

class MyIdView extends StatelessWidget {
  final AppProvider provider;
  const MyIdView({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final t = localeProvider.t;
    final matrix = provider.matrix;
    final notLoggedIn = t('not_logged_in_short');
    final userId = matrix.userId ?? notLoggedIn;
    final homeserver = matrix.homeserver ?? '';
    final identity = IdentityBridge.instance.identity;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          tooltip: localeProvider.t('back'),
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.sec(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t('my_id'),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildAvatar(context, userId, notLoggedIn, identity),
            const SizedBox(height: 20),
            Text(
              userId != notLoggedIn
                  ? userId.split(':').first.replaceAll('@', '')
                  : notLoggedIn,
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              homeserver,
              style: TextStyle(
                color: AppColors.iconGray(context),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 32),
            _buildMatrixIdCard(context, userId, notLoggedIn),
            const SizedBox(height: 16),
            if (identity != null) ...[
              _buildSovereignIdCard(context, identity),
              const SizedBox(height: 16),
              _buildTrustCard(context, identity),
              const SizedBox(height: 16),
              _buildCredentialsCard(context, identity),
            ] else ...[
              _buildNoIdentityCard(context),
            ],
            const SizedBox(height: 16),
            _buildShareCard(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    String userId,
    String notLoggedIn,
    dynamic identity,
  ) {
    final trustLevel = identity?.trustLevel ?? TrustLevel.untrusted;
    final borderColor = _trustColor(context, trustLevel);
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 2),
        boxShadow: identity != null
            ? [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          userId != notLoggedIn && userId.isNotEmpty
              ? userId[1].toUpperCase()
              : '?',
          style: TextStyle(
            color: borderColor,
            fontSize: 42,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildMatrixIdCard(
    BuildContext context,
    String userId,
    String notLoggedIn,
  ) {
    final t = localeProvider.t;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.messageCircle,
                size: 14,
                color: AppColors.sec(context),
              ),
              const SizedBox(width: 6),
              Text(
                t('matrix_id'),
                style: TextStyle(
                  color: AppColors.textHint(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            userId,
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(LucideIcons.copy, size: 16),
              label: Text(t('copy_id')),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: userId));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(t('id_copied')),
                    backgroundColor: AppColors.accent,
                    duration: const Duration(milliseconds: 1500),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSovereignIdCard(BuildContext context, dynamic identity) {
    final t = localeProvider.t;
    final did = identity.did;
    final nodeId = identity.nodeId;
    final publicKey = identity.publicKey;
    final epoch = identity.civilizationEpoch;
    final federationId = identity.federationId;
    final createdAt = DateTime.fromMillisecondsSinceEpoch(identity.createdAt);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.acc(context).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.shieldCheck,
                size: 14,
                color: AppColors.acc(context),
              ),
              const SizedBox(width: 6),
              Text(
                t('sovereign_identity'),
                style: TextStyle(
                  color: AppColors.acc(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            t('did'),
            did,
            LucideIcons.fingerprint,
            AppColors.acc(context),
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            context,
            t('node_id'),
            nodeId,
            LucideIcons.server,
            AppColors.sec(context),
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            context,
            t('public_key'),
            _truncateKey(publicKey),
            LucideIcons.key,
            AppColors.warn(context),
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            context,
            t('civilization_epoch'),
            '$epoch',
            LucideIcons.layers,
            AppColors.ok(context),
          ),
          if (federationId != null) ...[
            const SizedBox(height: 10),
            _buildInfoRow(
              context,
              t('federation_id'),
              federationId,
              LucideIcons.globe,
              AppColors.sec(context),
            ),
          ],
          const SizedBox(height: 10),
          _buildInfoRow(
            context,
            t('created_at'),
            _formatDate(createdAt),
            LucideIcons.calendar,
            AppColors.textTertiary(context),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(LucideIcons.copy, size: 16),
              label: Text(t('copy_did')),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.acc(context),
                side: BorderSide(
                  color: AppColors.acc(context).withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: did));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(t('did_copied')),
                    backgroundColor: AppColors.acc(context),
                    duration: const Duration(milliseconds: 1500),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustCard(BuildContext context, dynamic identity) {
    final t = localeProvider.t;
    final trustLevel = identity.trustLevel as TrustLevel;
    final color = _trustColor(context, trustLevel);
    final label = _trustLabel(trustLevel);
    final ancestry = identity.constitutionalAncestry as List;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.shield, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                t('trust_level'),
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (ancestry.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              t('ancestry'),
              style: TextStyle(
                color: AppColors.textHint(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: ancestry
                  .map(
                    (a) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.sfAlt(context),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$a',
                        style: TextStyle(
                          color: AppColors.textTertiary(context),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCredentialsCard(BuildContext context, dynamic identity) {
    final t = localeProvider.t;
    final credentials = identity.credentials as List;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.award, size: 14, color: AppColors.acc(context)),
              const SizedBox(width: 6),
              Text(
                t('credentials'),
                style: TextStyle(
                  color: AppColors.acc(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${credentials.length}',
                style: TextStyle(
                  color: AppColors.textTertiary(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (credentials.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              t('no_credentials'),
              style: TextStyle(
                color: AppColors.textTertiary(context),
                fontSize: 12,
              ),
            ),
          ],
          ...credentials
              .take(3)
              .map(
                (c) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.badgeCheck,
                        size: 14,
                        color: AppColors.ok(context),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          c.credentialType,
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildNoIdentityCard(BuildContext context) {
    final t = localeProvider.t;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warn(context).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.shieldOff, size: 32, color: AppColors.warn(context)),
          const SizedBox(height: 8),
          Text(
            t('no_sovereign_identity'),
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t('no_sovereign_identity_desc'),
            style: TextStyle(
              color: AppColors.textTertiary(context),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShareCard(BuildContext context) {
    final t = localeProvider.t;
    final userId = provider.matrix.userId ?? '';
    final identity = IdentityBridge.instance.identity;
    final shareId = identity?.did ?? userId;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('share_method'),
            style: TextStyle(
              color: AppColors.textHint(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _shareOption(
            context,
            LucideIcons.messageCircle,
            t('add_via_omnivium'),
            t('add_via_omnivium_desc'),
            onTap: () {
              Clipboard.setData(
                ClipboardData(text: 'omnivium://add?id=$shareId'),
              );
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(t('copied'))));
            },
          ),
          const SizedBox(height: 8),
          _shareOption(
            context,
            LucideIcons.link,
            t('share_via_link'),
            t('share_via_link_desc'),
            onTap: () {
              SharePlus.instance.share(
                ShareParams(
                  text:
                      'https://omnivium.app/i/${Uri.encodeComponent(shareId)}',
                  subject: t('add_me_omnivium'),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _shareOption(
            context,
            LucideIcons.qrCode,
            t('qr_code'),
            t('qr_code_desc'),
            onTap: () {
              _showQrDialog(context, shareId);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textTertiary(context),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 12,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _shareOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.sfAlt(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textTertiary(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: AppColors.iconGray(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showQrDialog(BuildContext context, String shareId) {
    final t = localeProvider.t;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('qr_code'),
          style: TextStyle(color: AppColors.textPrimary(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: 'omnivium://add?id=$shareId',
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 12),
            Text(
              shareId,
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: shareId));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(t('copied'))));
            },
            child: Text(t('copy')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('close')),
          ),
        ],
      ),
    );
  }

  Color _trustColor(BuildContext context, TrustLevel level) {
    switch (level) {
      case TrustLevel.system:
        return AppColors.acc(context);
      case TrustLevel.signed:
        return AppColors.ok(context);
      case TrustLevel.verified:
        return AppColors.ok(context);
      case TrustLevel.untrusted:
        return AppColors.warn(context);
      case TrustLevel.blocked:
        return AppColors.dng(context);
    }
  }

  String _trustLabel(TrustLevel level) {
    final t = localeProvider.t;
    switch (level) {
      case TrustLevel.system:
        return t('trust_system');
      case TrustLevel.signed:
        return t('trust_signed');
      case TrustLevel.verified:
        return t('trust_verified');
      case TrustLevel.untrusted:
        return t('trust_untrusted');
      case TrustLevel.blocked:
        return t('trust_blocked');
    }
  }

  String _truncateKey(String key) {
    if (key.length <= 16) return key;
    return '${key.substring(0, 8)}...${key.substring(key.length - 8)}';
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
