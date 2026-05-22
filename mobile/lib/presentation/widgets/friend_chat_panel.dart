import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:matrix/matrix.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';
import '../../core/app_provider.dart';
import '../../core/app_logger.dart';
import '../../core/call_service.dart';
import '../../core/haptic_service.dart';
import '../../core/file_download_service.dart';
import '../widgets/home_components.dart';
import '../widgets/voice_message.dart';
import '../widgets/link_preview_card.dart';
import '../views/key_verification_view.dart';
import '../views/friend_profile_view.dart';
import '../views/call_screen.dart';
import 'image_viewer.dart';

class FriendChatPanel extends StatefulWidget {
  final AppProvider provider;
  final String chatTargetId;
  final String chatTargetName;
  final VoidCallback onClose;
  final double maxWidth;

  const FriendChatPanel({
    super.key,
    required this.provider,
    required this.chatTargetId,
    required this.chatTargetName,
    required this.onClose,
    required this.maxWidth,
  });

  @override
  State<FriendChatPanel> createState() => _FriendChatPanelState();
}

class _FriendChatPanelState extends State<FriendChatPanel>
    with TickerProviderStateMixin {
  String t(String key) => localeProvider.t(key);

  final List<FriendMessageData> _friendMessages = [];
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isOtherTyping = false;
  bool _isListening = false;
  Future<CachedPresence?>? _presenceFuture;
  Timer? _presenceTimer;

  late AnimationController _listeningGlow;

  @override
  void initState() {
    super.initState();
    _listeningGlow = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    widget.provider.matrix.addListener(_onMatrixChanged);
    _presenceFuture = _getPresence();
    _presenceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {
          _presenceFuture = _getPresence();
        });
      }
    });
    _loadMatrixMessages(widget.chatTargetId);
    _markRoomAsRead(widget.chatTargetId);
  }

  @override
  void dispose() {
    _presenceTimer?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _listeningGlow.dispose();
    widget.provider.matrix.removeListener(_onMatrixChanged);
    super.dispose();
  }

  void _onMatrixChanged() {
    if (widget.chatTargetId.isEmpty) {
      setState(() {});
      return;
    }
    final matrix = widget.provider.matrix;
    final room = matrix.client?.getRoomById(widget.chatTargetId);
    if (room != null) {
      final typingUsers = room.typingUsers
          .where((u) => u.id != matrix.userId)
          .toList();
      final nowTyping = typingUsers.isNotEmpty;
      if (nowTyping != _isOtherTyping) {
        setState(() => _isOtherTyping = nowTyping);
      }
    }
    final newEvents = matrix.newEvents;
    final relevantEvents = newEvents.where((e) {
      return e.roomId == widget.chatTargetId;
    }).toList();
    if (relevantEvents.isNotEmpty) {
      for (final event in relevantEvents) {
        if (event.type == EventTypes.Message && event.body.isNotEmpty) {
          final isMe = event.senderId == matrix.userId;
          final msgType = event.content['msgtype'] as String?;
          final url =
              event.content['url'] as String? ??
              (event.content['file'] is Map
                  ? (event.content['file'] as Map)['url'] as String?
                  : null);
          final audioDuration = event.content['info'] is Map
              ? (event.content['info'] as Map)['duration'] as int?
              : null;
          setState(() {
            _friendMessages.add(
              FriendMessageData(
                isMe: isMe,
                content: event.body,
                msgType: msgType,
                url: url,
                audioDuration: audioDuration,
              ),
            );
          });
        }
      }
      matrix.clearNewEvents();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollToLatest();
      });
    } else {
      setState(() {});
    }
  }

  void _scrollToLatest() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _markRoomAsRead(String roomId) {
    final room = widget.provider.matrix.client?.getRoomById(roomId);
    if (room == null) return;
    final lastEventId = room.lastEvent?.eventId;
    if (lastEventId != null) {
      room.setReadMarker(lastEventId, mRead: lastEventId);
    }
  }

  Future<void> _loadMatrixMessages(String roomId) async {
    final matrix = widget.provider.matrix;
    if (!matrix.isLoggedIn) return;
    final room = matrix.client?.getRoomById(roomId);
    if (room == null) return;
    try {
      final timeline = await room.getTimeline();
      if (!mounted) return;
      setState(() {
        _friendMessages.clear();
        for (final event in timeline.events) {
          if (event.type == EventTypes.Message && event.body.isNotEmpty) {
            final isMe = event.senderId == matrix.userId;
            final msgType = event.content['msgtype'] as String?;
            final url =
                event.content['url'] as String? ??
                (event.content['file'] is Map
                    ? (event.content['file'] as Map)['url'] as String?
                    : null);
            final audioDuration = event.content['info'] is Map
                ? (event.content['info'] as Map)['duration'] as int?
                : null;
            _friendMessages.add(
              FriendMessageData(
                isMe: isMe,
                content: event.body,
                eventId: event.eventId,
                msgType: msgType,
                url: url,
                audioDuration: audioDuration,
              ),
            );
          }
        }
      });
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'Operation failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _toggleListening() {
    setState(() => _isListening = !_isListening);
    if (_isListening) {
      _listeningGlow.forward();
    } else {
      _listeningGlow.reverse();
    }
  }

  void _sendTypingNotice() {
    if (widget.chatTargetId.isEmpty) return;
    final room = widget.provider.matrix.client?.getRoomById(
      widget.chatTargetId,
    );
    if (room == null) return;
    room.setTyping(true, timeout: 5000);
  }

  void _sendFriendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    HapticService.sendMessage();
    _textController.clear();
    _focusNode.unfocus();

    setState(() {
      _friendMessages.add(FriendMessageData(isMe: true, content: text));
    });

    final matrix = widget.provider.matrix;
    if (matrix.isLoggedIn && widget.chatTargetId.isNotEmpty) {
      matrix.sendMessage(widget.chatTargetId, text);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollToLatest();
    });
  }

  void _sendVoiceMessage(String path, Duration duration) async {
    try {
      final client = widget.provider.matrix.client;
      if (client == null) return;
      final room = client.getRoomById(widget.chatTargetId);
      if (room == null) return;
      final bytes = await File(path).readAsBytes();
      final file = MatrixAudioFile(
        bytes: bytes,
        name: 'voice_message.m4a',
        duration: duration.inMilliseconds,
      );
      await room.sendFileEvent(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localeProvider.t('voice_send_failed')),
            backgroundColor: AppColors.sf(context),
          ),
        );
      }
    }
  }

  void _sendFileMessage(String prefix, String fileName, String? filePath) {
    if (!mounted) return;
    setState(() {
      _friendMessages.add(
        FriendMessageData(isMe: true, content: '$prefix $fileName'),
      );
    });
    final matrix = widget.provider.matrix;
    if (matrix.isLoggedIn &&
        widget.chatTargetId.isNotEmpty &&
        filePath != null) {
      if (prefix.contains(localeProvider.t('photo_msg')) ||
          prefix.contains(localeProvider.t('camera_msg'))) {
        matrix.sendImage(widget.chatTargetId, filePath, fileName);
      } else {
        matrix.sendFile(widget.chatTargetId, filePath, fileName);
      }
    }
  }

  void _showMessageActions(int index) {
    final msg = _friendMessages[index];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.sf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textDisabled(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(LucideIcons.copy, color: AppColors.sec(context)),
              title: Text(
                t('copy'),
                style: TextStyle(color: AppColors.textPrimary(context)),
              ),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: msg.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(t('copied')),
                    backgroundColor: AppColors.accent,
                    duration: const Duration(milliseconds: 1500),
                  ),
                );
              },
            ),
            if (msg.isMe)
              ListTile(
                leading: Icon(
                  LucideIcons.rotateCcw,
                  color: AppColors.warn(context),
                ),
                title: Text(
                  t('recall'),
                  style: TextStyle(color: AppColors.warn(context)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _recallMessage(index);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _recallMessage(int index) {
    final msg = _friendMessages[index];
    if (msg.eventId != null && widget.chatTargetId.isNotEmpty) {
      final room = widget.provider.matrix.client?.getRoomById(
        widget.chatTargetId,
      );
      if (room != null) {
        room.redactEvent(msg.eventId!);
      }
    }
    setState(() {
      _friendMessages[index] = FriendMessageData(
        isMe: msg.isMe,
        content: t('message_recalled'),
        eventId: msg.eventId,
      );
    });
  }

  void _showPlusMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.sf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _plusMenuItem(
                    LucideIcons.image,
                    localeProvider.t('image'),
                    onTap: _pickImage,
                  ),
                  _plusMenuItem(
                    LucideIcons.camera,
                    localeProvider.t('camera'),
                    onTap: _takePhoto,
                  ),
                  _plusMenuItem(
                    LucideIcons.file,
                    localeProvider.t('file'),
                    onTap: _pickFile,
                  ),
                  _plusMenuItem(
                    LucideIcons.phone,
                    localeProvider.t('voice_call'),
                    onTap: _startVoiceCall,
                  ),
                  _plusMenuItem(
                    LucideIcons.video,
                    localeProvider.t('video_call'),
                    onTap: () => _showComingSoon(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isEmpty) return;
    for (final img in images) {
      _sendFileMessage(localeProvider.t('photo_msg'), img.name, img.path);
    }
  }

  Future<void> _takePhoto() async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;
    _sendFileMessage(localeProvider.t('camera_msg'), photo.name, photo.path);
  }

  Future<void> _pickFile() async {
    Navigator.pop(context);
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return;
    for (final file in result.files) {
      _sendFileMessage(localeProvider.t('file_msg'), file.name, file.path);
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localeProvider.t('coming_soon')),
        backgroundColor: AppColors.accent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _startVoiceCall() {
    final client = widget.provider.matrix.client;
    if (client == null) return;
    final room = client.getRoomById(widget.chatTargetId);
    if (room == null) return;
    final remoteMembers = room.getParticipants();
    final remoteUser = remoteMembers
        .where((m) => m.id != client.userID)
        .firstOrNull;
    if (remoteUser == null) return;

    CallService.instance.initiateCall(room.id, remoteUser.id);
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CallScreen()));
  }

  Widget _plusMenuItem(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap ?? () => Navigator.pop(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.sfAlt(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: AppColors.sec(context)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(color: AppColors.textHint(context), fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showFriendChatMenu(BuildContext ctx) {
    showMenu(
      context: ctx,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(ctx).size.width - 180,
        MediaQuery.of(ctx).padding.top + 60,
        16,
        0,
      ),
      color: AppColors.sf(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        _menuItem(LucideIcons.user, localeProvider.t('view_profile')),
        _menuItem(LucideIcons.shieldCheck, localeProvider.t('encrypt_info')),
        _menuItem(LucideIcons.bell, localeProvider.t('mute_chat')),
        _menuItem(LucideIcons.search, localeProvider.t('search_chat_history')),
        _menuItem(LucideIcons.share, localeProvider.t('share_conversation')),
        _menuItem(
          LucideIcons.trash2,
          localeProvider.t('clear_chat'),
          isDanger: true,
        ),
      ],
    ).then((value) {
      if (value == null) return;
      if (value == localeProvider.t('view_profile')) {
        _showFriendProfile();
      } else if (value == localeProvider.t('encrypt_info')) {
        _showEncryptionInfo();
      } else if (value == localeProvider.t('mute_chat')) {
        _toggleMute();
      } else if (value == localeProvider.t('search_chat_history')) {
        _showChatSearch();
      } else if (value == localeProvider.t('share_conversation')) {
        _shareFriendConversation();
      } else if (value == localeProvider.t('clear_chat')) {
        _clearFriendChat();
      }
    });
  }

  void _toggleMute() {
    if (widget.chatTargetId.isEmpty) return;
    final room = widget.provider.matrix.client?.getRoomById(
      widget.chatTargetId,
    );
    if (room == null) return;
    final isMuted = room.pushRuleState == PushRuleState.dontNotify;
    if (isMuted) {
      room.setPushRuleState(PushRuleState.notify);
    } else {
      room.setPushRuleState(PushRuleState.dontNotify);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isMuted
              ? localeProvider.t('muted_off')
              : localeProvider.t('muted_on'),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showFriendProfile() {
    if (widget.chatTargetId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FriendProfileView(
          provider: widget.provider,
          roomId: widget.chatTargetId,
        ),
      ),
    );
  }

  void _showEncryptionInfo() {
    final matrix = widget.provider.matrix;
    final room = widget.chatTargetId.isNotEmpty
        ? matrix.client?.getRoomById(widget.chatTargetId)
        : null;
    final isEncrypted = room?.encrypted ?? false;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isEncrypted ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
              color: isEncrypted ? AppColors.accent : AppColors.warn(context),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isEncrypted
                  ? localeProvider.t('e2e_encrypted_short')
                  : localeProvider.t('not_encrypted_short'),
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isEncrypted) ...[
              Text(
                localeProvider.t('e2e_detail'),
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t('encrypt_verify'),
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<String?>(
                future: _getDeviceVerificationEmojis(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  final emojis = snap.data;
                  if (emojis == null || emojis.isEmpty) {
                    return Text(
                      t('verify_unavailable'),
                      style: TextStyle(
                        color: AppColors.textHint(context),
                        fontSize: 13,
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emojis,
                        style: TextStyle(fontSize: 28, letterSpacing: 4),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t('verify_instruction'),
                        style: TextStyle(
                          color: AppColors.textHint(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ] else ...[
              Text(
                localeProvider.t('no_e2e_detail'),
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              localeProvider.t('e2e_benefits'),
              style: TextStyle(
                color: AppColors.textHint(context),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          if (isEncrypted)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _startKeyVerification();
              },
              child: Text(
                t('verify_device'),
                style: TextStyle(color: AppColors.accent),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('got_it'), style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  void _startKeyVerification() async {
    try {
      final client = widget.provider.matrix.client;
      if (client == null || widget.chatTargetId.isEmpty) return;
      final deviceKeysList = client.userDeviceKeys[widget.chatTargetId];
      if (deviceKeysList == null || deviceKeysList.deviceKeys.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localeProvider.t('verify_unavailable')),
              backgroundColor: AppColors.sf(context),
            ),
          );
        }
        return;
      }
      final verification = await deviceKeysList.startVerification();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => KeyVerificationView(verification: verification),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localeProvider.t('verification_error')),
            backgroundColor: AppColors.sf(context),
          ),
        );
      }
    }
  }

  Future<String?> _getDeviceVerificationEmojis() async {
    try {
      final matrix = widget.provider.matrix;
      final client = matrix.client;
      if (client == null || widget.chatTargetId.isEmpty) return null;
      final room = client.getRoomById(widget.chatTargetId);
      if (room == null || !room.encrypted) return null;
      final fingerprint = client.fingerprintKey;
      final identity = client.identityKey;
      if (fingerprint.isEmpty && identity.isEmpty) return null;
      final parts = <String>[];
      if (fingerprint.isNotEmpty) {
        final fp = StringBuffer();
        for (var i = 0; i < fingerprint.length; i += 4) {
          if (i > 0) fp.write(' ');
          fp.write(
            fingerprint.substring(
              i,
              i + 4 > fingerprint.length ? fingerprint.length : i + 4,
            ),
          );
        }
        parts.add('${localeProvider.t('fingerprint_key')}: $fp');
      }
      if (identity.isNotEmpty) {
        final id = StringBuffer();
        for (var i = 0; i < identity.length; i += 4) {
          if (i > 0) id.write(' ');
          id.write(
            identity.substring(
              i,
              i + 4 > identity.length ? identity.length : i + 4,
            ),
          );
        }
        parts.add('${localeProvider.t('identity_key')}: $id');
      }
      return parts.join('\n');
    } catch (e, stackTrace) {
      AppLogger.instance.warning(
        'Operation failed',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<CachedPresence?> _getPresence() async {
    if (widget.chatTargetId.isEmpty) return null;
    final client = widget.provider.matrix.client;
    if (client == null) return null;
    final room = client.getRoomById(widget.chatTargetId);
    if (room == null) return null;
    final members = room.getParticipants();
    final otherUser = members.where((u) => u.id != client.userID).firstOrNull;
    if (otherUser == null) return null;
    try {
      return await client.fetchCurrentPresence(
        otherUser.id,
        fetchOnlyFromCached: true,
      );
    } catch (e, stackTrace) {
      AppLogger.instance.warning(
        'Operation failed',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  void _shareFriendConversation() {
    if (_friendMessages.isEmpty) return;
    final text = _friendMessages
        .map(
          (m) => m.isMe
              ? '${localeProvider.t('me')}：${m.content}'
              : '${widget.chatTargetName}：${m.content}',
        )
        .join('\n\n');
    SharePlus.instance.share(ShareParams(text: text));
  }

  void _clearFriendChat() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('clear_chat'),
          style: TextStyle(color: AppColors.textPrimary(context)),
        ),
        content: Text(
          t('clear_chat_confirm'),
          style: TextStyle(color: AppColors.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t('cancel'),
              style: TextStyle(color: AppColors.sec(context)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _friendMessages.clear());
            },
            child: Text(
              t('clear'),
              style: TextStyle(color: AppColors.dng(context)),
            ),
          ),
        ],
      ),
    );
  }

  void _showChatSearch() {
    final searchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final query = searchCtrl.text.toLowerCase();
            List<Map<String, dynamic>> results = [];
            if (query.isNotEmpty) {
              for (var i = 0; i < _friendMessages.length; i++) {
                if (_friendMessages[i].content.toLowerCase().contains(query)) {
                  results.add({
                    'index': i,
                    'content': _friendMessages[i].content,
                    'isMe': _friendMessages[i].isMe,
                  });
                }
              }
            }
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchCtrl,
                              autofocus: true,
                              style: TextStyle(
                                color: AppColors.textPrimary(context),
                                fontSize: 15,
                              ),
                              decoration: InputDecoration(
                                labelText: t('search_messages'),
                                hintStyle: TextStyle(
                                  color: AppColors.textDisabled(context),
                                ),
                                prefixIcon: Icon(
                                  LucideIcons.search,
                                  color: AppColors.textHint(context),
                                  size: 18,
                                ),
                                filled: true,
                                fillColor: AppColors.sf(context),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              onChanged: (_) => setModalState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              t('cancel'),
                              style: TextStyle(color: AppColors.sec(context)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (query.isNotEmpty && results.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          t('no_match_msg'),
                          style: TextStyle(
                            color: AppColors.textDisabled(context),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    if (results.isNotEmpty)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(ctx).size.height * 0.4,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: results.length,
                          itemBuilder: (ctx, i) {
                            final r = results[i];
                            final content = r['content'] as String;
                            final highlightStart = content
                                .toLowerCase()
                                .indexOf(query);
                            return ListTile(
                              dense: true,
                              title: _buildHighlightedText(
                                content,
                                highlightStart,
                                query.length,
                              ),
                              subtitle: Text(
                                r['isMe'] as bool
                                    ? localeProvider.t('me')
                                    : widget.chatTargetName,
                                style: TextStyle(
                                  color: AppColors.textDisabled(context),
                                  fontSize: 11,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHighlightedText(String text, int start, int length) {
    if (start < 0) {
      return Text(
        text,
        style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14),
      );
    }
    final before = text.substring(0, start);
    final match = text.substring(start, start + length);
    final after = text.substring(start + length);
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14),
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    IconData icon,
    String text, {
    bool isDanger = false,
  }) {
    return PopupMenuItem<String>(
      value: text,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDanger ? AppColors.dng(context) : AppColors.sec(context),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: isDanger
                  ? AppColors.dng(context)
                  : AppColors.textPrimary(context),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<BoxShadow> _buildGlowShadows(double g) {
    if (g > 0.01) {
      return [
        BoxShadow(
          color: AppColors.accent.withValues(alpha: 0.5 * g),
          blurRadius: 24,
          offset: const Offset(0, -4),
        ),
        BoxShadow(
          color: AppColors.accent.withValues(alpha: 0.3 * g),
          blurRadius: 8,
        ),
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildChatContent()),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onClose,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.sfAlt(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    LucideIcons.arrowLeft,
                    size: 18,
                    color: AppColors.sec(context),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.chatTargetName,
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_isOtherTyping)
                      Text(
                        t('typing'),
                        style: TextStyle(color: AppColors.accent, fontSize: 11),
                      )
                    else
                      FutureBuilder<CachedPresence?>(
                        future: _presenceFuture,
                        builder: (context, snap) {
                          final presence = snap.data;
                          if (presence == null) {
                            return Text(
                              '@${widget.chatTargetId}',
                              style: TextStyle(
                                color: AppColors.textTertiary(context),
                                fontSize: 11,
                              ),
                            );
                          }
                          final isOnline = presence.currentlyActive == true;
                          final status = isOnline
                              ? localeProvider.t('online')
                              : localeProvider.t('offline');
                          return Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isOnline
                                      ? AppColors.accent
                                      : AppColors.iconGray(context),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                status,
                                style: TextStyle(
                                  color: isOnline
                                      ? AppColors.accent
                                      : AppColors.iconGray(context),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
              ListenableBuilder(
                listenable: widget.provider.matrix,
                builder: (context, _) {
                  final room = widget.chatTargetId.isNotEmpty
                      ? widget.provider.matrix.client?.getRoomById(
                          widget.chatTargetId,
                        )
                      : null;
                  final isEncrypted = room?.encrypted ?? false;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _showEncryptionInfo,
                    child: Icon(
                      isEncrypted
                          ? LucideIcons.shieldCheck
                          : LucideIcons.shieldAlert,
                      size: 18,
                      color: isEncrypted
                          ? AppColors.accent
                          : AppColors.warn(context),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showFriendChatMenu(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.sfAlt(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    LucideIcons.moreVertical,
                    size: 18,
                    color: AppColors.sec(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatContent() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _friendMessages.length,
      itemBuilder: (_, i) {
        final msg = _friendMessages[i];
        final isLast = i == _friendMessages.length - 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Align(
            alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: msg.isMe ? () => _showMessageActions(i) : null,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: msg.isImage || msg.isFile
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: msg.isMe
                      ? AppColors.sfHover(context)
                      : AppColors.sf(context),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: msg.isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (msg.isVoice && msg.url != null)
                      VoiceMessagePlayer(url: msg.url!, isMe: msg.isMe)
                    else if (msg.isImage && msg.url != null)
                      _buildImageBubble(msg)
                    else if (msg.isFile)
                      _buildFileBubble(msg)
                    else ...[
                      Text(
                        msg.content,
                        style: TextStyle(
                          color: msg.isMe
                              ? AppColors.textPrimary(context)
                              : AppColors.textSecondary(context),
                          fontSize: 15,
                          fontWeight: msg.isMe
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                      _buildLinkPreviews(msg.content),
                    ],
                    if (msg.isMe) ...[
                      const SizedBox(height: 4),
                      Builder(
                        builder: (ctx) {
                          final client = widget.provider.matrix.client;
                          final room = client?.getRoomById(widget.chatTargetId);
                          final isRead =
                              room != null && room.notificationCount == 0;
                          if (isRead) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.checkCheck,
                                  size: 14,
                                  color: AppColors.acc(
                                    context,
                                  ).withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  t('read'),
                                  style: TextStyle(
                                    color: AppColors.acc(
                                      context,
                                    ).withValues(alpha: 0.7),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            );
                          }
                          return Icon(
                            LucideIcons.check,
                            size: 14,
                            color: AppColors.iconGray(context),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageBubble(FriendMessageData msg) {
    final mxcUrl = msg.url;
    if (mxcUrl == null) {
      return Text(
        msg.content,
        style: TextStyle(color: AppColors.textPrimary(context), fontSize: 14),
      );
    }
    final httpUrl = widget.provider.matrix.getMediaUrl(mxcUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (httpUrl != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ImageViewer(imageUrl: httpUrl)),
            );
          }
        },
        child: httpUrl != null
            ? CachedNetworkImage(
                imageUrl: httpUrl,
                width: 200,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  width: 200,
                  height: 150,
                  color: AppColors.sfAlt(context),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ),
                errorWidget: (_, _, _) => Container(
                  width: 200,
                  height: 80,
                  color: AppColors.sfAlt(context),
                  child: Icon(
                    LucideIcons.imageOff,
                    color: AppColors.iconGray(context),
                  ),
                ),
              )
            : Container(
                width: 200,
                height: 80,
                color: AppColors.sfAlt(context),
                child: Center(
                  child: Icon(
                    LucideIcons.image,
                    color: AppColors.iconGray(context),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildFileBubble(FriendMessageData msg) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        HapticService.lightImpact();
        final url = msg.url ?? '';
        if (url.isEmpty) return;
        await FileDownloadService.instance.downloadMatrixFile(
          mxcUrl: url,
          fileName: msg.content,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.sfAlt(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                LucideIcons.download,
                color: AppColors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                msg.content,
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkPreviews(String text) {
    final urlRegex = RegExp(r'https?://[^\s<>"{}|\\^`\[\]]+');
    final matches = urlRegex.allMatches(text);
    if (matches.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: matches.map((match) {
        final url = text.substring(match.start, match.end);
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: LinkPreviewCard(url: url),
        );
      }).toList(),
    );
  }

  Widget _buildInputArea() {
    final hasText = _textController.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.maxWidth - 32),
          child: AnimatedBuilder(
            animation: _listeningGlow,
            builder: (context, _) {
              final g = _listeningGlow.value;
              final glowShadows = _buildGlowShadows(g);
              final isFocused = _focusNode.hasFocus;
              final borderColor = isFocused
                  ? AppColors.accent
                  : g > 0.5
                  ? AppColors.accent.withValues(alpha: 0.3)
                  : AppColors.divider(context);
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: glowShadows,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.sf(context),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: borderColor),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          onSubmitted: (_) => _sendFriendMessage(),
                          onChanged: (_) {
                            setState(() {});
                            _sendTypingNotice();
                          },
                          decoration: InputDecoration(
                            labelText: t('input_message'),
                            hintStyle: TextStyle(
                              color: AppColors.textHint(context),
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                        ),
                      ),
                      _buildInputButtons(hasText),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInputButtons(bool hasText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: _isListening
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    key: const ValueKey('stop'),
                    onTap: _toggleListening,
                    child: Semantics(
                      button: true,
                      label: localeProvider.t('stop_listening'),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary(context),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  )
                : Row(
                    key: const ValueKey('normal-left'),
                    children: [
                      _circleBtn(
                        LucideIcons.plus,
                        onTap: () => _showPlusMenu(),
                      ),
                    ],
                  ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) {
              if (child.key == const ValueKey('confirm')) {
                return ScaleTransition(
                  scale: CurvedAnimation(
                    parent: anim,
                    curve: Curves.elasticOut,
                  ),
                  child: RotationTransition(
                    turns: Tween(begin: -0.12, end: 0.0).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                );
              }
              return ScaleTransition(
                scale: anim,
                child: FadeTransition(opacity: anim, child: child),
              );
            },
            child: _isListening
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    key: const ValueKey('confirm'),
                    onTap: _toggleListening,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Icon(
                        LucideIcons.check,
                        size: 18,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  )
                : Row(
                    key: const ValueKey('normal-right'),
                    children: [
                      VoiceRecorderButton(
                        onSend: (path, duration) =>
                            _sendVoiceMessage(path, duration),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: hasText ? _sendFriendMessage : () {},
                        child: Semantics(
                          button: true,
                          label: hasText ? 'Send message' : 'Voice input',
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(17),
                            ),
                            child: hasText
                                ? Icon(
                                    LucideIcons.arrowUp,
                                    size: 18,
                                    color: AppColors.textPrimary(context),
                                  )
                                : const VoiceBarsIcon(),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.sfHover(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, size: 18, color: AppColors.sec(context)),
      ),
    );
  }
}
