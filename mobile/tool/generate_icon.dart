import 'dart:io';
import 'package:image/image.dart';

void main() {
  final sourceBytes = File('../6dcc40c5b576c48046a09a5544fed162.jpg').readAsBytesSync();
  final src = decodeImage(sourceBytes)!;

  final binary = List.generate(src.height, (_) => List.filled(src.width, false));
  for (int y = 0; y < src.height; y++) {
    for (int x = 0; x < src.width; x++) {
      final p = src.getPixel(x, y);
      binary[y][x] = p.r.toInt() > 40 || p.g.toInt() > 40 || p.b.toInt() > 40;
    }
  }

  final darkBg = ColorRgba8(0x1C, 0x1C, 0x1E, 255);
  final lightBg = ColorRgba8(0xF5, 0xF5, 0xF7, 255);
  final darkLogo = ColorRgba8(0x1C, 0x1C, 0x1E, 255);
  final lightLogo = ColorRgba8(0xF5, 0xF5, 0xF7, 255);

  final sizes = [1024, 512, 192, 180, 167, 152, 120, 87, 80, 76, 60, 58, 40, 29, 20];

  for (final size in sizes) {
    final darkIcon = renderIconHQ(src, binary, size, darkBg, lightLogo);
    File('assets/icon/app_icon_${size}x$size.png').writeAsBytesSync(encodePng(darkIcon));
  }

  final mainIcon = renderIconHQ(src, binary, 1024, darkBg, lightLogo);
  File('assets/icon/app_icon.png').writeAsBytesSync(encodePng(mainIcon));

  final fgIcon = renderForegroundHQ(src, binary, 1024);
  File('assets/icon/app_icon_foreground.png').writeAsBytesSync(encodePng(fgIcon));

  final webIcon192 = renderIconHQ(src, binary, 192, darkBg, lightLogo);
  File('web/icons/Icon-192.png').writeAsBytesSync(encodePng(webIcon192));
  File('web/icons/Icon-maskable-192.png').writeAsBytesSync(encodePng(webIcon192));

  final webIcon512 = renderIconHQ(src, binary, 512, darkBg, lightLogo);
  File('web/icons/Icon-512.png').writeAsBytesSync(encodePng(webIcon512));
  File('web/icons/Icon-maskable-512.png').writeAsBytesSync(encodePng(webIcon512));

  final favicon = renderIconHQ(src, binary, 32, darkBg, lightLogo);
  File('web/favicon.png').writeAsBytesSync(encodePng(favicon));

  final lightSplash = renderIconHQ(src, binary, 1024, lightBg, darkLogo);
  File('assets/icon/app_icon_light_splash.png').writeAsBytesSync(encodePng(lightSplash));

  // ignore: avoid_print
  print('All icons generated with HQ rendering!');
}

Image renderIconHQ(Image src, List<List<bool>> binary, int size, ColorRgba8 bgColor, ColorRgba8 logoColor) {
  final img = Image(width: size, height: size);
  fill(img, color: bgColor);

  final padding = (size * 0.15).round();
  final iconSize = size - padding * 2;

  final resized = copyResize(
    src,
    width: iconSize,
    height: iconSize,
    interpolation: Interpolation.cubic,
  );

  for (int y = 0; y < resized.height; y++) {
    for (int x = 0; x < resized.width; x++) {
      final p = resized.getPixel(x, y);
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();
      final brightness = (r * 0.299 + g * 0.587 + b * 0.114).round();
      if (brightness > 30) {
        final alpha = (brightness / 255.0).clamp(0.0, 1.0);
        final lr = logoColor.r;
        final lg = logoColor.g;
        final lb = logoColor.b;
        final br = bgColor.r;
        final bg2 = bgColor.g;
        final bb = bgColor.b;
        final fr = (lr * alpha + br * (1 - alpha)).round();
        final fg = (lg * alpha + bg2 * (1 - alpha)).round();
        final fb = (lb * alpha + bb * (1 - alpha)).round();
        img.setPixel(x + padding, y + padding, ColorRgba8(fr, fg, fb, 255));
      }
    }
  }

  return img;
}

Image renderForegroundHQ(Image src, List<List<bool>> binary, int size) {
  final img = Image(width: size, height: size, numChannels: 4);
  fill(img, color: ColorRgba8(0, 0, 0, 0));

  final padding = (size * 0.16).round();
  final iconSize = size - padding * 2;

  final resized = copyResize(
    src,
    width: iconSize,
    height: iconSize,
    interpolation: Interpolation.cubic,
  );

  for (int y = 0; y < resized.height; y++) {
    for (int x = 0; x < resized.width; x++) {
      final p = resized.getPixel(x, y);
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();
      final brightness = (r * 0.299 + g * 0.587 + b * 0.114).round();
      if (brightness > 30) {
        final alpha = (brightness / 255.0 * 255).round().clamp(0, 255);
        img.setPixel(x + padding, y + padding, ColorRgba8(0xFF, 0xFF, 0xFF, alpha));
      }
    }
  }

  return img;
}
