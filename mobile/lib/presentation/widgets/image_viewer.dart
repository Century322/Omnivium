import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';

class ImageViewer extends StatelessWidget {
  final String imageUrl;
  final String? title;
  const ImageViewer({super.key, required this.imageUrl, this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        leading: IconButton(
          tooltip: localeProvider.t('close'),
          icon: Icon(LucideIcons.x, color: AppColors.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: title != null
            ? Text(
                title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 16,
                ),
              )
            : null,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (_, __) => Center(
              child: CircularProgressIndicator(
                color: AppColors.acc(context),
              ),
            ),
            errorWidget: (_, url, error) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.imageOff,
                    size: 48,
                    color: AppColors.iconGray(context),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    localeProvider.t('image_load_failed'),
                    style: TextStyle(
                      color: AppColors.textTertiary(context),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      CachedNetworkImage.evictFromCache(url);
                    },
                    icon: Icon(LucideIcons.refreshCw, size: 16, color: AppColors.acc(context)),
                    label: Text(
                      localeProvider.t('retry'),
                      style: TextStyle(color: AppColors.acc(context)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
