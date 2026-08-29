import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Minimal local encryption helper — for caching sensitive offline payloads.
/// Real prod should use `flutter_secure_storage` for keys; this is a placeholder
/// that can be swapped for `encrypt` package without changing call sites.
abstract final class LocalEncryption {
  static String encrypt(String plain, {String key = 'dev-key'}) {
    final bytes = utf8.encode(plain);
    final kb = utf8.encode(key);
    final out = Uint8List(bytes.length);
    for (var i = 0; i < bytes.length; i++) {
      out[i] = bytes[i] ^ kb[i % kb.length];
    }
    return base64Encode(out);
  }

  static String decrypt(String cipher, {String key = 'dev-key'}) {
    final bytes = base64Decode(cipher);
    final kb = utf8.encode(key);
    final out = Uint8List(bytes.length);
    for (var i = 0; i < bytes.length; i++) {
      out[i] = bytes[i] ^ kb[i % kb.length];
    }
    return utf8.decode(out);
  }

  static String randomKey([int len = 32]) {
    final r = Random.secure();
    final b = Uint8List(len);
    for (var i = 0; i < len; i++) {
      b[i] = r.nextInt(256);
    }
    return base64UrlEncode(b);
  }
}
