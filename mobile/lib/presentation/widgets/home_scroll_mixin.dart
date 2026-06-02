import 'package:flutter/material.dart';
import '../widgets/home_components.dart';

mixin HomeScrollMixin<T extends StatefulWidget> on State<T> {
  final ScrollController scrollController = ScrollController();
  bool showScrollBtn = false;
  bool _isAutoScrolling = false;
  bool _userAtBottom = true;

  List<ChatMessageData> get messages;

  void initScrollListener() {
    scrollController.addListener(_onScrollChanged);
  }

  void disposeScrollListener() {
    scrollController.dispose();
  }

  void _onScrollChanged() {
    if (!scrollController.hasClients || _isAutoScrolling) return;
    _detectUserAtBottom();
    _updateScrollBtn();
  }

  void _detectUserAtBottom() {
    if (!scrollController.hasClients) return;
    final max = scrollController.position.maxScrollExtent;
    final offset = scrollController.offset;
    final wasAtBottom = _userAtBottom;
    _userAtBottom = max - offset < 80;
    if (wasAtBottom != _userAtBottom) {
      setState(() {});
    }
  }

  bool get shouldAutoScroll => _userAtBottom;

  void _updateScrollBtn() {
    if (!scrollController.hasClients) return;
    final max = scrollController.position.maxScrollExtent;
    if (max <= 0) {
      if (showScrollBtn) setState(() => showScrollBtn = false);
      return;
    }
    final shouldShow = max - scrollController.offset > 80;
    if (showScrollBtn != shouldShow) {
      setState(() => showScrollBtn = shouldShow);
    }
  }

  void scrollToLatest() {
    if (!scrollController.hasClients) return;
    final target = scrollController.position.maxScrollExtent;
    if (target <= 0) return;
    _isAutoScrolling = true;
    _userAtBottom = true;
    scrollController
        .animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut)
        .then((_) {
          if (mounted) {
            _isAutoScrolling = false;
            setState(() => showScrollBtn = false);
          }
        });
  }
}
