import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String userId;
  final double size;
  final double radius;

  const UserAvatar({
    super.key,
    required this.userId,
    this.size = 30,
    this.radius = 15,
  });

  @override
  Widget build(BuildContext context) {
    final initial = userId.isNotEmpty
        ? userId.split(':').first.replaceAll('@', '').toUpperCase()
        : '?';
    final letter = initial.isNotEmpty ? initial[0] : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.acc(context).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: AppColors.acc(context),
            fontSize: size * 0.45,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
