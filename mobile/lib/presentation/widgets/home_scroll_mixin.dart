import 'package:flutter/material.dart';
import '../widgets/home_components.dart';

mixin HomeScrollMixin<T extends StatefulWidget> on State<T> {
  final ScrollController scrollController = ScrollController();
  final GlobalKey lastUserBubbleKey = GlobalKey();
  bool showScrollBtn = false;
  double maxScrollOffset = 0;
  bool _isAutoScrolling = false;

  List<ChatMessageData> get messages;

  void initScrollListener() {
    scrollController.addListener(_onScrollChanged);
  }

  void disposeScrollListener() {
    scrollController.dispose();
  }

  void _onScrollChanged() {
    if (!scrollController.hasClients || _isAutoScrolling) return;
    _clampScroll();
    _updateScrollBtn();
  }

  void _clampScroll() {
    if (!scrollController.hasClients) return;
    final userCount = messages.where((m) => m.role == 'user').length;
    if (userCount <= 1 || maxScrollOffset <= 0) return;
    if (scrollController.offset > maxScrollOffset) {
      scrollController.jumpTo(maxScrollOffset);
    }
  }

  void _updateScrollBtn() {
    final userCount = messages.where((m) => m.role == 'user').length;
    if (userCount <= 1) {
      if (showScrollBtn) setState(() => showScrollBtn = false);
      return;
    }
    if (maxScrollOffset <= 0) return;
    final shouldShow = scrollController.offset < maxScrollOffset - 10;
    if (showScrollBtn != shouldShow) {
      setState(() => showScrollBtn = shouldShow);
    }
  }

  void calcMaxScrollOffset() {
    final ctx = lastUserBubbleKey.currentContext;
    if (ctx == null) return;
    final renderBox = ctx.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final headerBottom = MediaQuery.of(context).padding.top + 68;
    final widgetTop = renderBox.localToGlobal(Offset.zero).dy;
    maxScrollOffset = scrollController.offset + widgetTop - headerBottom;
  }

  void scrollToLatest() {
    final target = maxScrollOffset > 0
        ? maxScrollOffset
        : scrollController.position.maxScrollExtent;
    if (target <= 0) return;
    _isAutoScrolling = true;
    scrollController
        .animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        )
        .then((_) {
          if (mounted) {
            _isAutoScrolling = false;
            setState(() => showScrollBtn = false);
          }
        });
  }

  void resetMaxScrollOffset() {
    maxScrollOffset = 0;
  }
}
