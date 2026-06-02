import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/locale_cubit.dart';

class FileBubble extends StatelessWidget {
  final String fileName;
  final int? fileSize;
  final String? mimeType;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;

  const FileBubble({
    super.key,
    required this.fileName,
    this.fileSize,
    this.mimeType,
    this.onTap,
    this.onDownload,
  });

  IconData get _icon {
    if (mimeType == null) return Icons.insert_drive_file;
    if (mimeType!.startsWith('audio/')) return Icons.audiotrack;
    if (mimeType!.startsWith('video/')) return Icons.videocam;
    if (mimeType!.startsWith('image/')) return Icons.image;
    if (mimeType!.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType!.contains('zip') || mimeType!.contains('rar')) return Icons.folder_zip;
    if (mimeType!.contains('text')) return Icons.description;
    return Icons.insert_drive_file;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bg2(context),
          borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, color: AppColors.sec(context), size: 32),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                  if (fileSize != null)
                    Text(
                      _formatSize(fileSize!),
                      style: TextStyle(
                        color: AppColors.textTertiary(context),
                        fontSize: 12)),
                ])),
            if (onDownload != null)
              IconButton(
                icon: Icon(Icons.download, color: AppColors.sec(context), size: 20),
                onPressed: onDownload),
          ],
        ),
      ),
    );
  }
}
