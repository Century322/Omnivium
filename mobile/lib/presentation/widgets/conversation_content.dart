import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../widgets/home_components.dart';
import '../widgets/thought_chain_panel.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/ai_bubbles.dart';
import '../../core/agent/agent_orchestrator.dart';

class ConversationContent extends StatelessWidget {
  final List<ChatMessageData> messages;
  final Set<int> expandedThoughts;
  final ScrollController scrollController;
  final GlobalKey lastUserBubbleKey;
  final bool showScrollBtn;
  final AgentOrchestrator orchestrator;
  final VoidCallback onScrollToLatest;
  final ValueChanged<int> onToggleThought;
  final VoidCallback onRegenerate;
  final ValueChanged<String> onCopy;
  final VoidCallback onSpeak;
  final ValueChanged<String> onShare;
  final void Function(String content, int index) onMore;
  final void Function(int index)? onMessageLongPress;

  const ConversationContent({
    super.key,
    required this.messages,
    required this.expandedThoughts,
    required this.scrollController,
    required this.lastUserBubbleKey,
    required this.showScrollBtn,
    required this.orchestrator,
    required this.onScrollToLatest,
    required this.onToggleThought,
    required this.onRegenerate,
    required this.onCopy,
    required this.onSpeak,
    required this.onShare,
    required this.onMore,
    this.onMessageLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final items = _buildItems(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            ScrollConfiguration(
              behavior: NoScrollbarBehavior(),
              child: ListView.builder(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8),
                itemCount: items.length + 1,
                itemBuilder: (_, index) {
                  if (index == items.length) {
                    return SizedBox(height: constraints.maxHeight);
                  }
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: items[index].bottomPadding),
                    child: items[index].widget);
                })),
            if (showScrollBtn)
              Positioned(
                right: 20,
                bottom: 8,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onScrollToLatest,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.sf(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.divider(context)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.bg(context).withValues(alpha: 0.3),
                          blurRadius: 8),
                      ]),
                    child: Icon(
                      LucideIcons.chevronDown,
                      size: 18,
                      color: AppColors.sec(context))))),
          ]);
      });
  }

  List<ListItemData> _buildItems(BuildContext context) {
    final longPress = onMessageLongPress;
    final items = <ListItemData>[];
    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      if (msg.role == 'user') {
        items.add(
          ListItemData(
            UserBubble(
              content: msg.content,
              onLongPress: longPress != null ? () => longPress(i) : null),
            12));
      } else {
        if (msg.thoughts.isNotEmpty) {
          items.add(
            ListItemData(
              ThoughtChainPanel(
                thoughts: msg.thoughts,
                isExpanded: expandedThoughts.contains(i),
                onToggle: () => onToggleThought(i)),
              4));
        }
        items.add(
          ListItemData(
            AiTextBubble(
              content: msg.content,
              isStreaming: msg.isStreaming,
              onLongPress: longPress != null ? () => longPress(i) : null),
            12));
        final isLastAi = i == messages.length - 1 && !msg.isStreaming;
        if (isLastAi) {
          items.add(
            ListItemData(
              AiActionRow(
                content: msg.content,
                msgIndex: i,
                onRegenerate: onRegenerate,
                onCopy: () => onCopy(msg.content),
                onSpeak: onSpeak,
                onShare: () => onShare(msg.content),
                onMore: () => onMore(msg.content, i)),
              36));
          final logs = orchestrator.executionLogs;
          if (logs.isNotEmpty) {
            items.add(ListItemData(ExecutionLogBubble(log: logs.last), 8));
          }
        }
        if (msg.isStreaming && i == messages.length - 1) {
          final currentThoughts = orchestrator.currentThoughts;
          if (currentThoughts.isNotEmpty) {
            items.add(
              ListItemData(
                ThoughtChainPanel(thoughts: currentThoughts, isExpanded: true),
                4));
          }
          if (orchestrator.isThinking || orchestrator.isReflecting) {
            items.add(const ListItemData(ThinkingIndicator(), 4));
            items.add(const ListItemData(CardSkeleton(), 4));
          }
        }
      }
    }
    return items;
  }
}
