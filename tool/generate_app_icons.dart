// ignore_for_file: avoid_print, avoid_single_cascade_in_expression_statements, unnecessary_string_interpolations, prefer_const_declarations
import 'dart:io';
import 'package:image/image.dart' as img;

String get _root => '${Directory.current.path}';

void main() {
  print('Loading master icon from assets/images/jims_icon_master.jpg...');
  final iconFile = File('$_root/assets/images/jims_icon_master.jpg');
  if (!iconFile.existsSync()) {
    print('ERROR: assets/images/jims_icon_master.jpg not found!');
    exit(1);
  }

  final master = img.decodeImage(iconFile.readAsBytesSync());
  if (master == null) {
    print('ERROR: Failed to decode master icon image.');
    exit(1);
  }

  // Also convert master logo to PNG for in-app display
  final logoFile = File('$_root/assets/images/jims_logo_master.jpg');
  if (logoFile.existsSync()) {
    final masterLogo = img.decodeImage(logoFile.readAsBytesSync());
    if (masterLogo != null) {
      File('$_root/assets/images/logo.png')
        ..writeAsBytesSync(img.encodePng(masterLogo, level: 6));
      print('Saved assets/images/logo.png');
    }
  }

  // Save 512px icon for in-app header/cards
  final inAppIcon = img.copyResize(master, width: 512, height: 512, interpolation: img.Interpolation.linear);
  File('$_root/assets/images/logo_icon.png')..writeAsBytesSync(img.encodePng(inAppIcon, level: 6));
  File('$_root/assets/icons/app_icon.png')..writeAsBytesSync(img.encodePng(inAppIcon, level: 6));

  _generateAndroid(master);
  _generateIOS(master);
  _generateMacOS(master);
  _generateWeb(master);
  _generateWindows(master);

  print('All platform icons generated successfully!');
}

void _generateAndroid(img.Image master) {
  print('Generating Android icons...');
  final base = '$_root/android/app/src/main/res';

  final mipmaps = {
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

    final resized = img.copyResize(master, width: size, height: size, interpolation: img.Interpolation.linear);
    File('$folder/ic_launcher.png').writeAsBytesSync(img.encodePng(resized, level: 6));

    // Round launcher icon
    final round = _makeCircular(resized);
    File('$folder/ic_launcher_round.png').writeAsBytesSync(img.encodePng(round, level: 6));
  }

  // Foreground adaptive icon (108dp / 432px at xxxhdpi)
  final fgSize = 432;
  final fgIcon = img.Image(width: fgSize, height: fgSize, numChannels: 4);
  final inner = img.copyResize(master, width: 280, height: 280, interpolation: img.Interpolation.linear);
  img.compositeImage(fgIcon, inner, dstX: (fgSize - 280) ~/ 2, dstY: (fgSize - 280) ~/ 2);
  final anyDpi = '$base/mipmap-anydpi-v26';
  Directory(anyDpi).createSync(recursive: true);
  File('$base/mipmap-xxxhdpi/ic_launcher_foreground.png').writeAsBytesSync(img.encodePng(fgIcon, level: 6));
  print('  Android icons complete.');
}

img.Image _makeCircular(img.Image src) {
  final out = img.Image(width: src.width, height: src.height, numChannels: 4);
  final r = src.width / 2.0;
  final cx = r;
  final cy = r;

  for (int y = 0; y < src.height; y++) {
    for (int x = 0; x < src.width; x++) {
      final dx = (x + 0.5) - cx;
      final dy = (y + 0.5) - cy;
      final dist = (dx * dx + dy * dy);
      if (dist <= r * r) {
        final p = src.getPixel(x, y);
        out.setPixel(x, y, p);
      }
    }
  }
  return out;
}

void _generateIOS(img.Image master) {
  print('Generating iOS icons...');
  final base = '$_root/ios/Runner/Assets.xcassets/AppIcon.appiconset';
  Directory(base).createSync(recursive: true);

  final iosSizes = {
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
    final resized = img.copyResize(master, width: entry.value, height: entry.value, interpolation: img.Interpolation.linear);
    File('$base/${entry.key}').writeAsBytesSync(img.encodePng(resized, level: 6));
  }
  print('  iOS icons complete.');
}

void _generateMacOS(img.Image master) {
  print('Generating macOS icons...');
  final base = '$_root/macos/Runner/Assets.xcassets/AppIcon.appiconset';
  Directory(base).createSync(recursive: true);

  final macSizes = {
    'app_icon_16.png': 16,
    'app_icon_32.png': 32,
    'app_icon_64.png': 64,
    'app_icon_128.png': 128,
    'app_icon_256.png': 256,
    'app_icon_512.png': 512,
    'app_icon_1024.png': 1024,
  };

  for (final entry in macSizes.entries) {
    final resized = img.copyResize(master, width: entry.value, height: entry.value, interpolation: img.Interpolation.linear);
    File('$base/${entry.key}').writeAsBytesSync(img.encodePng(resized, level: 6));
  }
  print('  macOS icons complete.');
}

void _generateWeb(img.Image master) {
  print('Generating Web icons & favicon...');
  final base = '$_root/web';
  Directory('$base/icons').createSync(recursive: true);

  final fav32 = img.copyResize(master, width: 32, height: 32, interpolation: img.Interpolation.linear);
  File('$base/favicon.png').writeAsBytesSync(img.encodePng(fav32, level: 6));
  File('$_root/assets/icons/favicon-32x32.png').writeAsBytesSync(img.encodePng(fav32, level: 6));

  final icon192 = img.copyResize(master, width: 192, height: 192, interpolation: img.Interpolation.linear);
  final icon512 = img.copyResize(master, width: 512, height: 512, interpolation: img.Interpolation.linear);

  File('$base/icons/Icon-192.png').writeAsBytesSync(img.encodePng(icon192, level: 6));
  File('$base/icons/Icon-512.png').writeAsBytesSync(img.encodePng(icon512, level: 6));
  File('$base/icons/Icon-maskable-192.png').writeAsBytesSync(img.encodePng(icon192, level: 6));
  File('$base/icons/Icon-maskable-512.png').writeAsBytesSync(img.encodePng(icon512, level: 6));
  print('  Web icons complete.');
}

void _generateWindows(img.Image master) {
  print('Generating Windows icons...');
  final base = '$_root/windows/runner/resources';
  Directory(base).createSync(recursive: true);

  final iconSizes = [16, 24, 32, 48, 64, 128, 256];
  final images = <img.Image>[];
  for (final s in iconSizes) {
    images.add(img.copyResize(master, width: s, height: s, interpolation: img.Interpolation.linear));
  }

  final icoData = _encodeIco(images, iconSizes);
  File('$base/app_icon.ico').writeAsBytesSync(icoData);
  File('$_root/assets/icons/favicon.ico').writeAsBytesSync(icoData);

  final png256 = img.copyResize(master, width: 256, height: 256, interpolation: img.Interpolation.linear);
  File('$base/app_icon.png').writeAsBytesSync(img.encodePng(png256, level: 6));
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
  for (int i = 0; i < images.length; i++) {
    final png = img.encodePng(images[i], level: 0);
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
