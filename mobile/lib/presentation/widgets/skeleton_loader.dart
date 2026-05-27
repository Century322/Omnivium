import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../core/lite_mode.dart';

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (LiteMode.instance.smoothAnimationsEnabled) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
          color: AppColors.sf(context).withValues(alpha: 0.3),
        ),
      );
    }
    return Semantics(
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _controller ?? kAlwaysCompleteAnimation,
        builder: (context, child) {
          final ctrl = _controller;
          final value = ctrl?.value ?? 0.0;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
              gradient: LinearGradient(
                begin: Alignment(-1.0 + 2.0 * value, 0),
                end: Alignment(1.0 + 2.0 * value, 0),
                colors: [
                  AppColors.sf(context),
                  AppColors.sf(context).withValues(alpha: 0.3),
                  AppColors.sf(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class MessageSkeleton extends StatelessWidget {
  final bool isUser;
  const MessageSkeleton({super.key, this.isUser = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.only(
          left: isUser ? 60 : 16,
          right: isUser ? 16 : 60,
          top: 8,
          bottom: 8,
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUser) ...[
                  const SkeletonLoader(
                    width: 32,
                    height: 32,
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  const SizedBox(width: 8),
                ],
                const SkeletonLoader(width: 80, height: 12),
              ],
            ),
            const SizedBox(height: 6),
            const SkeletonLoader(width: 200, height: 14),
            const SizedBox(height: 4),
            const SkeletonLoader(width: 150, height: 14),
          ],
        ),
      ),
    );
  }
}

class ChatListSkeleton extends StatelessWidget {
  final int count;
  const ChatListSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      excludeSemantics: true,
      child: Column(
        children: List.generate(
          count,
          (i) => const MessageSkeleton(isUser: false),
        ),
      ),
    );
  }
}

class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      excludeSemantics: true,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SkeletonLoader(width: 120, height: 16),
              SizedBox(height: 12),
              SkeletonLoader(height: 12),
              SizedBox(height: 4),
              SkeletonLoader(width: 200, height: 12),
              SizedBox(height: 4),
              SkeletonLoader(width: 160, height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
