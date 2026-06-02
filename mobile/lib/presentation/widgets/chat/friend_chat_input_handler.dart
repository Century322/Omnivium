import 'package:flutter/material.dart';
import '../../../core/di/app_di.dart';
import '../../../core/voice_service.dart';
import '../../../core/database_service.dart';
import '../../../core/matrix/matrix_cubit.dart';
import 'package:omnivium/presentation/widgets/chat/emoji_picker_widget.dart';

mixin FriendChatInputHandler on State {
  String get chatTargetId;
  TextEditingController get textController;
  FocusNode get focusNode;
  bool get isListening;
  set isListening(bool value);
  AnimationController get listeningGlowCtrl;
  bool get showEmojiPickerState;
  set showEmojiPickerState(bool value);

  void toggleListening() async {
    final voice = getIt<VoiceService>();
    if (isListening) {
      await voice.stopListening();
      if (!mounted) return;
      isListening = false;
      listeningGlowCtrl.reverse();
    } else {
      final ok = await voice.startListening();
      if (!ok || !mounted) return;
      isListening = true;
      listeningGlowCtrl.forward();
    }
  }

  DateTime? _lastTypingNotice;

  void sendTypingNotice() {
    if (chatTargetId.isEmpty) return;
    final now = DateTime.now();
    final lastNotice = _lastTypingNotice;
    if (lastNotice != null && now.difference(lastNotice).inSeconds < 3) {
      return;
    }
    _lastTypingNotice = now;
    getIt<MatrixCubit>().sendTypingNotification(chatTargetId, isTyping: true);
  }

  void toggleEmojiPicker() {
    showEmojiPickerState = !showEmojiPickerState;
    if (showEmojiPickerState) {
      focusNode.unfocus();
    }
  }

  void insertEmoji(String emoji) {
    final text = textController.text;
    final sel = textController.selection;
    final start = sel.start >= 0 ? sel.start : text.length;
    final end = sel.end >= 0 ? sel.end : text.length;
    final newText = text.replaceRange(start, end, emoji);
    textController.text = newText;
    textController.selection = TextSelection.collapsed(
      offset: start + emoji.length);
    setState(() {});
  }

  Widget buildEmojiPicker() {
    if (!showEmojiPickerState) return const SizedBox.shrink();
    return EmojiPickerWidget(
      onEmojiSelected: insertEmoji,
      onClose: () => showEmojiPickerState = false);
  }

  void restoreDraft() {
    final db = getIt<DatabaseService>();
    final draft = db.getData('draft_$chatTargetId');
    if (draft != null) {
      final text = draft['text'] as String? ?? '';
      if (text.isNotEmpty) {
        textController.text = text;
      }
    }
  }

  void saveDraft() {
    final db = getIt<DatabaseService>();
    final text = textController.text.trim();
    if (text.isEmpty) {
      db.deleteData('draft_$chatTargetId');
    } else {
      db.putData('draft_$chatTargetId', {'text': text});
    }
  }
}
