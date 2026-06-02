import '../../core/di/app_di.dart';
import '../../core/matrix/matrix_cubit.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:matrix/matrix.dart';
import '../../core/app_logger.dart';
import '../../core/voice_service.dart';
import '../../core/database_service.dart';
import '../theme/app_colors.dart';
import '../theme/locale_cubit.dart';
import 'home_components.dart';
import 'chat/chat_components.dart';
import 'chat/friend_chat_matrix_handler.dart';
import 'chat/friend_chat_input_handler.dart';
import 'chat/friend_chat_content_view.dart';
import 'chat/friend_chat_encryption.dart';
import 'chat/friend_chat_menu_actions.dart';
import 'chat/friend_chat_message_actions.dart';
import 'chat/friend_chat_message_sender.dart';
import 'chat/friend_chat_message_loader.dart';
import 'chat/friend_chat_plus_menu.dart';

class FriendChatPanel extends StatefulWidget {
  final String chatTargetId;
  final String chatTargetName;
  final VoidCallback onClose;
  final double maxWidth;

  const FriendChatPanel({
    super.key,
    required this.chatTargetId,
    required this.chatTargetName,
    required this.onClose,
    required this.maxWidth,
  });

  @override
  State<FriendChatPanel> createState() => _FriendChatPanelState();

  static Future<void> flushOutbox() async {
    final db = getIt<DatabaseService>();
    final outbox = db.getData('outbox');
    if (outbox == null) return;
    final messages = List<Map<String, dynamic>>.from(
      outbox['messages'] as List<dynamic>? ?? []);
    if (messages.isEmpty) return;
    final remaining = <Map<String, dynamic>>[];
    for (final msg in messages) {
      final roomId = msg['roomId'] as String?;
      final text = msg['text'] as String?;
      if (roomId == null || text == null) continue;
      try {
        final matrix = getIt<MatrixCubit>();
        if (matrix.isLoggedIn) {
          await matrix.sendMessage(roomId, text);
          continue;
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
    with TickerProviderStateMixin, FriendChatPlusMenu, FriendChatMenuActions,
         FriendChatEncryption, FriendChatMessageActions, FriendChatMessageSender,
         FriendChatMessageLoader, FriendChatMatrixHandler, FriendChatInputHandler {
  @override
  String get chatTargetId => widget.chatTargetId;
  @override
  List<FriendMessageData> get friendMessages => _friendMessages;
  @override
  set friendMessages(List<FriendMessageData> v) => setState(() => _friendMessages = v);
  @override
  ScrollController get scrollController => _scrollController;
  @override
  Future<CachedPresence?>? get presenceFutureValue => _presenceFuture;
  @override
  set presenceFutureValue(Future<CachedPresence?>? v) => setState(() => _presenceFuture = v);
  @override
  bool get isOtherTypingValue => _isOtherTyping;
  @override
  set isOtherTypingValue(bool v) => setState(() => _isOtherTyping = v);
  @override
  TextEditingController get textController => _textController;
  @override
  FocusNode get focusNode => _focusNode;
  @override
  bool get isListening => _isListening;
  @override
  set isListening(bool v) => setState(() => _isListening = v);
  @override
  AnimationController get listeningGlowCtrl => _listeningGlow;
  @override
  bool get showEmojiPickerState => _showEmojiPicker;
  @override
  set showEmojiPickerState(bool v) => setState(() => _showEmojiPicker = v);

  String t(String key) => localeProvider.t(key);

  List<FriendMessageData> _friendMessages = [];
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
  StreamSubscription? _matrixStateSub;
  late AnimationController _listeningGlow;

  @override
  void initState() {
    super.initState();
    _listeningGlow = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this);
    _matrixStateSub = getIt<MatrixCubit>().stream.listen((_) => onMatrixChanged());
    _presenceFuture = getPresence();
    _presenceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle == AppLifecycleState.paused) return;
      presenceFutureValue = getPresence();
    });
    _initMessages();
    markRoomAsRead(widget.chatTargetId);
    _scrollController.addListener(_onScroll);
    restoreDraft();
    _voiceResultSub = getIt<VoiceService>().onFinalResult.listen((text) {
      if (!mounted || text.isEmpty) return;
      final current = _textController.text;
      _textController.text = current.isEmpty ? text : '$current $text';
      _textController.selection = TextSelection.collapsed(
        offset: _textController.text.length);
      setState(() {});
    });
  }

  Future<void> _initMessages() async {
    final msgs = await loadMatrixMessages(widget.chatTargetId);
    if (mounted) {
      setState(() {
        _friendMessages = msgs;
      });
    }
  }

  Future<void> _reloadMessages() async {
    final msgs = await loadMatrixMessages(widget.chatTargetId);
    if (mounted) {
      setState(() {
        _friendMessages = msgs;
      });
    }
  }

  @override
  void didUpdateWidget(covariant FriendChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatTargetId != widget.chatTargetId) {
      saveDraft();
      _timeline = null;
      _reloadMessages();
      markRoomAsRead(widget.chatTargetId);
      restoreDraft();
      _presenceFuture = getPresence();
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

  Future<void> _loadMoreHistory() async {
    if (_isLoadingHistory || !_canLoadMore) return;
    _isLoadingHistory = true;
    try {
      final tl = _timeline;
      if (tl == null) return;
      final events = await tl.requestHistory();
      if (events.isEmpty) {
        _canLoadMore = false;
        return;
      }
      final newMsgs = <FriendMessageData>[];
      for (final event in events) {
        if (event.type == EventTypes.Message && event.body.isNotEmpty) {
          final isMe = event.senderId == getIt<MatrixCubit>().userId;
          newMsgs.add(FriendMessageData(
            isMe: isMe,
            content: event.body,
            msgType: event.content['msgtype'] as String?,
            url: event.content['url'] as String?,
            eventId: event.eventId));
        }
      }
      if (newMsgs.isNotEmpty && mounted) {
        setState(() {
          _friendMessages = [...newMsgs, ..._friendMessages];
        });
      }
    } catch (e) {
      AppLogger.instance.debug('Load more history failed', error: e);
    } finally {
      _isLoadingHistory = false;
    }
  }

  @override
  void dispose() {
    saveDraft();
    _voiceResultSub?.cancel();
    _matrixStateSub?.cancel();
    _presenceTimer?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _listeningGlow.dispose();
    super.dispose();
  }

  void _sendFriendMessage() {
    sendFriendMessage(context,
        text: _textController.text.trim(),
        textController: _textController,
        replyingTo: _replyingTo,
        onClearedReply: () => setState(() => _replyingTo = null));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: FriendChatContentView(
          messages: _friendMessages,
          scrollController: _scrollController,
          chatTargetId: widget.chatTargetId,
          timeline: _timeline,
          onLongPress: (i, msg) => showMessageActions(context, i, msg,
              onReply: () => setState(() => _replyingTo = msg),
              onEdit: (msg) => editMessage(context, msg, () => _reloadMessages()),
              onRefresh: () => _reloadMessages()),
        )),
        _buildInputArea(),
        buildEmojiPicker(),
      ]);
  }

  Widget _buildHeader() {
    return FriendChatAppBar(
      chatTargetId: widget.chatTargetId,
      chatTargetName: widget.chatTargetName,
      onClose: widget.onClose,
      isOtherTyping: _isOtherTyping,
      presenceFuture: _presenceFuture,
      onEncryptionInfo: () => showEncryptionInfo(context, widget.chatTargetId),
      onMenu: () => showFriendChatMenu(context, widget.chatTargetId),
    );
  }

  Widget _buildInputArea() {
    return FriendChatInput(
      textController: _textController,
      focusNode: _focusNode,
      listeningGlow: _listeningGlow,
      isListening: _isListening,
      replyContent: _replyingTo?.content,
      replyLabel: t('replying_to'),
      onSend: _sendFriendMessage,
      onToggleEmoji: toggleEmojiPicker,
      onToggleListening: toggleListening,
      onPlusMenu: () => showPlusMenu(context, widget.chatTargetId,
          onSendFile: () {},
          sendFileMessage: (prefix, name, path) => sendFileMessage(context, prefix, name, path)),
      onCancelReply: () => setState(() => _replyingTo = null),
      onSendVoice: (path, duration) => sendVoiceMessage(context, path, duration),
    );
  }
}
