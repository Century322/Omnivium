import '../../core/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_colors.dart';
import '../../core/app_provider.dart';
import '../../core/navigation_provider.dart';
import '../../core/voice_service.dart';
import '../../core/runtime/card_runtime.dart';
import '../utils/responsive.dart';
import '../theme/locale_provider.dart';
import '../../core/notification_center.dart' as nc;
import '../../core/app_navigator.dart' as nav;
import '../widgets/home_components.dart';
import '../widgets/model_sheets.dart';
import '../widgets/home_header.dart';
import '../widgets/conversation_content.dart';
import '../widgets/chat_input_area.dart';
import '../widgets/chat_search_sheet.dart';
import '../widgets/home_dialogs.dart';
import '../../core/haptic_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/library_panel.dart';
import '../widgets/friend_chat_panel.dart';

class HomeView extends StatefulWidget {
  final AppProvider provider;
  const HomeView({super.key, required this.provider});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  String t(String key) => localeProvider.t(key);
  bool _isListening = false;
  bool _isLeftDrawerOpen = false;
  bool _hasSentMessage = false;
  bool _showScrollBtn = false;
  bool _isAutoScrolling = false;
  double _maxScrollOffset = 0;
  int _editingIndex = -1;
  bool _isLibraryMode = false;
  bool _showContacts = false;
  bool _showSearchBar = false;
  bool _isFriendChat = false;
  String _chatTargetId = '';
  String _chatTargetName = '';
  final TextEditingController _searchController = TextEditingController();

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _lastUserBubbleKey = GlobalKey();

  final List<ChatMessageData> _messages = [];
  final Set<int> _expandedThoughts = {};

  final GlobalKey<AppDrawerState> _drawerKey = GlobalKey();
  double _swipeStartX = 0;

  late AnimationController _listeningGlow;
  late AnimationController _headerSwitch;
  late AnimationController _tabSwitch;

  bool _permissionDialogShown = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollChanged);
    widget.provider.orchestrator.addListener(_onOrchestratorChanged);
    widget.provider.matrix.addListener(_onMatrixChanged);
    _listeningGlow = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _headerSwitch = AnimationController(duration: const Duration(milliseconds: 250), vsync: this);
    _tabSwitch = AnimationController(duration: const Duration(milliseconds: 250), vsync: this);
    nc.NotificationCenter.observe(nc.Event.capabilityConfirm, _onCapabilityConfirm);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _listeningGlow.dispose();
    _headerSwitch.dispose();
    _tabSwitch.dispose();
    _searchController.dispose();
    widget.provider.orchestrator.removeListener(_onOrchestratorChanged);
    widget.provider.matrix.removeListener(_onMatrixChanged);
    nc.NotificationCenter.removeObserver(nc.Event.capabilityConfirm, callback: _onCapabilityConfirm);
    super.dispose();
  }

  void _onCapabilityConfirm(Map<String, dynamic>? data) {
    if (!mounted) return;
    final capId = data?['capabilityId'] as String? ?? '';
    if (data?['pending'] == true) {
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(localeProvider.t('capability_confirm_title')),
          content: Text('${localeProvider.t('capability_confirm_msg')} $capId'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(localeProvider.t('deny'))),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(localeProvider.t('allow'))),
          ],
        ),
      ).then((granted) {
        nc.NotificationCenter.post(nc.Event.capabilityConfirm, data: {'granted': granted ?? false});
      });
    }
  }

  void _onOrchestratorChanged() {
    final orchestrator = widget.provider.orchestrator;
    final orchMessages = orchestrator.messages;

    _messages.clear();
    for (final msg in orchMessages) {
      _messages.add(ChatMessageData(role: msg.role, content: msg.content, isStreaming: msg.isStreaming, thoughts: msg.thoughts));
    }

    final cards = orchestrator.cardRuntime.cards;
    for (final card in cards.values) {
      if (card.lifecycle == CardLifecycle.created || card.lifecycle == CardLifecycle.streaming) {
        final exists = _messages.any((m) => m.cardType != null && m.cardData?['cardId'] == card.id);
        if (!exists) {
          _messages.add(ChatMessageData(role: 'assistant', content: '', cardType: card.type, cardData: {...card.data, 'cardId': card.id}));
        }
      }
    }

    if (orchestrator.isWaitingPermission) {
      _showPermissionDialog();
    }

    if (_messages.isNotEmpty && !_hasSentMessage) {
      _hasSentMessage = true;
      _headerSwitch.forward(from: 0);
    }

    if (_messages.isEmpty && _hasSentMessage) {
      _hasSentMessage = false;
      _headerSwitch.reverse();
    }

    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _calcMaxScrollOffset();
      if (orchestrator.isStreaming) {
        _scrollToLatest();
      }
    });
  }

  void _onMatrixChanged() => setState(() {});

  void _onScrollChanged() {
    if (!_scrollController.hasClients || _isAutoScrolling) return;
    _clampScroll();
    _updateScrollBtn();
  }

  void _clampScroll() {
    if (!_scrollController.hasClients) return;
    final userCount = _messages.where((m) => m.role == 'user').length;
    if (userCount <= 1 || _maxScrollOffset <= 0) return;
    if (_scrollController.offset > _maxScrollOffset) {
      _scrollController.jumpTo(_maxScrollOffset);
    }
  }

  void _updateScrollBtn() {
    final userCount = _messages.where((m) => m.role == 'user').length;
    if (userCount <= 1) {
      if (_showScrollBtn) setState(() => _showScrollBtn = false);
      return;
    }
    if (_maxScrollOffset <= 0) return;
    final shouldShow = _scrollController.offset < _maxScrollOffset - 10;
    if (_showScrollBtn != shouldShow) setState(() => _showScrollBtn = shouldShow);
  }

  void _calcMaxScrollOffset() {
    final ctx = _lastUserBubbleKey.currentContext;
    if (ctx == null) return;
    final renderBox = ctx.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final headerBottom = MediaQuery.of(context).padding.top + 68;
    final widgetTop = renderBox.localToGlobal(Offset.zero).dy;
    _maxScrollOffset = _scrollController.offset + widgetTop - headerBottom;
  }

  void _scrollToLatest() {
    final target = _maxScrollOffset > 0 ? _maxScrollOffset : _scrollController.position.maxScrollExtent;
    if (target <= 0) return;
    _isAutoScrolling = true;
    _scrollController.animateTo(target, duration: const Duration(milliseconds: 300), curve: Curves.easeOut).then((_) {
      if (mounted) { _isAutoScrolling = false; setState(() => _showScrollBtn = false); }
    });
  }

  void _openDrawer() => setState(() => _isLeftDrawerOpen = true);

  void _closeDrawer() {
    final state = _drawerKey.currentState;
    if (state != null) { state.close(); } else { setState(() => _isLeftDrawerOpen = false); }
  }

  void _openSettingsFromDrawer() {
    widget.provider.navigation.openSettingsFromDrawer();
    _closeDrawer();
  }

  void _toggleListening() {
    setState(() => _isListening = !_isListening);
    if (_isListening) { _listeningGlow.forward(); } else { _listeningGlow.reverse(); }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    if (text.length > 32000) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localeProvider.t('message_too_long')), backgroundColor: AppColors.warn(context)));
      return;
    }
    HapticService.sendMessage();

    if (_editingIndex >= 0 && _editingIndex < _messages.length) {
      _messages.removeAt(_editingIndex + 1);
      _messages.removeAt(_editingIndex);
      _editingIndex = -1;
      _maxScrollOffset = 0;
    }

    if (!_hasSentMessage) {
      setState(() { _hasSentMessage = true; _headerSwitch.forward(from: 0); });
    }

    if (widget.provider.session.activeSessionId == null) {
      widget.provider.session.createSession();
    }

    _textController.clear();
    _focusNode.unfocus();

    final orchestrator = widget.provider.orchestrator;
    if (orchestrator.isIdle) orchestrator.sendMessage(text);

    widget.provider.session.saveCurrentSession();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _calcMaxScrollOffset();
      _scrollToLatest();
    });
  }

  void _closeConversation() {
    _headerSwitch.reverse().then((_) {
      if (mounted) {
        widget.provider.session.closeActiveSession();
        setState(() { _hasSentMessage = false; _messages.clear(); _textController.clear(); _focusNode.unfocus(); _showScrollBtn = false; _maxScrollOffset = 0; });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final contentWidth = Responsive.contentMaxWidth(context);

    return ListenableBuilder(
      listenable: Listenable.merge([widget.provider.navigation, widget.provider.orchestrator, widget.provider.session]),
      builder: (context, _) {
        if (!widget.provider.navigation.isSettingsOpen && widget.provider.navigation.shouldShowDrawerAfterSettings) {
          widget.provider.navigation.clearDrawerFlag();
          WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _openDrawer(); });
        }
        return GestureDetector(

      behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) => _swipeStartX = d.globalPosition.dx,
          onHorizontalDragEnd: (d) {
            final dx = d.globalPosition.dx - _swipeStartX;
            if (dx > 50 && !_isLeftDrawerOpen) { _openDrawer(); }
            else if (dx < -50 && _isLeftDrawerOpen) { _closeDrawer(); }
            else if (dx < -50 && !_isLeftDrawerOpen && !isDesktop) { widget.provider.navigation.setCurrentView(ViewState.discover); }
          },
          child: Scaffold(
            body: Stack(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Column(
                      children: [
                        if (_isFriendChat)
                          Expanded(child: FriendChatPanel(provider: widget.provider, chatTargetId: _chatTargetId, chatTargetName: _chatTargetName, onClose: _closeFriendChat, maxWidth: contentWidth))
                        else ...[
                          HomeHeader(
                            hasSentMessage: _hasSentMessage,
                            headerSwitch: _headerSwitch,
                            tabSwitch: _tabSwitch,
                            isLibraryMode: _isLibraryMode,
                            showContacts: _showContacts,
                            isIncognito: widget.provider.navigation.isIncognito,
                            onCloseConversation: _closeConversation,
                            onShowConversationMenu: () => _showConversationMenu(context),
                            onOpenDrawer: _openDrawer,
                            onToggleContacts: () => setState(() => _showContacts = !_showContacts),
                            onSwitchToChat: () { _tabSwitch.reverse(); setState(() { _isLibraryMode = false; _showContacts = false; _showSearchBar = false; }); },
                            onSwitchToLibrary: () { _tabSwitch.forward(); setState(() { _isLibraryMode = true; _showContacts = false; _showSearchBar = false; }); },
                            onToggleSearch: () => setState(() => _showSearchBar = !_showSearchBar),
                            onOpenDiscover: () => widget.provider.navigation.setCurrentView(ViewState.discover),
                            userAvatar: _buildUserAvatar(size: 30, radius: 15),
                          ),
                          Expanded(child: _buildCenterContent()),
                          if (!_isLibraryMode)
                            ChatInputArea(
                              textController: _textController,
                              focusNode: _focusNode,
                              listeningGlow: _listeningGlow,
                              hasSentMessage: _hasSentMessage,
                              isListening: _isListening,
                              isEditing: _editingIndex >= 0,
                              isIncognito: widget.provider.navigation.isIncognito,
                              isFriendChat: _isFriendChat,
                              isGenerating: !widget.provider.orchestrator.isIdle,
                              maxWidth: contentWidth,
                              onSend: _sendMessage,
                              onToggleListening: _toggleListening,
                              onCancelEdit: _cancelEdit,
                              onToggleIncognito: () => widget.provider.navigation.setIsIncognito(!widget.provider.navigation.isIncognito),
                              onShowOptions: _showOptionsSheet,
                              onShowModels: _showModelsSheet,
                              onOpenVoice: () => widget.provider.navigation.setCurrentView(ViewState.voice),
                              onChanged: () => setState(() {}),
                              onStopGeneration: () => widget.provider.orchestrator.interrupt(),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_isLeftDrawerOpen) AppDrawer(
                  key: _drawerKey,
                  provider: widget.provider,
                  onClose: () => setState(() => _isLeftDrawerOpen = false),
                  onOpenNotifications: _openNotifications,
                  onOpenSettings: _openSettingsFromDrawer,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCenterContent() {
    if (_isLibraryMode) {
      return LibraryPanel(
        provider: widget.provider,
        onCreateGroupChat: _showCreateGroupChat,
        onAddContact: _showAddContact,
        showSearchBar: _showSearchBar,
        onToggleSearch: () => setState(() => _showSearchBar = !_showSearchBar),
        onOpenFriendChat: _openFriendChat,
      );
    }
    if (_hasSentMessage) {
      return ConversationContent(
        messages: _messages,
        expandedThoughts: _expandedThoughts,
        scrollController: _scrollController,
        lastUserBubbleKey: _lastUserBubbleKey,
        showScrollBtn: _showScrollBtn,
        orchestrator: widget.provider.orchestrator,
        onScrollToLatest: _scrollToLatest,
        onToggleThought: (i) => setState(() { _expandedThoughts.contains(i) ? _expandedThoughts.remove(i) : _expandedThoughts.add(i); }),
        onRegenerate: _regenerateResponse,
        onCopy: _copyContent,
        onSpeak: _speakLastResponse,
        onShare: (content) => SharePlus.instance.share(ShareParams(text: content)),
        onMore: (content, index) => HomeDialogs.showMoreMenu(context, content, index,
          onEdit: () => _editQuery(index),
          onDelete: () => _deleteMessagePair(index),
          onReport: () => _reportNotHelpful(index),
        ),
        onMessageLongPress: (index) => HomeDialogs.showMoreMenu(context, _messages[index].content, index,
          onEdit: () => _editQuery(index),
          onDelete: () => _deleteMessagePair(index),
          onReport: () => _reportNotHelpful(index),
        ),
      );
    }
    if (widget.provider.navigation.isIncognito) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t('incognito_mode'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.textPrimary(context))),
              const SizedBox(height: 16),
              Text(localeProvider.t('incognito_notice'), style: TextStyle(fontSize: 15, color: AppColors.mut(context), height: 1.6), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    return Center(child: Text('Omnivium', style: TextStyle(fontSize: 36, color: AppColors.textPrimary(context), fontFamily: 'serif')));
  }

  void _openFriendChat(String id, String name) => setState(() { _isFriendChat = true; _chatTargetId = id; _chatTargetName = name; });

  void _closeFriendChat() => setState(() { _isFriendChat = false; _chatTargetId = ''; _chatTargetName = ''; });

  void _cancelEdit() => setState(() => _editingIndex = -1);

  void _editQuery(int index) {
    if (index <= 0 || index >= _messages.length) return;
    setState(() { _editingIndex = index - 1; _textController.text = _messages[index - 1].content; });
    _focusNode.requestFocus();
  }

  void _deleteMessagePair(int index) {
    if (index <= 0 || index >= _messages.length) return;
    widget.provider.orchestrator.deleteMessagePair(index);
    setState(() { _editingIndex = -1; _maxScrollOffset = 0; });
    widget.provider.session.saveCurrentSession();
  }

  void _reportNotHelpful(int index) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localeProvider.t('feedback_recorded')), duration: const Duration(seconds: 2)));
  }

  void _regenerateResponse() {
    final orchestrator = widget.provider.orchestrator;
    if (!orchestrator.isIdle) return;
    final orchMsgs = orchestrator.messages;
    if (orchMsgs.isEmpty) return;
    String? lastUserMsg;
    for (var i = orchMsgs.length - 1; i >= 0; i--) {
      if (orchMsgs[i].role == 'user') { lastUserMsg = orchMsgs[i].content; break; }
    }
    if (lastUserMsg == null) return;
    if (orchMsgs.isNotEmpty && orchMsgs.last.role == 'assistant') {
      orchestrator.deleteMessagePair(orchMsgs.length - 1);
    }
    orchestrator.sendMessage(lastUserMsg);
  }

  void _copyContent(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t('copied')), backgroundColor: AppColors.accent, duration: const Duration(milliseconds: 1500)),
    );
  }

  void _speakLastResponse() {
    final orch = widget.provider.orchestrator;
    final msgs = orch.messages;
    if (msgs.isEmpty) return;
    final last = msgs.last;
    if (last.role == 'assistant' && last.content.isNotEmpty) VoiceService.instance.speak(last.content);
  }

  void _showPermissionDialog() {
    if (_permissionDialogShown) return;
    _permissionDialogShown = true;
    final orchestrator = widget.provider.orchestrator;
    final skillName = orchestrator.pendingSkillName ?? localeProvider.t('unknown_action');
    HomeDialogs.showPermissionDialog(context, skillName,
      onGrant: () { _permissionDialogShown = false; orchestrator.grantPermission(); },
      onDeny: () { _permissionDialogShown = false; orchestrator.denyPermission(); },
    );
  }

  Widget _buildUserAvatar({required double size, required double radius}) {
    final userId = widget.provider.matrix.userId ?? '';
    final initial = userId.isNotEmpty ? userId.split(':').first.replaceAll('@', '').toUpperCase() : '?';
    final letter = initial.isNotEmpty ? initial[0] : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(radius)),
      child: Center(child: Text(letter, style: TextStyle(color: AppColors.accent, fontSize: size * 0.45, fontWeight: FontWeight.w700))),
    );
  }

  void _openNotifications() {
    _closeDrawer();
    nav.AppNavigator.go(context, '/notifications');
  }

  void _toggleFavorite() {
    final sessionId = widget.provider.session.activeSessionId;
    if (sessionId == null) return;
    widget.provider.session.toggleFavoriteSession(sessionId);
    final session = widget.provider.session.sessions.where((s) => s.id == sessionId).firstOrNull;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(session?.isFavorite == true ? localeProvider.t('favorited') : localeProvider.t('unfavorited')), duration: const Duration(seconds: 2)),
    );
  }

  void _showConversationMenu(BuildContext ctx) {
    showMenu(
      context: ctx,
      position: RelativeRect.fromLTRB(MediaQuery.of(ctx).size.width - 180, MediaQuery.of(ctx).padding.top + 60, 16, 0),
      color: AppColors.sf(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        _menuItem(LucideIcons.bookmark, localeProvider.t('favorite_conversation'), key: 'favorite'),
        _menuItem(LucideIcons.share, localeProvider.t('share_conversation'), key: 'share'),
        _menuItem(LucideIcons.search, localeProvider.t('search_conversation'), key: 'search'),
        _menuItem(LucideIcons.shield, widget.provider.navigation.isIncognito ? localeProvider.t('close_incognito') : localeProvider.t('incognito_mode_short'), key: 'incognito'),
        _menuItem(LucideIcons.trash2, localeProvider.t('delete_conversation'), key: 'delete', isDanger: true),
      ],
    ).then((value) {
      if (value == null || !mounted) return;
      switch (value) {
        case 'favorite': _toggleFavorite();
        case 'share': _shareConversation();
        case 'search': ChatSearchSheet(messages: _messages).show(context);
        case 'incognito': widget.provider.navigation.setIsIncognito(!widget.provider.navigation.isIncognito);
        case 'delete': _closeConversation();
      }
    });
  }

  void _shareConversation() {
    final msgs = _messages;
    if (msgs.isEmpty) return;
    final text = msgs.map((m) => m.role == 'user' ? '${localeProvider.t('me')}：${m.content}' : '${localeProvider.t('ai')}：${m.content}').join('\n\n');
    SharePlus.instance.share(ShareParams(text: text));
  }

  PopupMenuItem<String> _menuItem(IconData icon, String text, {String? key, bool isDanger = false}) {
    return PopupMenuItem<String>(
      value: key ?? text,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Icon(icon, size: 16, color: isDanger ? AppColors.dng(context) : AppColors.sec(context)),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: isDanger ? AppColors.dng(context) : AppColors.textPrimary(context), fontSize: 14, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  void _showCreateGroupChat() {
    HomeDialogs.showCreateGroupChat(context, onCreate: (name, members) async {
      try { await widget.provider.matrix.createGroupChat(name, userIds: members); }
      catch (e, stackTrace) { AppLogger.instance.error('Operation failed', error: e, stackTrace: stackTrace); }
    });
  }

  void _showAddContact() {
    HomeDialogs.showAddContact(context, onAdd: (userId) async {
      try { await widget.provider.matrix.createDirectChat(userId); }
      catch (e, stackTrace) { AppLogger.instance.error('Operation failed', error: e, stackTrace: stackTrace); }
    });
  }

  void _showOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SlidingSheet(child: OptionsContent(onClose: () => Navigator.pop(context), provider: widget.provider)),
    );
  }

  void _showModelsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SlidingSheet(child: ModelsContent(onClose: () => Navigator.pop(context), provider: widget.provider)),
    );
  }
}
