import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/di/app_di.dart';
import '../../core/matrix/matrix_cubit.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/call_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/file_download_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/locale_cubit.dart';
import '../../views/call_screen.dart';

mixin FriendChatPlusMenu on State {
  void showPlusMenu(BuildContext context, String roomId, {
    required VoidCallback onSendFile,
    required void Function(String label, String name, String path) sendFileMessage,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.sf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _plusMenuItem(context, LucideIcons.image, localeProvider.t('image'),
                      onTap: () => _pickImage(context, sendFileMessage)),
                  _plusMenuItem(context, LucideIcons.camera, localeProvider.t('camera'),
                      onTap: () => _takePhoto(context, sendFileMessage)),
                  _plusMenuItem(context, LucideIcons.file, localeProvider.t('file'),
                      onTap: () => _pickFile(context, sendFileMessage)),
                  _plusMenuItem(context, LucideIcons.phone, localeProvider.t('voice_call'),
                      onTap: () => _startVoiceCall(context, roomId)),
                  _plusMenuItem(context, LucideIcons.video, localeProvider.t('video_call'),
                      onTap: () => _startVideoCall(context, roomId)),
                  _plusMenuItem(context, LucideIcons.film, localeProvider.t('video'),
                      onTap: () => _pickVideo(context, roomId)),
                ]),
            ]))));
  }

  Widget _plusMenuItem(BuildContext context, IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap ?? () => Navigator.pop(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.sfAlt(context),
              borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, size: 22, color: AppColors.sec(context))),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: AppColors.textHint(context), fontSize: 11)),
        ]));
  }

  Future<void> _pickImage(BuildContext context, void Function(String, String, String) sendFileMessage) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isEmpty) return;
    for (final img in images) {
      sendFileMessage(localeProvider.t('photo_msg'), img.name, img.path);
    }
  }

  Future<void> _takePhoto(BuildContext context, void Function(String, String, String) sendFileMessage) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;
    sendFileMessage(localeProvider.t('camera_msg'), photo.name, photo.path);
  }

  Future<void> _pickFile(BuildContext context, void Function(String, String, String) sendFileMessage) async {
    Navigator.pop(context);
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return;
    for (final file in result.files) {
      if (file.path != null) {
        sendFileMessage(localeProvider.t('file_msg'), file.name, file.path!);
      }
    }
  }

  Future<void> _pickVideo(BuildContext context, String roomId) async {
    Navigator.pop(context);
    final result = await FilePicker.platform.pickFiles(type: FileType.video, allowMultiple: false);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;
    HapticService.lightImpact();
    try {
      await getIt<MatrixCubit>().sendVideo(roomId, file.path!, file.name);
      getIt<AnalyticsService>().logSendMessage(type: 'video');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.dng(context)));
      }
    }
  }

  void _startVoiceCall(BuildContext context, String roomId) {
    final matrix = getIt<MatrixCubit>();
    final memberIds = matrix.getRoomMemberIds(roomId);
    final remoteUserId = memberIds.where((id) => id != matrix.userId).firstOrNull;
    if (remoteUserId == null) return;
    getIt<CallService>().initiateCall(roomId, remoteUserId);
    getIt<AnalyticsService>().logVoiceCall();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CallScreen()));
  }

  void _startVideoCall(BuildContext context, String roomId) {
    final matrix = getIt<MatrixCubit>();
    final memberIds = matrix.getRoomMemberIds(roomId);
    final remoteUserId = memberIds.where((id) => id != matrix.userId).firstOrNull;
    if (remoteUserId == null) return;
    getIt<CallService>().initiateCallWithVideo(roomId, remoteUserId, isVideo: true);
    getIt<AnalyticsService>().logVoiceCall();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CallScreen()));
  }
}
