import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io' if (dart.library.html) '';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';
import '../theme/wallpaper_presets.dart';
import '../../core/app_provider.dart';
import '../../core/analytics_service.dart';
import '../../core/app_logger.dart';
import '../../core/voice_service.dart';
import '../../core/database_service.dart';
import '../../core/matrix/matrix_service.dart';
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

  static Future<void> flushOutbox() async {
    final db = DatabaseService.instance;
    final outbox = db.getData('outbox');
    if (outbox == null) return;
    final messages = List<Map<String, dynamic>>.from(
      outbox['messages'] as List? ?? [],
    );
    if (messages.isEmpty) return;
    final remaining = <Map<String, dynamic>>[];
    for (final msg in messages) {
      final roomId = msg['roomId'] as String?;
      final text = msg['text'] as String?;
      if (roomId == null || text == null) continue;
      try {
        final matrix = MatrixService.instance;
        if (matrix.isLoggedIn) {
          final room = matrix.client?.getRoomById(roomId);
          if (room != null) {
            await room.sendTextEvent(text);
            continue;
          }
        }
        remaining.add(msg);
      } catch (e) {
        AppLogger.instance.warning('Outbox flush failed', error: e);
        remaining.add(msg);
      }
    }
    if (remaining.isEmpty) {
      db.deleteData('outbox');
    } else {
      db.putData('outbox', {'messages': remaining});
    }
  }
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
  Timeline? _timeline;
  bool _isLoadingHistory = false;
  bool _canLoadMore = true;
  FriendMessageData? _replyingTo;
  bool _showEmojiPicker = false;
  StreamSubscription? _voiceResultSub;

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
      if (!mounted) return;
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle == AppLifecycleState.paused) return;
      setState(() {
        _presenceFuture = _getPresence();
      });
    });
    _loadMatrixMessages(widget.chatTargetId);
    _markRoomAsRead(widget.chatTargetId);
    _scrollController.addListener(_onScroll);
    _restoreDraft();
    _voiceResultSub = VoiceService.instance.onFinalResult.listen((text) {
      if (!mounted || text.isEmpty) return;
      final current = _textController.text;
      _textController.text = current.isEmpty ? text : '$current $text';
      _textController.selection = TextSelection.collapsed(
        offset: _textController.text.length,
      );
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant FriendChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider.matrix != widget.provider.matrix) {
      oldWidget.provider.matrix.removeListener(_onMatrixChanged);
      widget.provider.matrix.addListener(_onMatrixChanged);
    }
    if (oldWidget.chatTargetId != widget.chatTargetId) {
      _saveDraft();
      _timeline?.dispose();
      _timeline = null;
      _loadMatrixMessages(widget.chatTargetId);
      _markRoomAsRead(widget.chatTargetId);
      _restoreDraft();
      _presenceFuture = _getPresence();
    }
  }

  void _restoreDraft() {
    final db = DatabaseService.instance;
    final draft = db.getData('draft_${widget.chatTargetId}');
    if (draft != null) {
      final text = draft['text'] as String? ?? '';
      if (text.isNotEmpty) {
        _textController.text = text;
      }
    }
  }

  void _saveDraft() {
    final db = DatabaseService.instance;
    final text = _textController.text.trim();
    if (text.isEmpty) {
      db.deleteData('draft_${widget.chatTargetId}');
    } else {
      db.putData('draft_${widget.chatTargetId}', {'text': text});
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels <= 100 &&
        _canLoadMore &&
        !_isLoadingHistory) {
      _loadMoreHistory();
    }
  }

  @override
  void dispose() {
    _saveDraft();
    _voiceResultSub?.cancel();
    _presenceTimer?.cancel();
    _timeline?.dispose();
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _listeningGlow.dispose();
    widget.provider.matrix.removeListener(_onMatrixChanged);
    super.dispose();
  }

  void _onMatrixChanged() {
    if (!mounted) return;
    if (widget.chatTargetId.isEmpty) return;
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
          final eventId = event.eventId;
          if (_friendMessages.any((m) => m.eventId == eventId)) continue;
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
                eventId: eventId,
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
      _timeline = await room.getTimeline();
      if (!mounted) return;
      final timeline = _timeline;
      if (timeline == null) return;
      setState(() {
        _friendMessages.clear();
        _friendMessages.addAll(_parseTimelineEvents(timeline));
        _canLoadMore = timeline.canRequestHistory;
      });
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'App error',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _loadMoreHistory() async {
    final timeline = _timeline;
    if (timeline == null || !timeline.canRequestHistory || _isLoadingHistory)
      return;
    setState(() => _isLoadingHistory = true);
    try {
      await timeline.requestHistory(historyCount: 50);
      if (!mounted) return;
      final prevCount = _friendMessages.length;
      setState(() {
        _friendMessages.addAll(_parseTimelineEvents(timeline));
        _canLoadMore = timeline.canRequestHistory;
        _isLoadingHistory = false;
      });
      final addedCount = _friendMessages.length - prevCount;
      if (addedCount > 0 && _scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scrollController.hasClients) return;
          final max = _scrollController.position.maxScrollExtent;
          final approxItemHeight = 60.0;
          _scrollController.jumpTo(
            max +
                addedCount * approxItemHeight -
                (max - _scrollController.position.pixels),
          );
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  List<FriendMessageData> _parseTimelineEvents(Timeline timeline) {
    final matrix = widget.provider.matrix;
    final messages = <FriendMessageData>[];
    final eventMap = <String, Event>{};
    for (final event in timeline.events) {
      eventMap[event.eventId] = event;
    }
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
        final replyToId = event.content['m.relates_to'] is Map
            ? (event.content['m.relates_to'] as Map)['m.in_reply_to'] is Map
                  ? (event.content['m.relates_to']
                            as Map)['m.in_reply_to']['event_id']
                        as String?
                  : null
            : null;
        String? replyToContent;
        String? replyToSender;
        if (replyToId != null) {
          final replyEvent = eventMap[replyToId];
          if (replyEvent != null) {
            replyToContent = replyEvent.body;
            replyToSender = replyEvent.senderId;
          }
        }
        final formattedContent = event.content['formatted_body'] as String?;
        messages.add(
          FriendMessageData(
            isMe: isMe,
            content: event.body,
            eventId: event.eventId,
            msgType: msgType,
            url: url,
            audioDuration: audioDuration,
            replyToId: replyToId,
            replyToContent: replyToContent,
            replyToSender: replyToSender,
            formattedContent: formattedContent,
            senderId: event.senderId,
            timestamp: event.originServerTs,
            isEdited:
                (event.content['m.new_content'] != null ||
                (event.content['m.relates_to']
                        as Map<String, dynamic>?)?['rel_type'] ==
                    'm.replace'),
            forwardFrom: event.content['formatted_body'] != null
                ? _extractForwardFrom(
                    event.content['formatted_body'] as String?,
                  )
                : null,
          ),
        );
      }
    }
    return messages;
  }

  void _toggleListening() async {
    final voice = VoiceService.instance;
    if (_isListening) {
      await voice.stopListening();
      if (!mounted) return;
      setState(() => _isListening = false);
      _listeningGlow.reverse();
    } else {
      final ok = await voice.startListening();
      if (!ok || !mounted) return;
      setState(() => _isListening = true);
      _listeningGlow.forward();
    }
  }

  DateTime? _lastTypingNotice;

  void _sendTypingNotice() {
    if (widget.chatTargetId.isEmpty) return;
    final now = DateTime.now();
    final lastNotice = _lastTypingNotice;
    if (lastNotice != null &&
        now.difference(lastNotice).inSeconds < 3) {
      return;
    }
    _lastTypingNotice = now;
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
    _saveDraft();

    final matrix = widget.provider.matrix;
    if (matrix.isLoggedIn && widget.chatTargetId.isNotEmpty) {
      final room = matrix.client?.getRoomById(widget.chatTargetId);
      if (room != null) {
        final content = <String, dynamic>{'msgtype': 'm.text', 'body': text};
        final replyingTo = _replyingTo;
        if (replyingTo != null && replyingTo.eventId != null) {
          content['m.relates_to'] = {
            'm.in_reply_to': {'event_id': replyingTo.eventId},
          };
          final replyBody = replyingTo.content;
          final replySender = replyingTo.senderId ?? '';
          content['body'] = '> <$replySender> $replyBody\n\n$text';
        }
        room.sendEvent(content, type: EventTypes.Message).catchError((e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localeProvider.t('send_failed')),
                backgroundColor: AppColors.dng(context),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });
        AnalyticsService.instance.logSendMessage(type: 'text');
      } else {
        _enqueueOutbox(text);
      }
      setState(() => _replyingTo = null);
    } else {
      _enqueueOutbox(text);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollToLatest();
    });
  }

  void _enqueueOutbox(String text) {
    final db = DatabaseService.instance;
    final outbox = db.getData('outbox') ?? {'messages': <Map>[]};
    final messages = List<Map<String, dynamic>>.from(
      outbox['messages'] as List? ?? [],
    );
    messages.add({
      'roomId': widget.chatTargetId,
      'text': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    db.putData('outbox', {'messages': messages});
    setState(() {
      _friendMessages.add(
        FriendMessageData(isMe: true, content: text, timestamp: DateTime.now()),
      );
    });
  }

  void _toggleEmojiPicker() {
    setState(() => _showEmojiPicker = !_showEmojiPicker);
    if (_showEmojiPicker) {
      _focusNode.unfocus();
    }
  }

  void _insertEmoji(String emoji) {
    final text = _textController.text;
    final sel = _textController.selection;
    final start = sel.start >= 0 ? sel.start : text.length;
    final end = sel.end >= 0 ? sel.end : text.length;
    final newText = text.replaceRange(start, end, emoji);
    _textController.text = newText;
    _textController.selection = TextSelection.collapsed(
      offset: start + emoji.length,
    );
    setState(() {});
  }

  Widget _buildEmojiPicker() {
    if (!_showEmojiPicker) return const SizedBox.shrink();
    const allEmojis = [
      '😀', '😂', '🥹', '😊', '😍', '🥰', '😘', '😜', '🤪', '😎',
      '🤔', '🤗', '😏', '😌', '🥳', '😇', '🤩', '😋', '🤭', '🫠',
      '👍', '👎', '❤️', '🔥', '💯', '✨', '🎉', '💪', '🙏', '👋',
      '😢', '😭', '😤', '🤬', '😱', '🫣', '🥺', '😓', '🙄', '💀',
      '⭐', '🌟', '💫', '🌈', '☀️', '🌙', '⚡', '💎', '🎵', '🎶',
    ];
    return Container(
      height: 220,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        border: Border(
          top: BorderSide(color: AppColors.divider(context), width: 0.5),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 2,
        runSpacing: 2,
        children: allEmojis.map((emoji) {
          return GestureDetector(
            onTap: () => _insertEmoji(emoji),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _sendVoiceMessage(String path, Duration duration) async {
    try {
      if (kIsWeb) return;
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
              leading: Icon(LucideIcons.reply, color: AppColors.acc(context)),
              title: Text(
                t('reply'),
                style: TextStyle(color: AppColors.textPrimary(context)),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() => _replyingTo = msg);
                _focusNode.requestFocus();
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.forward, color: AppColors.sec(context)),
              title: Text(
                t('forward_message'),
                style: TextStyle(color: AppColors.textPrimary(context)),
              ),
              onTap: () {
                Navigator.pop(context);
                _forwardMessage(msg);
              },
            ),
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
                    backgroundColor: AppColors.acc(context),
                    duration: const Duration(milliseconds: 1500),
                  ),
                );
              },
            ),
            if (msg.isMe) ...[
              ListTile(
                leading: Icon(
                  LucideIcons.pencil,
                  color: AppColors.sec(context),
                ),
                title: Text(
                  t('edit'),
                  style: TextStyle(color: AppColors.textPrimary(context)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(msg);
                },
              ),
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
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _forwardMessage(FriendMessageData msg) {
    final matrix = widget.provider.matrix;
    final client = matrix.client;
    if (client == null) return;
    final rooms = client.rooms
        .where((r) => r.id != widget.chatTargetId)
        .toList();
    if (rooms.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('no_chats_to_forward'))));
      return;
    }
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                t('forward_to'),
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: rooms.length,
                itemBuilder: (_, i) {
                  final room = rooms[i];
                  return ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.accBg(context),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          room.name.isNotEmpty
                              ? room.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: AppColors.acc(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      room.name,
                      style: TextStyle(color: AppColors.textPrimary(context)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        await room.sendTextEvent(msg.content);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(t('forwarded')),
                              backgroundColor: AppColors.ok(context),
                              duration: const Duration(milliseconds: 1500),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: AppColors.dng(context),
                            ),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _recallMessage(int index) async {
    final msg = _friendMessages[index];
    if (msg.eventId != null && widget.chatTargetId.isNotEmpty) {
      final room = widget.provider.matrix.client?.getRoomById(
        widget.chatTargetId,
      );
      if (room != null) {
        try {
          final eventId = msg.eventId;
          if (eventId != null) {
            await room.redactEvent(eventId);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localeProvider.t('send_failed')),
                backgroundColor: AppColors.dng(context),
              ),
            );
          }
          return;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _friendMessages[index] = FriendMessageData(
        isMe: msg.isMe,
        content: t('message_recalled'),
        eventId: msg.eventId,
      );
    });
  }

  void _editMessage(FriendMessageData msg) {
    if (msg.eventId == null) return;
    final editCtrl = TextEditingController(text: msg.content);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        title: Text(
          t('edit'),
          style: TextStyle(color: AppColors.textPrimary(context)),
        ),
        content: TextField(
          controller: editCtrl,
          style: TextStyle(color: AppColors.textPrimary(context), fontSize: 15),
          autofocus: true,
          maxLines: 5,
          minLines: 1,
          maxLength: 4096,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.bg(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t('cancel'),
              style: TextStyle(color: AppColors.textTertiary(context)),
            ),
          ),
          TextButton(
            onPressed: () async {
              final newText = editCtrl.text.trim();
              Navigator.pop(context);
              if (newText.isEmpty || newText == msg.content) return;
              final room = widget.provider.matrix.client?.getRoomById(
                widget.chatTargetId,
              );
              if (room == null) return;
              try {
                final content = <String, dynamic>{
                  'msgtype': 'm.text',
                  'body': '* $newText',
                  'm.new_content': {'msgtype': 'm.text', 'body': newText},
                  'm.relates_to': {
                    'rel_type': 'm.replace',
                    'event_id': msg.eventId,
                  },
                };
                await room.sendEvent(content, type: EventTypes.Message);
                if (!mounted) return;
                setState(() {
                  final idx = _friendMessages.indexWhere(
                    (m) => m.eventId == msg.eventId,
                  );
                  if (idx >= 0) {
                    _friendMessages[idx] = FriendMessageData(
                      isMe: true,
                      content: newText,
                      eventId: msg.eventId,
                      msgType: msg.msgType,
                    );
                  }
                });
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppColors.dng(context),
                    ),
                  );
                }
              }
            },
            child: Text(
              t('save'),
              style: TextStyle(color: AppColors.acc(context)),
            ),
          ),
        ],
      ),
    );
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
                    onTap: _startVideoCall,
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
      if (file.path != null) {
        _sendFileMessage(localeProvider.t('file_msg'), file.name, file.path);
      }
    }
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
    AnalyticsService.instance.logVoiceCall();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CallScreen()));
  }

  void _startVideoCall() {
    final client = widget.provider.matrix.client;
    if (client == null) return;
    final room = client.getRoomById(widget.chatTargetId);
    if (room == null) return;
    final remoteMembers = room.getParticipants();
    final remoteUser = remoteMembers
        .where((m) => m.id != client.userID)
        .firstOrNull;
    if (remoteUser == null) return;

    CallService.instance.initiateCallWithVideo(
      room.id,
      remoteUser.id,
      isVideo: true,
    );
    AnalyticsService.instance.logVoiceCall();
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
              color: isEncrypted
                  ? AppColors.acc(context)
                  : AppColors.warn(context),
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
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
                  if (snap.hasError) {
                    return Text(
                      t('verify_unavailable'),
                      style: TextStyle(
                        color: AppColors.textHint(context),
                        fontSize: 13,
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
                style: TextStyle(color: AppColors.acc(context)),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t('got_it'),
              style: TextStyle(color: AppColors.acc(context)),
            ),
          ),
        ],
      ),
    );
  }

  void _startKeyVerification() async {
    try {
      final client = widget.provider.matrix.client;
      if (client == null || widget.chatTargetId.isEmpty) return;
      final room = client.getRoomById(widget.chatTargetId);
      if (room == null) return;
      final members = room.getParticipants();
      final otherMember = members.where((u) => u.id != client.userID).firstOrNull;
      if (otherMember == null) {
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
      final deviceKeysList = client.userDeviceKeys[otherMember.id];
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
        'App error',
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
        'App error',
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
    try {
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
                  if (_friendMessages[i].content.toLowerCase().contains(
                    query,
                  )) {
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
                                maxLength: 256,
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
    } finally {
      searchCtrl.dispose();
    }
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
              color: AppColors.acc(context),
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
          color: AppColors.acc(context).withValues(alpha: 0.5 * g),
          blurRadius: 24,
          offset: const Offset(0, -4),
        ),
        BoxShadow(
          color: AppColors.acc(context).withValues(alpha: 0.3 * g),
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
        _buildEmojiPicker(),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_isOtherTyping)
                      Text(
                        t('typing'),
                        style: TextStyle(
                          color: AppColors.acc(context),
                          fontSize: 11,
                        ),
                      )
                    else
                      FutureBuilder<CachedPresence?>(
                        future: _presenceFuture,
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return SizedBox(
                              width: 60,
                              height: 14,
                              child: LinearProgressIndicator(
                                borderRadius: BorderRadius.circular(2),
                                backgroundColor: AppColors.sfActive(context),
                              ),
                            );
                          }
                          if (snap.hasError || !snap.hasData) {
                            return Text(
                              '@${widget.chatTargetId}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textTertiary(context),
                                fontSize: 11,
                              ),
                            );
                          }
                          final presence = snap.data;
                          if (presence == null) return const SizedBox.shrink();
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
                                      ? AppColors.acc(context)
                                      : AppColors.iconGray(context),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                status,
                                style: TextStyle(
                                  color: isOnline
                                      ? AppColors.acc(context)
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
                          ? AppColors.acc(context)
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

  BoxDecoration? _getWallpaperDecoration() {
    final db = DatabaseService.instance;
    final data = db.getData('chat_wallpaper');
    if (data == null) return null;
    final id = data['id'] as String?;
    if (id == null || id == 'none') return null;
    switch (id) {
      case 'gradient_sunset':
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: WallpaperPresets.warm,
          ),
        );
      case 'gradient_ocean':
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: WallpaperPresets.ocean,
          ),
        );
      case 'gradient_forest':
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: WallpaperPresets.forest,
          ),
        );
      case 'gradient_night':
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: WallpaperPresets.dark,
          ),
        );
      case 'gradient_rose':
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: WallpaperPresets.pink,
          ),
        );
      case 'solid_dark':
        return const BoxDecoration(color: WallpaperPresets.darkBg);
      case 'solid_midnight':
        return const BoxDecoration(color: WallpaperPresets.darkBlueBg);
      default:
        return null;
    }
  }

  Widget _buildChatContent() {
    final wallpaper = _getWallpaperDecoration();
    if (_friendMessages.isEmpty) {
      return Container(
        decoration: wallpaper,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.messageCircle,
                size: 48,
                color: AppColors.mut(context),
              ),
              const SizedBox(height: 12),
              Text(
                localeProvider.t('no_messages_yet'),
                style: TextStyle(
                  color: AppColors.textTertiary(context),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      decoration: wallpaper,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _friendMessages.length,
        itemBuilder: (_, i) {
          final msg = _friendMessages[i];
          final showDateHeader =
              i == 0 || _shouldShowDateSeparator(_friendMessages[i - 1], msg);
          return Column(
            children: [
              if (showDateHeader)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.sfAlt(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatDateHeader(msg.timestamp),
                        style: TextStyle(
                          color: AppColors.textTertiary(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Align(
                  alignment: msg.isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onLongPress: () => _showMessageActions(i),
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      padding: msg.isImage || msg.isFile
                          ? EdgeInsets.zero
                          : const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                      decoration: BoxDecoration(
                        color: msg.isMe
                            ? AppColors.acc(context)
                            : AppColors.sf(context),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: msg.isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (msg.isVoice && msg.url != null)
                            VoiceMessagePlayer(url: msg.url ?? '', isMe: msg.isMe)
                          else if (msg.isImage && msg.url != null)
                            _buildImageBubble(msg)
                          else if (msg.isFile)
                            _buildFileBubble(msg)
                          else ...[
                            if (msg.hasReply) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: msg.isMe
                                      ? AppColors.bg(
                                          context,
                                        ).withValues(alpha: 0.15)
                                      : AppColors.accBg(context),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border(
                                    left: BorderSide(
                                      color: AppColors.acc(context),
                                      width: 3,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.replyToSender ?? '',
                                      style: TextStyle(
                                        color: AppColors.acc(context),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      msg.replyToContent ?? '',
                                      style: TextStyle(
                                        color: msg.isMe
                                            ? AppColors.bg(
                                                context,
                                              ).withValues(alpha: 0.7)
                                            : AppColors.textTertiary(context),
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (msg.forwardFrom != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: msg.isMe
                                      ? AppColors.bg(
                                          context,
                                        ).withValues(alpha: 0.1)
                                      : AppColors.sfAlt(context),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.forward,
                                      size: 12,
                                      color: AppColors.textTertiary(context),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${t('forwarded_from')} ${msg.forwardFrom}',
                                      style: TextStyle(
                                        color: AppColors.textTertiary(context),
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            _buildMessageContent(msg),
                            _buildLinkPreviews(msg.content),
                          ],
                          if (msg.timestamp != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatMessageTime(msg.timestamp ?? DateTime.now()),
                                    style: TextStyle(
                                      color: msg.isMe
                                          ? AppColors.bg(
                                              context,
                                            ).withValues(alpha: 0.5)
                                          : AppColors.textDisabled(context),
                                      fontSize: 10,
                                    ),
                                  ),
                                  if (msg.isEdited) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '(${t('edited')})',
                                      style: TextStyle(
                                        color: msg.isMe
                                            ? AppColors.bg(
                                                context,
                                              ).withValues(alpha: 0.4)
                                            : AppColors.textDisabled(context),
                                        fontSize: 9,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          if (msg.isMe) ...[
                            const SizedBox(height: 4),
                            Builder(
                              builder: (ctx) {
                                final client = widget.provider.matrix.client;
                                final room = client?.getRoomById(
                                  widget.chatTargetId,
                                );
                                if (room == null) {
                                  return Icon(
                                    LucideIcons.check,
                                    size: 14,
                                    color: AppColors.iconGray(context),
                                  );
                                }
                                final isRead = _isMessageRead(room, msg);
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
              ),
            ],
          );
        },
      ),
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
                memCacheWidth: 400,
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
                        color: AppColors.acc(context),
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
                color: AppColors.acc(context),
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

  String? _extractForwardFrom(String? formattedBody) {
    if (formattedBody == null) return null;
    final forwardMatch = RegExp(
      r'Forwarded from\s+([^<]+)',
    ).firstMatch(formattedBody);
    return forwardMatch?.group(1)?.trim();
  }

  bool _shouldShowDateSeparator(
    FriendMessageData prev,
    FriendMessageData curr,
  ) {
    final prevTs = prev.timestamp;
    final currTs = curr.timestamp;
    if (prevTs == null || currTs == null) return false;
    return _dateOnly(prevTs) != _dateOnly(currTs);
  }

  String _dateOnly(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _formatDateHeader(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final today = _dateOnly(now);
    final yesterday = _dateOnly(now.subtract(const Duration(days: 1)));
    final dateStr = _dateOnly(dt);
    if (dateStr == today) return t('today');
    if (dateStr == yesterday) return t('yesterday');
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  String _formatMessageTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildMessageContent(FriendMessageData msg) {
    final displayText = _stripReplyFallback(msg.content);
    final hasFormatting =
        displayText.contains('**') ||
        displayText.contains('*') ||
        displayText.contains('`') ||
        displayText.contains('```') ||
        displayText.contains('#') ||
        displayText.contains('[') ||
        displayText.contains('>') ||
        msg.formattedContent != null;

    if (hasFormatting) {
      return MarkdownBody(
        data: displayText,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            color: msg.isMe
                ? AppColors.bg(context)
                : AppColors.textSecondary(context),
            fontSize: 15,
            fontWeight: msg.isMe ? FontWeight.w500 : FontWeight.w400,
          ),
          code: TextStyle(
            color: msg.isMe ? AppColors.bg(context) : AppColors.acc(context),
            backgroundColor: msg.isMe
                ? AppColors.bg(context).withValues(alpha: 0.15)
                : AppColors.sfAlt(context),
            fontSize: 13,
          ),
          codeblockDecoration: BoxDecoration(
            color: msg.isMe
                ? AppColors.bg(context).withValues(alpha: 0.1)
                : AppColors.sfAlt(context),
            borderRadius: BorderRadius.circular(8),
          ),
          blockquote: TextStyle(
            color: msg.isMe
                ? AppColors.bg(context).withValues(alpha: 0.7)
                : AppColors.textTertiary(context),
            fontSize: 14,
          ),
          blockquoteDecoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: AppColors.acc(context), width: 3),
            ),
          ),
          listBullet: TextStyle(
            color: msg.isMe
                ? AppColors.bg(context)
                : AppColors.textSecondary(context),
            fontSize: 15,
          ),
        ),
      );
    }

    return Text(
      displayText,
      style: TextStyle(
        color: msg.isMe
            ? AppColors.bg(context)
            : AppColors.textSecondary(context),
        fontSize: 15,
        fontWeight: msg.isMe ? FontWeight.w500 : FontWeight.w400,
      ),
    );
  }

  String _stripReplyFallback(String content) {
    final lines = content.split('\n');
    final result = <String>[];
    var pastFallback = false;
    for (final line in lines) {
      if (!pastFallback && line.startsWith('> ')) {
        continue;
      }
      if (!pastFallback && !line.startsWith('> ')) {
        pastFallback = true;
      }
      if (pastFallback && line.isEmpty && result.isEmpty) {
        continue;
      }
      result.add(line);
    }
    return result.join('\n').trim();
  }

  bool _isMessageRead(Room room, FriendMessageData msg) {
    if (msg.eventId == null) return false;
    if (!msg.isMe) return false;
    try {
      final readMarkers = room.readMarkers;
      final mRead = readMarkers['m.read'];
      if (mRead == null) return false;
      final timeline = room.timeline;
      if (timeline == null) return false;
      final events = timeline.events;
      if (events.isEmpty) return false;
      final msgIndex = events.indexWhere((e) => e.eventId == msg.eventId);
      final readIndex = events.indexWhere((e) => e.eventId == mRead);
      if (msgIndex == -1 || readIndex == -1) return false;
      return readIndex >= msgIndex;
    } catch (e) {
      AppLogger.instance.debug('Read receipt check failed', error: e);
      return false;
    }
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
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding > 0 ? bottomPadding : max(24, safeBottom)),
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
                  ? AppColors.acc(context)
                  : g > 0.5
                  ? AppColors.acc(context).withValues(alpha: 0.3)
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
                      if (_replyingTo != null)
                        Container(
                          margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accBg(context),
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              left: BorderSide(
                                color: AppColors.acc(context),
                                width: 3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t('replying_to'),
                                      style: TextStyle(
                                        color: AppColors.acc(context),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _replyingTo?.content ?? '',
                                      style: TextStyle(
                                        color: AppColors.textTertiary(context),
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _replyingTo = null),
                                child: Icon(
                                  LucideIcons.x,
                                  size: 16,
                                  color: AppColors.iconGray(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          maxLength: 4096,
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
                        color: AppColors.acc(context),
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
                      IconButton(
                        icon: Icon(
                          LucideIcons.smile,
                          size: 22,
                          color: AppColors.sec(context),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: () => _toggleEmojiPicker(),
                      ),
                      const SizedBox(width: 4),
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
                          label: hasText
                              ? localeProvider.t('send_message_semantic')
                              : localeProvider.t('voice_input_semantic'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.acc(context),
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
