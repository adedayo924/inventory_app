import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PasswordHasher {
  PasswordHasher._();

  static const int _iterations = 10000;
  static final Random _random = Random.secure();

  static String hash(String password) {
    final salt = List<int>.generate(16, (_) => _random.nextInt(256));
    final digest = _pbkdf2(utf8.encode(password), salt, _iterations, 32);
    return '${base64Url.encode(salt)}.${base64Url.encode(digest)}';
  }

  static bool isPlaintext(String stored) => !stored.contains('.');

  static bool verify(String password, String stored) {
    if (stored.isEmpty) return false;
    if (isPlaintext(stored)) return password == stored;

    try {
      final parts = stored.split('.');
      final salt = base64Url.decode(parts[0]);
      final expected = base64Url.decode(parts[1]);
      final actual = _pbkdf2(utf8.encode(password), salt, _iterations, 32);
      if (actual.length != expected.length) return false;
      var diff = 0;
      for (var i = 0; i < actual.length; i++) {
        diff |= actual[i] ^ expected[i];
      }
      return diff == 0;
    } catch (_) {
      return false;
    }
  }

  static List<int> _pbkdf2(List<int> password, List<int> salt, int iterations, int dkLen) {
    final hLen = sha256.convert(const []).bytes.length;
    final blockCount = (dkLen / hLen).ceil();
    final dk = <int>[];
    for (var blockIndex = 1; blockIndex <= blockCount; blockIndex++) {
      final blockInts = [
        (blockIndex >> 24) & 0xff,
        (blockIndex >> 16) & 0xff,
        (blockIndex >> 8) & 0xff,
        blockIndex & 0xff,
      ];
      var u = _hmacSha256(password, [...salt, ...blockInts]);
      final t = List<int>.from(u);
      for (var i = 1; i < iterations; i++) {
        u = _hmacSha256(password, u);
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      dk.addAll(t);
    }
    return dk.sublist(0, dkLen);
  }

  static List<int> _hmacSha256(List<int> key, List<int> data) {
    const blockSize = 64;
    var k = key.length > blockSize ? sha256.convert(key).bytes : List<int>.from(key);
    k = List<int>.from(k);
    while (k.length < blockSize) {
      k.add(0);
    }
    final ipad = List<int>.generate(blockSize, (i) => k[i] ^ 0x36);
    final opad = List<int>.generate(blockSize, (i) => k[i] ^ 0x5c);
    return sha256.convert([...opad, ...sha256.convert([...ipad, ...data]).bytes]).bytes;
  }
}
