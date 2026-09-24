// GenerateJimsBrand — draws a professional JIMS brand mark programmatically
// and exports it to every platform (Android, iOS, macOS, Windows, Web) plus
// in-app assets and favicons.
//
// Run from the project root:  dart run tool/generate_app_icons.dart
//
// ignore_for_file: avoid_print, unnecessary_string_interpolations
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

String get _root => Directory.current.path;

// ---------------------------------------------------------------------------
// Brand palette (mirrors lib/core/theme/app_theme.dart)
// ---------------------------------------------------------------------------
const _topColor = (r: 6, g: 95, b: 70); // Emerald 800  #065F46
const _bottomColor = (r: 52, g: 211, b: 153); // Emerald 400 #34D399
const _white = (r: 255, g: 255, b: 255, a: 255);

// Normalized (0..1) geometry of the "J" mark.
const _topBar = (x1: 0.316, y1: 0.301, x2: 0.684, y2: 0.301, t: 0.127);
const _stem = (x1: 0.684, y1: 0.364, x2: 0.684, y2: 0.691, t: 0.127);
const _stub = (x1: 0.316, y1: 0.691, x2: 0.620, y2: 0.691, t: 0.127);
const _shadowOffset = (dx: 0.012, dy: 0.016);

void main() {
  print('Drawing JIMS brand mark (1024x1024 master)...');
  final master = drawBrandImage(1024);
  _savePng(master, '$_root/assets/images/jims_icon_master.png');
  File('$_root/assets/images/jims_icon_master.jpg')
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodeJpg(master, quality: 95));
  _savePng(master, '$_root/assets/images/logo.png');

  // In-app assets (square, full-bleed rendering).
  _savePng(_resize(master, 512), '$_root/assets/images/logo_icon.png');
  _savePng(_resize(master, 512), '$_root/assets/icons/app_icon.png');

  // Favicons.
  final fav32 = _resize(drawBrandImage(512, rounded: true), 32);
  _savePng(fav32, '$_root/web/favicon.png');
  _savePng(fav32, '$_root/assets/icons/favicon-32x32.png');
  _savePng(_resize(drawBrandImage(512, rounded: true), 180), '$_root/web/apple-touch-icon.png');

  // Web PWA icons (maskable = full-bleed, centered glyph).
  _savePng(master, '$_root/web/icons/Icon-512.png');
  _savePng(_resize(master, 192), '$_root/web/icons/Icon-192.png');
  final maskable = drawBrandImage(512, rounded: false);
  _savePng(maskable, '$_root/web/icons/Icon-maskable-512.png');
  _savePng(_resize(maskable, 192), '$_root/web/icons/Icon-maskable-192.png');

  generateAndroid(master);
  generateIOS(master);
  generateMacOS(master);
  generateWindows(master);

  print('All platform icons regenerated successfully!');
}

// ---------------------------------------------------------------------------
// Brand mark drawing
// ---------------------------------------------------------------------------

/// Draws a brand tile in [size]x[size].
/// [rounded] true => superellipse/rounded-square canvas (app icons, favicon).
/// [rounded] false => full-bleed square, glyph centered (maskable PWA icons).
img.Image drawBrandImage(int size, {bool rounded = true}) {
  final canvas = img.Image(width: size, height: size, numChannels: 4);
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));

  // Background tile.
  _fillBrandBackground(canvas, size, rounded);

  // Drop shadow beneath the mark for depth.
  _drawJ(canvas, size, dx: _shadowOffset.dx * size, dy: _shadowOffset.dy * size, alpha: 56);

  // White mark.
  _drawJ(canvas, size, dx: 0, dy: 0, alpha: 255);

  return canvas;
}

void _fillBrandBackground(img.Image canvas, int size, bool rounded) {
  const inset = 0.035;
  final x1 = (size * inset).round();
  final y1 = (size * inset).round();
  final x2 = (size * (1 - inset)).round();
  final y2 = (size * (1 - inset)).round();

  if (!rounded) {
    for (var y = 0; y < size; y++) {
      final c = _lerpColor(_topColor, _bottomColor, y / math.max(1, size - 1));
      img.fillRect(
        canvas,
        x1: 0,
        y1: y,
        x2: size - 1,
        y2: y,
        color: c,
      );
    }
    return;
  }

  final radius = (size * 0.20).round();
  for (var y = y1; y <= y2; y++) {
    final c = _lerpColor(_topColor, _bottomColor, (y - y1) / math.max(1, y2 - y1));
    img.fillRect(canvas, x1: x1, y1: y, x2: x2, y2: y, color: c);
  }
  // Rounded corners: a full circle at each corner center only visibly fills
  // the quarter outside the square, producing a smooth rounded tile.
  img.fillCircle(
      canvas, x: x1 + radius, y: y1 + radius, radius: radius, color: _lerpColor(_topColor, _bottomColor, 0.0), antialias: true);
  img.fillCircle(canvas,
      x: x2 - radius, y: y1 + radius, radius: radius, color: _lerpColor(_topColor, _bottomColor, 0.0), antialias: true);
  img.fillCircle(canvas,
      x: x1 + radius, y: y2 - radius, radius: radius, color: _lerpColor(_topColor, _bottomColor, 1.0), antialias: true);
  img.fillCircle(canvas,
      x: x2 - radius, y: y2 - radius, radius: radius, color: _lerpColor(_topColor, _bottomColor, 1.0), antialias: true);
}

/// Draws the thick "J" monogram stroke (three rounded capsules).
void _drawJ(img.Image canvas, int size, {required double dx, required double dy, required int alpha}) {
  final color = img.ColorRgba8(_white.r, _white.g, _white.b, alpha);
  _capsule(
    canvas,
    from: offset(_topBar.x1 * size, _topBar.y1 * size, dx, dy),
    to: offset(_topBar.x2 * size, _topBar.y2 * size, dx, dy),
    thickness: _topBar.t * size,
    color: color,
  );
  _capsule(
    canvas,
    from: offset(_stem.x1 * size, _stem.y1 * size, dx, dy),
    to: offset(_stem.x2 * size, _stem.y2 * size, dx, dy),
    thickness: _stem.t * size,
    color: color,
  );
  _capsule(
    canvas,
    from: offset(_stub.x1 * size, _stub.y1 * size, dx, dy),
    to: offset(_stub.x2 * size, _stub.y2 * size, dx, dy),
    thickness: _stub.t * size,
    color: color,
  );
}

({double x, double y}) offset(double x, double y, double dx, double dy) =>
    (x: x + dx, y: y + dy);

void _capsule(img.Image canvas,
    {required ({double x, double y}) from,
    required ({double x, double y}) to,
    required double thickness,
    required img.Color color}) {
  final x1 = from.x.round();
  final y1 = from.y.round();
  final x2 = to.x.round();
  final y2 = to.y.round();
  final r = (thickness / 2).round();

  if (y1 == y2) {
    final x0 = math.min(x1, x2) - r;
    img.fillRect(
        canvas, x1: x0, y1: y1 - r, x2: math.max(x1, x2) + r, y2: y1 + r, color: color);
  } else {
    final y0 = math.min(y1, y2) - r;
    img.fillRect(
        canvas, x1: x1 - r, y1: y0, x2: x1 + r, y2: math.max(y1, y2) + r, color: color);
  }
  img.fillCircle(canvas, x: x1, y: y1, radius: r, color: color, antialias: true);
  img.fillCircle(canvas, x: x2, y: y2, radius: r, color: color, antialias: true);
}

img.Color _lerpColor(({int r, int g, int b}) a, ({int r, int g, int b}) b, double t) {
  t = t.clamp(0.0, 1.0);
  final r = (a.r + (b.r - a.r) * t).round();
  final g = (a.g + (b.g - a.g) * t).round();
  final bl = (a.b + (b.b - a.b) * t).round();
  return img.ColorRgba8(r, g, bl, 255);
}

img.Image _resize(img.Image src, int size) =>
    img.copyResize(src, width: size, height: size, interpolation: img.Interpolation.linear);

void _savePng(img.Image image, String path) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(image, level: 6));
  print('  saved $path');
}

void _saveBytes(List<int> bytes, String path) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);
  print('  saved $path');
}

// ---------------------------------------------------------------------------
// Platform exports
// ---------------------------------------------------------------------------

void generateAndroid(img.Image master) {
  print('Generating Android icons...');
  final base = '$_root/android/app/src/main/res';

  const mipmaps = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  for (final entry in mipmaps.entries) {
    final folder = '$base/${entry.key}';
    Directory(folder).createSync(recursive: true);
    final size = entry.value;
    final resized = _resize(master, size);
    _savePng(resized, '$folder/ic_launcher.png');
    _savePng(_makeCircular(resized), '$folder/ic_launcher_round.png');
  }

  // Adaptive foreground (108dp canvas @ xxxhdpi = 432px, safe zone = center 66%).
  const fgSize = 432;
  final box = img.Image(width: fgSize, height: fgSize, numChannels: 4);
  img.compositeImage(box, _resize(master, 280), dstX: (fgSize - 280) ~/ 2, dstY: (fgSize - 280) ~/ 2);
  _savePng(box, '$base/mipmap-xxxhdpi/ic_launcher_foreground.png');
  print('  Android icons complete.');
}

img.Image _makeCircular(img.Image src) {
  final out = img.Image(width: src.width, height: src.height, numChannels: 4);
  final r = src.width / 2.0;
  for (var y = 0; y < src.height; y++) {
    for (var x = 0; x < src.width; x++) {
      final dx = (x + 0.5) - r;
      final dy = (y + 0.5) - r;
      if ((dx * dx + dy * dy) <= r * r) {
        out.setPixel(x, y, src.getPixel(x, y));
      }
    }
  }
  return out;
}

void generateIOS(img.Image master) {
  print('Generating iOS icons...');
  final base = '$_root/ios/Runner/Assets.xcassets/AppIcon.appiconset';
  Directory(base).createSync(recursive: true);

  const iosSizes = {
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
  };

  for (final entry in iosSizes.entries) {
    _savePng(_resize(master, entry.value), '$base/${entry.key}');
  }
  print('  iOS icons complete.');
}

void generateMacOS(img.Image master) {
  print('Generating macOS icons...');
  final base = '$_root/macos/Runner/Assets.xcassets/AppIcon.appiconset';
  Directory(base).createSync(recursive: true);

  const sizes = {'app_icon_16': 16, 'app_icon_32': 32, 'app_icon_64': 64, 'app_icon_128': 128, 'app_icon_256': 256, 'app_icon_512': 512, 'app_icon_1024': 1024};
  for (final entry in sizes.entries) {
    _savePng(_resize(master, entry.value), '$base/${entry.key}.png');
  }
  print('  macOS icons complete.');
}

void generateWindows(img.Image master) {
  print('Generating Windows icons...');
  final base = '$_root/windows/runner/resources';
  Directory(base).createSync(recursive: true);

  const sizes = [16, 24, 32, 48, 64, 128, 256];
  final images = sizes.map((s) => _resize(master, s)).toList();
  _saveBytes(_encodeIco(images, sizes), '$base/app_icon.ico');
  _savePng(_resize(master, 256), '$base/app_icon.png');

  final favIco = _encodeIco(images, sizes);
  _saveBytes(favIco, '$_root/assets/icons/favicon.ico');
  _saveBytes(favIco, '$_root/web/favicon.ico');
  print('  Windows icons complete.');
}

List<int> _encodeIco(List<img.Image> images, List<int> sizes) {
  final bytes = <int>[];
  bytes.addAll([0, 0]); // reserved
  bytes.addAll(_u16le(1)); // ICO type
  bytes.addAll(_u16le(images.length)); // image count

  final dataStart = 6 + images.length * 16;
  int dataOffset = dataStart;

  final encodedImages = <List<int>>[];
  for (var i = 0; i < images.length; i++) {
    final png = img.encodePng(images[i]);
    encodedImages.add(png);
    final s = sizes[i];
    bytes.add(s > 255 ? 0 : s);
    bytes.add(s > 255 ? 0 : s);
    bytes.add(0);
    bytes.add(0);
    bytes.addAll(_u16le(1));
    bytes.addAll(_u16le(32));
    bytes.addAll(_u32le(png.length));
    bytes.addAll(_u32le(dataOffset));
    dataOffset += png.length;
  }
  for (final png in encodedImages) {
    bytes.addAll(png);
  }
  return bytes;
}

List<int> _u16le(int value) => [value & 0xFF, (value >> 8) & 0xFF];

List<int> _u32le(int value) => [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];