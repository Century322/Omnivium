import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
          child: Image.network(
            imageUrl,
            semanticLabel: title ?? localeProvider.t('full_size_image'),
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                      : null,
                  color: AppColors.acc(context),
                ),
              );
            },
            errorBuilder: (_, _, _) => Center(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
