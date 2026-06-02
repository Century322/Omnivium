
import '../../core/di/app_di.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/voice_service.dart';
import '../theme/app_colors.dart';
import '../theme/locale_cubit.dart';
import '../widgets/home_components.dart';
import '../../core/agent/agent_orchestrator.dart';
import '../../core/session_cubit.dart';

mixin HomeMessageActionsMixin<T extends StatefulWidget> on State<T> { List<ChatMessageData> get messages;
  TextEditingController get textController;
  FocusNode get focusNode;
  int get editingIndex;
  set editingIndex(int value);
  void markNeedsRebuild();

  void editQuery(int index) {
    if (index <= 0 || index >= messages.length) return;
    setState(() {
      editingIndex = index - 1;
      textController.text = messages[index - 1].content;
    });
    focusNode.requestFocus();
  }

  void deleteMessagePair(int index) {
    if (index <= 0 || index >= messages.length) return;
    getIt<AgentOrchestrator>().deleteMessagePair(index);
    setState(() {
      editingIndex = -1;
    });
    getIt<SessionCubit>().saveCurrentSession();
  }

  void reportNotHelpful(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localeProvider.t('feedback_recorded')),
        duration: const Duration(seconds: 2)));
  }

  void regenerateResponse() {
    final orchestrator = getIt<AgentOrchestrator>();
    if (!orchestrator.isIdle) return;
    final orchMsgs = orchestrator.messages;
    if (orchMsgs.isEmpty) return;
    String? lastUserMsg;
    for (var i = orchMsgs.length - 1; i >= 0; i--) {
      if (orchMsgs[i].role == 'user') {
        lastUserMsg = orchMsgs[i].content;
        break;
      }
    }
    if (lastUserMsg == null) return;
    if (orchMsgs.isNotEmpty && orchMsgs.last.role == 'assistant') {
      orchestrator.deleteMessagePair(orchMsgs.length - 1);
    }
    orchestrator.sendMessage(lastUserMsg);
  }

  void copyContent(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localeProvider.t('copied')),
        backgroundColor: AppColors.acc(context),
        duration: const Duration(milliseconds: 1500)));
  }

  void speakLastResponse() {
    final orch = getIt<AgentOrchestrator>();
    final msgs = orch.messages;
    if (msgs.isEmpty) return;
    final last = msgs.last;
    if (last.role == 'assistant' && last.content.isNotEmpty) {
      getIt<VoiceService>().speak(last.content);
    }
  }

  void shareMessage(String content) {
    SharePlus.instance.share(ShareParams(text: content));
  }
}
