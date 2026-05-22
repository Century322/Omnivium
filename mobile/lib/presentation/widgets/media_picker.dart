import '../../core/app_logger.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';
import '../../core/app_provider.dart';
import '../../core/permission_service.dart';

class MediaPicker {
  static final _imagePicker = ImagePicker();
  static final _perm = PermissionService.instance;

  static Future<void> showPicker(BuildContext context, AppProvider provider, String roomId) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.sf(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(padding: const EdgeInsets.all(12), child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider(context), borderRadius: BorderRadius.circular(2)))),
              _buildOption(ctx, LucideIcons.camera, localeProvider.t('take_photo'), () async {
                Navigator.pop(ctx);
                await _pickFromCamera(context, provider, roomId);
              }),
              _buildOption(ctx, LucideIcons.image, localeProvider.t('pick_image'), () async {
                Navigator.pop(ctx);
                await _pickFromGallery(context, provider, roomId);
              }),
              _buildOption(ctx, LucideIcons.video, localeProvider.t('pick_video'), () async {
                Navigator.pop(ctx);
                await _pickVideo(context, provider, roomId);
              }),
              _buildOption(ctx, LucideIcons.file, localeProvider.t('pick_file'), () async {
                Navigator.pop(ctx);
                await _pickFile(context, provider, roomId);
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildOption(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: AppColors.accBg(context), child: Icon(icon, color: AppColors.accent, size: 20)),
      title: Text(label, style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  static Future<void> _pickFromCamera(BuildContext context, AppProvider provider, String roomId) async {
    final granted = await _perm.requestCamera();
    if (!granted) {
      if (context.mounted) _showPermissionDenied(context, localeProvider.t('camera_permission'));
      return;
    }
    try {
      final xFile = await _imagePicker.pickImage(source: ImageSource.camera, maxWidth: 1920, imageQuality: 85);
      if (xFile == null) return;
      await _sendMediaMessage(provider, roomId, xFile.path, xFile.name, isImage: true);
    } catch (e) {
      if (context.mounted) _showError(context, e.toString());
    }
  }

  static Future<void> _pickFromGallery(BuildContext context, AppProvider provider, String roomId) async {
    final granted = await _perm.requestPhotos();
    if (!granted) {
      if (context.mounted) _showPermissionDenied(context, localeProvider.t('photos_permission'));
      return;
    }
    try {
      final xFile = await _imagePicker.pickImage(source: ImageSource.gallery, maxWidth: 1920, imageQuality: 85);
      if (xFile == null) return;
      await _sendMediaMessage(provider, roomId, xFile.path, xFile.name, isImage: true);
    } catch (e) {
      if (context.mounted) _showError(context, e.toString());
    }
  }

  static Future<void> _pickVideo(BuildContext context, AppProvider provider, String roomId) async {
    final granted = await _perm.requestPhotos();
    if (!granted) {
      if (context.mounted) _showPermissionDenied(context, localeProvider.t('photos_permission'));
      return;
    }
    try {
      final xFile = await _imagePicker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 5));
      if (xFile == null) return;
      await _sendMediaMessage(provider, roomId, xFile.path, xFile.name, isImage: false);
    } catch (e) {
      if (context.mounted) _showError(context, e.toString());
    }
  }

  static Future<void> _pickFile(BuildContext context, AppProvider provider, String roomId) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.path == null) return;
      await _sendMediaMessage(provider, roomId, file.path!, file.name, isImage: false);
    } catch (e) {
      if (context.mounted) _showError(context, e.toString());
    }
  }

  static Future<void> _sendMediaMessage(AppProvider provider, String roomId, String filePath, String fileName, {required bool isImage}) async {
    try {
      if (isImage) {
        await provider.matrix.sendImage(roomId, filePath, fileName);
      } else {
        await provider.matrix.sendFile(roomId, filePath, fileName);
      }
    } catch (e) {
      AppLogger.instance.info('Failed to send media: $e');
    }
  }

  static void _showPermissionDenied(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.warn(context)),
    );
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.dng(context)),
    );
  }
}

class MediaThumbnail extends StatelessWidget {
  final String filePath;
  final String fileName;
  final bool isImage;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const MediaThumbnail({
    super.key,
    required this.filePath,
    required this.fileName,
    this.isImage = true,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(

      behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: 80,
            height: 80,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.sf(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider(context)),
            ),
            child: isImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(filePath), semanticLabel: localeProvider.t('selected_image'), fit: BoxFit.cover, width: 80, height: 80, errorBuilder: (_, _, _) => _buildFilePlaceholder(context)),
                  )
                : _buildFilePlaceholder(context),
          ),
        ),
        if (onRemove != null)
          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(

      behavior: HitTestBehavior.opaque,
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: AppColors.bg(context).withValues(alpha: 0.5), shape: BoxShape.circle),
                child: Icon(LucideIcons.x, size: 12, color: AppColors.textPrimary(context)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilePlaceholder(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.file, size: 24, color: AppColors.mut(context)),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 8, color: AppColors.mut(context))),
          ),
        ],
      ),
    );
  }
}
