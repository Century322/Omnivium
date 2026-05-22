import '../../core/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';
import '../../core/link_preview_service.dart';

class LinkPreviewCard extends StatelessWidget {
  final String url;
  final LinkPreviewData? preview;
  const LinkPreviewCard({super.key, required this.url, this.preview});

  @override
  Widget build(BuildContext context) {
    if (preview == null) {
      return _buildFallback(context);
    }
    return Semantics(
      label: localeProvider.t('open_link'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _launchUrl(url),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.sf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider(context)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (preview!.imageUrl != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: CachedNetworkImage(
                    imageUrl: preview!.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      height: 120,
                      color: AppColors.sfActive(context),
                    ),
                    errorWidget: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (preview!.siteName != null)
                      Text(
                        preview!.siteName!,
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 2),
                    if (preview!.title != null)
                      Text(
                        preview!.title!,
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (preview!.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        preview!.description!,
                        style: TextStyle(
                          color: AppColors.mut(context),
                          fontSize: 12,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.link,
                          size: 12,
                          color: AppColors.textDisabled(context),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _truncateUrl(url),
                            style: TextStyle(
                              color: AppColors.textDisabled(context),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _launchUrl(url),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.sf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accBg(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(LucideIcons.link, size: 20, color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _truncateUrl(url),
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    url,
                    style: TextStyle(
                      color: AppColors.textDisabled(context),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.externalLink,
              size: 16,
              color: AppColors.textDisabled(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _truncateUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceAll('www.', '');
    } catch (e, stackTrace) {
      AppLogger.instance.warning(
        'Operation failed',
        error: e,
        stackTrace: stackTrace,
      );
      return url.length > 40 ? '${url.substring(0, 40)}...' : url;
    }
  }
}
