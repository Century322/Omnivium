import 'dart:io';
import 'package:image/image.dart';

void main() {
  final sourcePath = '../6dcc40c5b576c48046a09a5544fed162.jpg';
  final sourceBytes = File(sourcePath).readAsBytesSync();
  final sourceImage = decodeImage(sourceBytes)!;

  final darkBg = ColorRgba8(0x1C, 0x1C, 0x1E, 255);
  final lightBg = ColorRgba8(0xF5, 0xF5, 0xF7, 255);

  final sizes = [1024, 512, 192, 180, 167, 152, 120, 87, 80, 76, 60, 58, 40, 29, 20];

  for (final size in sizes) {
    final darkIcon = composeIcon(sourceImage, size, darkBg);
    File('assets/icon/app_icon_${size}x$size.png').writeAsBytesSync(encodePng(darkIcon));
  }

  final mainIcon = composeIcon(sourceImage, 1024, darkBg);
  File('assets/icon/app_icon.png').writeAsBytesSync(encodePng(mainIcon));

  final fgIcon = composeForeground(sourceImage, 1024);
  File('assets/icon/app_icon_foreground.png').writeAsBytesSync(encodePng(fgIcon));

  final webIcon192 = composeIcon(sourceImage, 192, darkBg);
  File('web/icons/Icon-192.png').writeAsBytesSync(encodePng(webIcon192));

  final webIcon512 = composeIcon(sourceImage, 512, darkBg);
  File('web/icons/Icon-512.png').writeAsBytesSync(encodePng(webIcon512));

  final webMaskable192 = composeIcon(sourceImage, 192, darkBg);
  File('web/icons/Icon-maskable-192.png').writeAsBytesSync(encodePng(webMaskable192));

  final webMaskable512 = composeIcon(sourceImage, 512, darkBg);
  File('web/icons/Icon-maskable-512.png').writeAsBytesSync(encodePng(webMaskable512));

  final favicon = composeIcon(sourceImage, 32, darkBg);
  File('web/favicon.png').writeAsBytesSync(encodePng(favicon));

  print('All icons generated successfully!');
}

Image composeIcon(Image source, int size, ColorRgba8 bgColor) {
  final img = Image(width: size, height: size);
  fill(img, color: bgColor);

  final padding = (size * 0.15).round();
  final iconSize = size - padding * 2;
  final resized = copyResize(source, width: iconSize, height: iconSize);

  for (int y = 0; y < resized.height; y++) {
    for (int x = 0; x < resized.width; x++) {
      final pixel = resized.getPixel(x, y);
      img.setPixel(x + padding, y + padding, pixel);
    }
  }

  return img;
}

Image composeForeground(Image source, int size) {
  final img = Image(width: size, height: size);
  fill(img, color: ColorRgba8(0, 0, 0, 0));

  final padding = (size * 0.16).round();
  final iconSize = size - padding * 2;
  final resized = copyResize(source, width: iconSize, height: iconSize);

  for (int y = 0; y < resized.height; y++) {
    for (int x = 0; x < resized.width; x++) {
      final pixel = resized.getPixel(x, y);
      img.setPixel(x + padding, y + padding, pixel);
    }
  }

  return img;
}
