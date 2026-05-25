import 'dart:io';
import 'dart:math';
import 'package:image/image.dart';

void main() {
  final sizes = [1024, 512, 192, 180, 167, 152, 120, 87, 80, 76, 60, 58, 40, 29, 20];

  for (final size in sizes) {
    final img = generateIcon(size);
    final file = File('assets/icon/app_icon_${size}x${size}.png');
    file.writeAsBytesSync(encodePng(img));
    print('Generated: ${file.path}');
  }

  final mainIcon = generateIcon(1024);
  File('assets/icon/app_icon.png').writeAsBytesSync(encodePng(mainIcon));
  print('Generated: assets/icon/app_icon.png');

  final fgIcon = generateForeground(1024);
  File('assets/icon/app_icon_foreground.png').writeAsBytesSync(encodePng(fgIcon));
  print('Generated: assets/icon/app_icon_foreground.png');

  print('Done!');
}

final bgColor = ColorRgba8(255, 255, 255, 255);
final fgColor = ColorRgba8(26, 26, 46, 255);

Image generateIcon(int size) {
  final img = Image(width: size, height: size);
  fill(img, color: bgColor);

  final cx = size ~/ 2;
  final cy = size ~/ 2;
  final outerRadius = (size * 0.34).round();
  final innerRadius = (size * 0.26).round();

  fillCircle(img, x: cx, y: cy, radius: outerRadius, color: fgColor);
  fillCircle(img, x: cx, y: cy, radius: innerRadius, color: bgColor);

  final dotRadius = (size * 0.045).round();
  fillCircle(img, x: cx, y: cy, radius: dotRadius, color: fgColor);

  return img;
}

Image generateForeground(int size) {
  final img = Image(width: size, height: size);
  fill(img, color: ColorRgba8(0, 0, 0, 0));

  final cx = size ~/ 2;
  final cy = size ~/ 2;
  final outerRadius = (size * 0.34).round();
  final innerRadius = (size * 0.26).round();

  fillCircle(img, x: cx, y: cy, radius: outerRadius, color: fgColor);
  fillCircle(img, x: cx, y: cy, radius: innerRadius, color: ColorRgba8(0, 0, 0, 0));

  final dotRadius = (size * 0.045).round();
  fillCircle(img, x: cx, y: cy, radius: dotRadius, color: fgColor);

  return img;
}
