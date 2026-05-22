import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:matrix/encryption/utils/key_verification.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';

class KeyVerificationView extends StatefulWidget {
  final KeyVerification verification;
  const KeyVerificationView({super.key, required this.verification});

  @override
  State<KeyVerificationView> createState() => _KeyVerificationViewState();
}

class _KeyVerificationViewState extends State<KeyVerificationView> {
  @override
  void initState() {
    super.initState();
    widget.verification.onUpdate = () {
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    widget.verification.onUpdate = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.verification;
    final t = localeProvider.t;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          tooltip: localeProvider.t('back'),
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.sec(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t('verify_device'),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildBody(context, v, t),
    );
  }

  Widget _buildBody(
    BuildContext context,
    KeyVerification v,
    String Function(String) t,
  ) {
    switch (v.state) {
      case KeyVerificationState.askChoice:
        return _buildAskChoice(context, v, t);
      case KeyVerificationState.askAccept:
        return _buildAskAccept(context, v, t);
      case KeyVerificationState.askSas:
      case KeyVerificationState.waitingSas:
        return _buildSasVerification(context, v, t);
      case KeyVerificationState.done:
        return _buildDone(context, t);
      case KeyVerificationState.error:
        return _buildError(context, v, t);
      case KeyVerificationState.askSSSS:
        return _buildWaiting(context, t('verifying'));
      default:
        return _buildWaiting(context, t('waiting_for_accept'));
    }
  }

  Widget _buildAskChoice(
    BuildContext context,
    KeyVerification v,
    String Function(String) t,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accBg(context),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                LucideIcons.shieldCheck,
                size: 40,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              t('verify_device'),
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t('verify_device_desc'),
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (v.sasTypes.contains('emoji'))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => v.acceptSas(),
                  icon: Icon(LucideIcons.smile, size: 20),
                  label: Text(
                    t('verify_with_emoji'),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.textPrimary(context),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            if (v.sasTypes.contains('emoji') && v.sasTypes.contains('decimal'))
              const SizedBox(height: 12),
            if (v.sasTypes.contains('decimal'))
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => v.acceptSas(),
                  icon: Icon(LucideIcons.hash, size: 20),
                  label: Text(
                    t('verify_with_numbers'),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.sec(context),
                    side: BorderSide(color: AppColors.divider(context)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAskAccept(
    BuildContext context,
    KeyVerification v,
    String Function(String) t,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accBg(context),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                LucideIcons.shieldQuestion,
                size: 40,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              t('verification_request'),
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t('verification_request_desc'),
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      v.cancel();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.dng(context),
                      side: BorderSide(
                        color: AppColors.dng(context).withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      t('reject'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => v.acceptSas(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.textPrimary(context),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      t('accept'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSasVerification(
    BuildContext context,
    KeyVerification v,
    String Function(String) t,
  ) {
    final emojis = v.sasEmojis;
    final numbers = v.sasNumbers;
    final isWaiting = v.state == KeyVerificationState.waitingSas;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accBg(context),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                LucideIcons.shieldCheck,
                size: 40,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              t('compare_emoji'),
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t('compare_emoji_desc'),
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (emojis.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: AppColors.sf(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider(context)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: emojis
                      .map(
                        (e) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(e.emoji, style: TextStyle(fontSize: 36)),
                            const SizedBox(height: 4),
                            Text(
                              e.name,
                              style: TextStyle(
                                color: AppColors.textHint(context),
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            if (numbers.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.sf(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider(context)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < numbers.length; i++) ...[
                      if (i > 0 && i % 3 == 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '�C',
                            style: TextStyle(
                              color: AppColors.textTertiary(context),
                              fontSize: 24,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      Text(
                        '${numbers[i]}',
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            if (isWaiting)
              Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t('waiting_for_confirm'),
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 14,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        v.rejectSas();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.dng(context),
                        side: BorderSide(
                          color: AppColors.dng(context).withValues(alpha: 0.3),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        t('they_dont_match'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        v.acceptSas();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.textPrimary(context),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        t('they_match'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDone(BuildContext context, String Function(String) t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accBg(context),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                LucideIcons.checkCircle2,
                size: 40,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              t('verification_complete'),
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t('verification_complete_desc'),
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.textPrimary(context),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  t('done'),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    KeyVerification v,
    String Function(String) t,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.dng(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                LucideIcons.shieldOff,
                size: 40,
                color: AppColors.dng(context),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              t('verification_failed'),
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              v.canceledReason ?? t('verification_error'),
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.textPrimary(context),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  t('close'),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaiting(BuildContext context, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
