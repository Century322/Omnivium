import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ImageBubble extends StatelessWidget {
  final String url;
  final String? thumbnailUrl;
  final VoidCallback? onTap;

  const ImageBubble({
    super.key,
    required this.url,
    this.thumbnailUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240, maxHeight: 240),
          child: thumbnailUrl != null
              ? Image.network(
                  thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(context))
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(context)),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: 200,
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.bg2(context),
        borderRadius: BorderRadius.circular(12)),
      child: Icon(Icons.image, color: AppColors.textTertiary(context), size: 40),
    );
  }
}
