import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/locale_cubit.dart';

class IncognitoIcon extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color color;

  const IncognitoIcon({
    super.key,
    this.size = 18,
    this.strokeWidth = 2,
    this.color = AppColors.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: localeProvider.t('incognito_mode'),
      child: CustomPaint(
        size: Size(size, size),
        painter: _IncognitoPainter(strokeWidth: strokeWidth, color: color)));
  }
}

class _IncognitoPainter extends CustomPainter {
  final double strokeWidth;
  final Color color;

  _IncognitoPainter({required this.strokeWidth, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth * (size.width / 24)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final s = size.width / 24;

    final path1 = Path()
      ..moveTo(2 * s, 10 * s)
      ..lineTo(2 * s, 8 * s)
      ..cubicTo(2 * s, 5.8 * s, 3.8 * s, 4 * s, 6 * s, 4 * s)
      ..lineTo(18 * s, 4 * s)
      ..cubicTo(20.2 * s, 4 * s, 22 * s, 5.8 * s, 22 * s, 8 * s)
      ..lineTo(22 * s, 10 * s)
      ..lineTo(22 * s, 14 * s)
      ..cubicTo(22 * s, 15.1 * s, 21.1 * s, 16 * s, 20 * s, 16 * s)
      ..lineTo(18.7 * s, 16 * s)
      ..cubicTo(18.1 * s, 16 * s, 17.5 * s, 15.7 * s, 17.1 * s, 15.2 * s)
      ..lineTo(15.8 * s, 13.8 * s)
      ..cubicTo(15.4 * s, 13.4 * s, 14.8 * s, 13.1 * s, 14.2 * s, 13.1 * s)
      ..lineTo(11.8 * s, 13.1 * s)
      ..cubicTo(11.2 * s, 13.1 * s, 10.6 * s, 13.4 * s, 10.2 * s, 13.8 * s)
      ..lineTo(8.9 * s, 15.2 * s)
      ..cubicTo(8.5 * s, 15.7 * s, 7.9 * s, 16 * s, 7.3 * s, 16 * s)
      ..lineTo(6 * s, 16 * s)
      ..cubicTo(4.9 * s, 16 * s, 4 * s, 15.1 * s, 4 * s, 14 * s)
      ..lineTo(4 * s, 10 * s);

    final path2 = Path()
      ..moveTo(2 * s, 10 * s)
      ..lineTo(22 * s, 10 * s);
    final path3 = Path()
      ..moveTo(12 * s, 10 * s)
      ..lineTo(12 * s, 14 * s);

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
