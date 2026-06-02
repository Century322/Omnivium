
import '../../core/di/app_di.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_colors.dart';

import '../../core/di/app_di.dart';
import '../../core/analytics_service.dart';
import '../../core/navigation_cubit.dart';
import '../../core/runtime/card_runtime.dart';
import '../../core/voice_service.dart';
import '../../core/agent/agent_orchestrator.dart' show AgentOrchestrator, OrchestratorState;
import '../../core/matrix/matrix_cubit.dart';
import '../../core/model_cubit.dart';
import '../../core/session_cubit.dart';
import '../utils/responsive.dart';
import '../theme/locale_cubit.dart';
import '../../core/notification_center.dart' as nc;
import '../../core/app_navigator.dart' as nav;
import '../widgets/home_components.dart';
import '../widgets/library_panel.dart';
import '../widgets/model_sheets.dart';
import '../widgets/home_header.dart';
import '../widgets/conversation_content.dart';
import '../widgets/chat_input_area.dart';
import '../widgets/home_dialogs.dart';
import '../../core/haptic_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/friend_chat_panel.dart';

import '../widgets/user_avatar.dart';
import '../widgets/home_scroll_mixin.dart';
import '../widgets/home_message_actions_mixin.dart';
import '../widgets/home_conversation_menu_mixin.dart';

class HomeView extends StatefulWidget { const HomeView({super.key});

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
  StreamSubscription? _voiceStateSub;
  StreamSubscription? _voiceResultSub;
  StreamSubscription? _matrixSub;
  StreamSubscription? _orchestratorSub;
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
  final GlobalKey lastUserBubbleKey = GlobalKey();
  double _swipeStartX = 0;

  late AnimationController _listeningGlow;
  late AnimationController _headerSwitch;
  late AnimationController _tabSwitch;

  bool _permissionDialogShown = false;

  @override @override
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
    _orchestratorSub = getIt<AgentOrchestrator>().stream.listen((_) => _onOrchestratorChanged());
    _matrixSub = getIt<MatrixCubit>().stream.listen((_) => _onMatrixChanged());
    _listeningGlow = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this);
    _voiceStateSub = getIt<VoiceService>().onListeningStateChanged.listen((
      isListening) {
      if (!mounted) return;
      setState(() => _isListening = isListening);
      if (isListening) {
        _listeningGlow.repeat(reverse: true);
      } else {
        _listeningGlow.stop();
        _listeningGlow.reverse();
      }
    });
    _voiceResultSub = getIt<VoiceService>().onFinalResult.listen((result) {
      if (!mounted || result.isEmpty) return;
      final current = _textController.text;
      final separator = current.isNotEmpty ? ' ' : '';
      _textController.text = '$current$separator$result';
      setState(() {});
    });
    _headerSwitch = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this);
    _tabSwitch = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this);
    nc.NotificationCenter.observe(
      nc.Event.capabilityConfirm,
      _onCapabilityConfirm);
  }

  @override
  void dispose() {
    _voiceStateSub?.cancel();
    _matrixSub?.cancel();
    _voiceResultSub?.cancel();
    _orchestratorSub?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    _listeningGlow.dispose();
    _headerSwitch.dispose();
    _tabSwitch.dispose();
    _searchController.dispose();
    disposeScrollListener();
    nc.NotificationCenter.removeObserver(
      nc.Event.capabilityConfirm,
      callback: _onCapabilityConfirm);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
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
              child: Text(localeProvider.t('deny'))),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(localeProvider.t('allow'))),
          ])).then((granted) {
        nc.NotificationCenter.post(
          nc.Event.capabilityConfirm,
          data: {'granted': granted ?? false});
      });
    }
  }

  void _onOrchestratorChanged() {
    if (!mounted) return;
    final orchestrator = getIt<AgentOrchestrator>();
    final orchMessages = orchestrator.messages;

    _messages.clear();
    for (final msg in orchMessages) {
      _messages.add(
        ChatMessageData(
          role: msg.role,
          content: msg.content,
          isStreaming: msg.isStreaming,
          thoughts: msg.thoughts));
    }

    final cards = orchestrator.cardRuntime.cards;
    for (final card in cards.values) {
      if (card.lifecycle == CardLifecycle.created ||
          card.lifecycle == CardLifecycle.streaming) {
        final exists = _messages.any(
          (m) => m.cardType != null && m.cardData?['cardId'] == card.id);
        if (!exists) {
          _messages.add(
            ChatMessageData(
              role: 'assistant',
              content: '',
              cardType: card.type,
              cardData: {...card.data, 'cardId': card.id}));
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
    getIt<NavigationCubit>().openSettingsFromDrawer();
    _closeDrawer();
  }

  void _toggleListening() async {
    final voice = getIt<VoiceService>();
    if (_isListening) {
      await voice.stopListening();
      if (!mounted) return;
      _listeningGlow.stop();
      _listeningGlow.reverse();
      setState(() => _isListening = false);
    } else {
      final available = await getIt<VoiceService>().isAvailable();
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localeProvider.t('voice_not_available')),
              backgroundColor: AppColors.warn(context)));
        }
        return;
      }
      final ok = await voice.startListening();
      if (!ok || !mounted) return;
      setState(() => _isListening = true);
      _listeningGlow.repeat(reverse: true);
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    if (text.length > 32000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localeProvider.t('message_too_long')),
          backgroundColor: AppColors.warn(context)));
      return;
    }
    HapticService.sendMessage();

    if (_editingIndex >= 0 && _editingIndex < _messages.length) {
      _messages.removeAt(_editingIndex + 1);
      _messages.removeAt(_editingIndex);
      _editingIndex = -1;
    }

    if (!_hasSentMessage) {
      setState(() {
        _hasSentMessage = true;
        _headerSwitch.forward(from: 0);
      });
    }

    if (getIt<SessionCubit>().activeSessionId == null) {
      getIt<SessionCubit>().createSession();
    }

    _textController.clear();
    _focusNode.unfocus();

    final orchestrator = getIt<AgentOrchestrator>();
    if (orchestrator.isIdle) {
      orchestrator.sendMessage(text);
      getIt<AnalyticsService>().logAiQuery(
        model: getIt<ModelCubit>().activeModelId ?? 'unknown');
    }

    getIt<SessionCubit>().saveCurrentSession();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollToLatest();
    });
  }

  void _closeConversation() {
    _headerSwitch.reverse().then((_) {
      if (mounted) {
        getIt<SessionCubit>().closeActiveSession();
        setState(() {
          _hasSentMessage = false;
          _messages.clear();
          _textController.clear();
          _focusNode.unfocus();
          showScrollBtn = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final contentWidth = Responsive.contentMaxWidth(context);

    return StreamBuilder<OrchestratorState>(
      stream: getIt<AgentOrchestrator>().stream,
      initialData: getIt<AgentOrchestrator>().state,
      builder: (context, _) {
        if (!getIt<NavigationCubit>().isSettingsOpen &&
            getIt<NavigationCubit>().shouldShowDrawerAfterSettings) {
          getIt<NavigationCubit>().clearDrawerFlag();
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
              getIt<NavigationCubit>().setCurrentView(ViewState.discover);
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
                              chatTargetId: _chatTargetId,
                              chatTargetName: _chatTargetName,
                              onClose: _closeFriendChat,
                              maxWidth: contentWidth))
                        else ...[
                          HomeHeader(
                            hasSentMessage: _hasSentMessage,
                            headerSwitch: _headerSwitch,
                            tabSwitch: _tabSwitch,
                            isLibraryMode: _isLibraryMode,
                            isIncognito: getIt<NavigationCubit>().isIncognito,
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
                              () => _showSearchBar = !_showSearchBar),
                            onOpenDiscover: () => getIt<NavigationCubit>()
                                .setCurrentView(ViewState.discover),
                            userAvatar: UserAvatar(
                              userId: getIt<MatrixCubit>().userId ?? '',
                              size: 30,
                              radius: 15)),
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
                                  getIt<NavigationCubit>().isIncognito,
                              isFriendChat: _isFriendChat,
                              isGenerating:
                                  !getIt<AgentOrchestrator>().isIdle,
                              maxWidth: contentWidth,
                              onSend: _sendMessage,
                              onToggleListening: _toggleListening,
                              onCancelEdit: _cancelEdit,
                              onToggleIncognito: () =>
                                  getIt<NavigationCubit>().setIsIncognito(
                                    !getIt<NavigationCubit>().isIncognito),
                              onShowOptions: _showOptionsSheet,
                              onShowModels: _showModelsSheet,
                              onChanged: () => setState(() {}),
                              onStopGeneration: () =>
                                  getIt<AgentOrchestrator>().interrupt()),
                        ],
                      ]))),
                if (_isLeftDrawerOpen)
                  AppDrawer(
                    key: _drawerKey,
                    onClose: () => setState(() => _isLeftDrawerOpen = false),
                    onOpenNotifications: _openNotifications,
                    onOpenSettings: _openSettingsFromDrawer),
              ])));
      });
  }

  Widget _buildCenterContent() {
    if (_isLibraryMode) {
      return LibraryPanel(
        showSearchBar: _showSearchBar,
        onToggleSearch: () => setState(() => _showSearchBar = !_showSearchBar),
        onCreateGroupChat: _showCreateGroupChat,
        onOpenFriendChat: (id, name) => _openFriendChat(id, name));
    }
    if (_hasSentMessage) {
      return ConversationContent(
        messages: _messages,
        expandedThoughts: _expandedThoughts,
        scrollController: scrollController,
        lastUserBubbleKey: lastUserBubbleKey,
        showScrollBtn: showScrollBtn,
        orchestrator: getIt<AgentOrchestrator>(),
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
          onReport: () => reportNotHelpful(index)),
        onMessageLongPress: (index) => HomeDialogs.showMoreMenu(
          context,
          _messages[index].content,
          index,
          onEdit: () => editQuery(index),
          onDelete: () => deleteMessagePair(index),
          onReport: () => reportNotHelpful(index)));
    }
    if (getIt<NavigationCubit>().isIncognito) {
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
                  color: AppColors.textPrimary(context))),
              const SizedBox(height: 16),
              Text(
                localeProvider.t('incognito_notice'),
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.mut(context),
                  height: 1.6),
                textAlign: TextAlign.center),
            ])));
    }
    return Center(
      child: Text(
        'Omnivium',
        style: TextStyle(
          fontSize: 36,
          color: AppColors.textPrimary(context),
          fontFamily: 'serif')));
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
    final orchestrator = getIt<AgentOrchestrator>();
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
      });
  }

  void _openNotifications() {
    _closeDrawer();
    nav.AppNavigator.go<void>(context, '/notifications');
  }

  void _showCreateGroupChat() {
    nav.AppNavigator.go<void>(context, '/create-group');
  }

  void _showOptionsSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SlidingSheet(
        child: OptionsContent(
          onClose: () => Navigator.pop(context))));
  }

  void _showModelsSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SlidingSheet(
        child: ModelsContent(
          onClose: () => Navigator.pop(context))));
  }
}
