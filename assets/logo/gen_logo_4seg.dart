import 'dart:math';
import 'dart:io';

class Seg {
  final double spanDeg;
  final double thicknessMult;
  final double gapAfterDeg;
  final String label;

  const Seg({
    required this.spanDeg,
    required this.thicknessMult,
    required this.gapAfterDeg,
    required this.label,
  });
}

void main() {
  const cx = 256.0;
  const cy = 256.0;
  const baseR = 175.0;
  const baseThickness = 10.0;
  const gap = 12.0;
  const segSpan = 78.0;
  const rotationDeg = 18.0;

  const segments = [
    Seg(spanDeg: segSpan, thicknessMult: 1.3, gapAfterDeg: gap, label: "THICK"),
    Seg(spanDeg: segSpan, thicknessMult: 1.0, gapAfterDeg: gap, label: "normal"),
    Seg(spanDeg: segSpan, thicknessMult: 1.3, gapAfterDeg: gap, label: "THICK"),
    Seg(spanDeg: segSpan, thicknessMult: 1.0, gapAfterDeg: gap, label: "normal"),
  ];

  generateSvg(String strokeColor, String bgColor, String filename) {
    final sb = StringBuffer();
    sb.writeln('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">');
    sb.writeln('  <rect width="512" height="512" fill="$bgColor"/>');
    sb.writeln('  <g transform="translate($cx, $cy)">');

    double currentAngle = -90 + gap + rotationDeg;

    for (final seg in segments) {
      final startAngle = currentAngle;
      final endAngle = currentAngle + seg.spanDeg;

      final r = baseR;
      final sw = baseThickness * seg.thicknessMult;

      final x1 = r * cos(startAngle * pi / 180);
      final y1 = r * sin(startAngle * pi / 180);
      final x2 = r * cos(endAngle * pi / 180);
      final y2 = r * sin(endAngle * pi / 180);
      final largeArc = seg.spanDeg > 180 ? 1 : 0;

      sb.writeln('');
      sb.writeln('    <!-- ${seg.label} -->');
      sb.writeln(
          '    <path d="M ${x1.toStringAsFixed(2)},${y1.toStringAsFixed(2)} A ${r.toStringAsFixed(2)},${r.toStringAsFixed(2)} 0 $largeArc,1 ${x2.toStringAsFixed(2)},${y2.toStringAsFixed(2)}"');
      sb.writeln(
          '          fill="none" stroke="$strokeColor" stroke-width="${sw.toStringAsFixed(2)}" stroke-linecap="round"/>');

      currentAngle = endAngle + seg.gapAfterDeg;
    }

    sb.writeln('  </g>');
    sb.writeln('</svg>');

    File(filename).writeAsStringSync(sb.toString());
    print('Generated: $filename');
  }

  generateSvg('#000000', '#FFFFFF', 'omnivium_logo_4seg_light.svg');
  generateSvg('#FFFFFF', '#000000', 'omnivium_logo_4seg_dark.svg');
  print('Done!');
}
