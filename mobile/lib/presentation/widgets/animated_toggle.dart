import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';
import '../../core/haptic_service.dart';

class AnimatedToggle extends StatefulWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;

  const AnimatedToggle({
    super.key,
    required this.enabled,
    required this.onChanged,
    this.semanticLabel,
  });

  @override
  State<AnimatedToggle> createState() => _AnimatedToggleState();
}

class _AnimatedToggleState extends State<AnimatedToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _position = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    if (widget.enabled) _controller.value = 1;
  }

  @override
  void didUpdateWidget(AnimatedToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticService.toggleSwitch();
        widget.onChanged(!widget.enabled);
      },
      child: Semantics(
        toggled: widget.enabled,
        label: widget.semanticLabel != null
            ? '${widget.semanticLabel}, ${widget.enabled ? localeProvider.t('enabled') : localeProvider.t('disabled')}'
            : (widget.enabled
                  ? localeProvider.t('enabled')
                  : localeProvider.t('disabled')),
        child: AnimatedBuilder(
          animation: _position,
          builder: (context, child) {
            return Container(
              width: 50,
              height: 28,
              decoration: BoxDecoration(
                color: Color.lerp(
                  AppColors.sfHover(context),
                  AppColors.acc(context),
                  _position.value,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Align(
                  alignment: Alignment.lerp(
                    Alignment.centerLeft,
                    Alignment.centerRight,
                    _position.value,
                  )!,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary(context),
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.bg(context).withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
