import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../../core/app_provider.dart';
import '../../core/analytics_service.dart';
import '../../core/navigation_provider.dart';
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
import '../widgets/home_dialogs.dart';
import '../../core/haptic_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/library_panel.dart';
import '../widgets/friend_chat_panel.dart';
import '../widgets/user_avatar.dart';
import '../widgets/home_scroll_mixin.dart';
import '../widgets/home_message_actions_mixin.dart';
import '../widgets/home_conversation_menu_mixin.dart';

class HomeView extends StatefulWidget {
  final AppProvider provider;
  const HomeView({super.key, required this.provider});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with
        TickerProviderStateMixin,
        HomeScrollMixin,
        HomeMessageActionsMixin,
        HomeConversationMenuMixin {
  String t(String key) => localeProvider.t(key);
  bool _isListening = false;
  bool _isLeftDrawerOpen = false;
  bool _hasSentMessage = false;
  int _editingIndex = -1;
  bool _isLibraryMode = false;
  bool _showSearchBar = false;
  bool _isFriendChat = false;
  String _chatTargetId = '';
  String _chatTargetName = '';
  final TextEditingController _searchController = TextEditingController();

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<ChatMessageData> _messages = [];
  final Set<int> _expandedThoughts = {};

  final GlobalKey<AppDrawerState> _drawerKey = GlobalKey();
  double _swipeStartX = 0;

  late AnimationController _listeningGlow;
  late AnimationController _headerSwitch;
  late AnimationController _tabSwitch;

  bool _permissionDialogShown = false;

  @override
  AppProvider get provider => widget.provider;

  @override
  List<ChatMessageData> get messages => _messages;

  @override
  TextEditingController get textController => _textController;

  @override
  FocusNode get focusNode => _focusNode;

  @override
  int get editingIndex => _editingIndex;

  @override
  set editingIndex(int value) => _editingIndex = value;

  @override
  void markNeedsRebuild() => setState(() {});

  @override
  void onDeleteConversation() => _closeConversation();

  @override
  void initState() {
    super.initState();
    initScrollListener();
    widget.provider.orchestrator.addListener(_onOrchestratorChanged);
    widget.provider.matrix.addListener(_onMatrixChanged);
    _listeningGlow = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _headerSwitch = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _tabSwitch = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    nc.NotificationCenter.observe(
      nc.Event.capabilityConfirm,
      _onCapabilityConfirm,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _listeningGlow.dispose();
    _headerSwitch.dispose();
    _tabSwitch.dispose();
    _searchController.dispose();
    disposeScrollListener();
    widget.provider.orchestrator.removeListener(_onOrchestratorChanged);
    widget.provider.matrix.removeListener(_onMatrixChanged);
    nc.NotificationCenter.removeObserver(
      nc.Event.capabilityConfirm,
      callback: _onCapabilityConfirm,
    );
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
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(localeProvider.t('deny')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(localeProvider.t('allow')),
            ),
          ],
        ),
      ).then((granted) {
        nc.NotificationCenter.post(
          nc.Event.capabilityConfirm,
          data: {'granted': granted ?? false},
        );
      });
    }
  }

  void _onOrchestratorChanged() {
    if (!mounted) return;
    final orchestrator = widget.provider.orchestrator;
    final orchMessages = orchestrator.messages;

    _messages.clear();
    for (final msg in orchMessages) {
      _messages.add(
        ChatMessageData(
          role: msg.role,
          content: msg.content,
          isStreaming: msg.isStreaming,
          thoughts: msg.thoughts,
        ),
      );
    }

    final cards = orchestrator.cardRuntime.cards;
    for (final card in cards.values) {
      if (card.lifecycle == CardLifecycle.created ||
          card.lifecycle == CardLifecycle.streaming) {
        final exists = _messages.any(
          (m) => m.cardType != null && m.cardData?['cardId'] == card.id,
        );
        if (!exists) {
          _messages.add(
            ChatMessageData(
              role: 'assistant',
              content: '',
              cardType: card.type,
              cardData: {...card.data, 'cardId': card.id},
            ),
          );
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
      if (!scrollController.hasClients) return;
      calcMaxScrollOffset();
      if (orchestrator.isStreaming) {
        scrollToLatest();
      }
    });
  }

  void _onMatrixChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _openDrawer() => setState(() => _isLeftDrawerOpen = true);

  void _closeDrawer() {
    final state = _drawerKey.currentState;
    if (state != null) {
      state.close();
    } else {
      setState(() => _isLeftDrawerOpen = false);
    }
  }

  void _openSettingsFromDrawer() {
    widget.provider.navigation.openSettingsFromDrawer();
    _closeDrawer();
  }

  void _toggleListening() {
    setState(() => _isListening = !_isListening);
    if (_isListening) {
      _listeningGlow.forward();
    } else {
      _listeningGlow.reverse();
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    if (text.length > 32000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localeProvider.t('message_too_long')),
          backgroundColor: AppColors.warn(context),
        ),
      );
      return;
    }
    HapticService.sendMessage();

    if (_editingIndex >= 0 && _editingIndex < _messages.length) {
      _messages.removeAt(_editingIndex + 1);
      _messages.removeAt(_editingIndex);
      _editingIndex = -1;
      maxScrollOffset = 0;
    }

    if (!_hasSentMessage) {
      setState(() {
        _hasSentMessage = true;
        _headerSwitch.forward(from: 0);
      });
    }

    if (widget.provider.session.activeSessionId == null) {
      widget.provider.session.createSession();
    }

    _textController.clear();
    _focusNode.unfocus();

    final orchestrator = widget.provider.orchestrator;
    if (orchestrator.isIdle) {
      orchestrator.sendMessage(text);
      AnalyticsService.instance.logAiQuery(
        model: widget.provider.model.activeModelId ?? 'unknown',
      );
    }

    widget.provider.session.saveCurrentSession();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      calcMaxScrollOffset();
      scrollToLatest();
    });
  }

  void _closeConversation() {
    _headerSwitch.reverse().then((_) {
      if (mounted) {
        widget.provider.session.closeActiveSession();
        setState(() {
          _hasSentMessage = false;
          _messages.clear();
          _textController.clear();
          _focusNode.unfocus();
          showScrollBtn = false;
          maxScrollOffset = 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final contentWidth = Responsive.contentMaxWidth(context);

    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.provider.navigation,
        widget.provider.orchestrator,
        widget.provider.session,
      ]),
      builder: (context, _) {
        if (!widget.provider.navigation.isSettingsOpen &&
            widget.provider.navigation.shouldShowDrawerAfterSettings) {
          widget.provider.navigation.clearDrawerFlag();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _openDrawer();
          });
        }
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) => _swipeStartX = d.globalPosition.dx,
          onHorizontalDragEnd: (d) {
            final dx = d.globalPosition.dx - _swipeStartX;
            if (dx > 50 && !_isLeftDrawerOpen) {
              _openDrawer();
            } else if (dx < -50 && _isLeftDrawerOpen) {
              _closeDrawer();
            } else if (dx < -50 && !_isLeftDrawerOpen && !isDesktop) {
              widget.provider.navigation.setCurrentView(ViewState.discover);
            }
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
                          Expanded(
                            child: FriendChatPanel(
                              provider: widget.provider,
                              chatTargetId: _chatTargetId,
                              chatTargetName: _chatTargetName,
                              onClose: _closeFriendChat,
                              maxWidth: contentWidth,
                            ),
                          )
                        else ...[
                          HomeHeader(
                            hasSentMessage: _hasSentMessage,
                            headerSwitch: _headerSwitch,
                            tabSwitch: _tabSwitch,
                            isLibraryMode: _isLibraryMode,
                            isIncognito: widget.provider.navigation.isIncognito,
                            onCloseConversation: _closeConversation,
                            onShowConversationMenu: () =>
                                showConversationMenu(context),
                            onOpenDrawer: _openDrawer,
                            onCreateGroupChat: _showCreateGroupChat,
                            onSwitchToChat: () {
                              _tabSwitch.reverse();
                              setState(() {
                                _isLibraryMode = false;
                                _showSearchBar = false;
                              });
                            },
                            onSwitchToLibrary: () {
                              _tabSwitch.forward();
                              setState(() {
                                _isLibraryMode = true;
                                _showSearchBar = false;
                              });
                            },
                            onToggleSearch: () => setState(
                              () => _showSearchBar = !_showSearchBar,
                            ),
                            onOpenDiscover: () => widget.provider.navigation
                                .setCurrentView(ViewState.discover),
                            userAvatar: UserAvatar(
                              userId: widget.provider.matrix.userId ?? '',
                              size: 30,
                              radius: 15,
                            ),
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
                              isIncognito:
                                  widget.provider.navigation.isIncognito,
                              isFriendChat: _isFriendChat,
                              isGenerating:
                                  !widget.provider.orchestrator.isIdle,
                              maxWidth: contentWidth,
                              onSend: _sendMessage,
                              onToggleListening: _toggleListening,
                              onCancelEdit: _cancelEdit,
                              onToggleIncognito: () =>
                                  widget.provider.navigation.setIsIncognito(
                                    !widget.provider.navigation.isIncognito,
                                  ),
                              onShowOptions: _showOptionsSheet,
                              onShowModels: _showModelsSheet,
                              onChanged: () => setState(() {}),
                              onStopGeneration: () =>
                                  widget.provider.orchestrator.interrupt(),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_isLeftDrawerOpen)
                  AppDrawer(
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
        showSearchBar: _showSearchBar,
        onToggleSearch: () => setState(() => _showSearchBar = !_showSearchBar),
        onOpenFriendChat: _openFriendChat,
      );
    }
    if (_hasSentMessage) {
      return ConversationContent(
        messages: _messages,
        expandedThoughts: _expandedThoughts,
        scrollController: scrollController,
        lastUserBubbleKey: lastUserBubbleKey,
        showScrollBtn: showScrollBtn,
        orchestrator: widget.provider.orchestrator,
        onScrollToLatest: scrollToLatest,
        onToggleThought: (i) => setState(() {
          _expandedThoughts.contains(i)
              ? _expandedThoughts.remove(i)
              : _expandedThoughts.add(i);
        }),
        onRegenerate: regenerateResponse,
        onCopy: copyContent,
        onSpeak: speakLastResponse,
        onShare: shareMessage,
        onMore: (content, index) => HomeDialogs.showMoreMenu(
          context,
          content,
          index,
          onEdit: () => editQuery(index),
          onDelete: () => deleteMessagePair(index),
          onReport: () => reportNotHelpful(index),
        ),
        onMessageLongPress: (index) => HomeDialogs.showMoreMenu(
          context,
          _messages[index].content,
          index,
          onEdit: () => editQuery(index),
          onDelete: () => deleteMessagePair(index),
          onReport: () => reportNotHelpful(index),
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
              Text(
                t('incognito_mode'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                localeProvider.t('incognito_notice'),
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.mut(context),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return Center(
      child: Text(
        'Omnivium',
        style: TextStyle(
          fontSize: 36,
          color: AppColors.textPrimary(context),
          fontFamily: 'serif',
        ),
      ),
    );
  }

  void _openFriendChat(String id, String name) => setState(() {
    _isFriendChat = true;
    _chatTargetId = id;
    _chatTargetName = name;
  });

  void _closeFriendChat() => setState(() {
    _isFriendChat = false;
    _chatTargetId = '';
    _chatTargetName = '';
  });

  void _cancelEdit() => setState(() => _editingIndex = -1);

  void _showPermissionDialog() {
    if (_permissionDialogShown) return;
    _permissionDialogShown = true;
    final orchestrator = widget.provider.orchestrator;
    final skillName =
        orchestrator.pendingSkillName ?? localeProvider.t('unknown_action');
    HomeDialogs.showPermissionDialog(
      context,
      skillName,
      onGrant: () {
        _permissionDialogShown = false;
        orchestrator.grantPermission();
      },
      onDeny: () {
        _permissionDialogShown = false;
        orchestrator.denyPermission();
      },
    );
  }

  void _openNotifications() {
    _closeDrawer();
    nav.AppNavigator.go(context, '/notifications');
  }

  void _showCreateGroupChat() {
    nav.AppNavigator.go(context, '/create-group');
  }

  void _showOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.black.withValues(alpha: 0.54),
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: SlidingSheet(
          child: OptionsContent(
            onClose: () => Navigator.pop(context),
            provider: widget.provider,
          ),
        ),
      ),
    );
  }

  void _showModelsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.black.withValues(alpha: 0.54),
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: SlidingSheet(
          child: ModelsContent(
            onClose: () => Navigator.pop(context),
            provider: widget.provider,
          ),
        ),
      ),
    );
  }
}
