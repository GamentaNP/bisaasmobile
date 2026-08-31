/// AES-256-GCM local encryption for sensitive offline payloads.
///
/// Key lifecycle:
/// - A random 32-byte key is generated on first use and stored in
///   `flutter_secure_storage` (Keychain / Keystore) under `_kEncKey`.
/// - Subsequent calls read the persisted key — no key rotation within an
///   install.  If the key is lost (e.g. after backup restore without keychain),
///   `readKey` generates a new one; callers must handle cache invalidation.
///
/// Wire format: `<16-byte IV in base64>.<ciphertext in base64>`
/// This is an internal format — never send it over the network.
library;

import 'dart:convert';
import 'dart:math';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../logging/app_logger.dart';

abstract final class LocalEncryption {
  static const _kEncKey = 'local_enc_key_v1';
  static const _storage = FlutterSecureStorage();
  static const _separator = '.';

  // ---------------------------------------------------------------------------
  // Key management
  // ---------------------------------------------------------------------------

  /// Returns the persisted key, generating + persisting a new one if absent.
  static Future<enc.Key> readKey() async {
    if (kIsWeb) {
      // Web has no Keychain/Keystore — use a deterministic dev key.
      return enc.Key(Uint8List(32));
    }

    var raw = await _storage.read(key: _kEncKey);
    if (raw == null) {
      raw = randomKey();
      await _storage.write(key: _kEncKey, value: raw);
      AppLogger.i('LocalEncryption: new AES-256 key generated and persisted');
    }
    return enc.Key(base64.decode(raw));
  }

  // ---------------------------------------------------------------------------
  // Encrypt / decrypt (async — reads key from secure storage each call)
  // ---------------------------------------------------------------------------

  /// Encrypts [plain] with AES-256-GCM.
  /// Returns a `<iv>.<ciphertext>` string, both base64.
  static Future<String> encryptAsync(String plain) async {
    final key = await readKey();
    return _encryptWithKey(plain, key);
  }

  /// Decrypts a string produced by [encryptAsync] or [encrypt].
  /// Returns null if the format is invalid or decryption fails.
  static Future<String?> decryptAsync(String cipher) async {
    final key = await readKey();
    return _decryptWithKey(cipher, key);
  }

  // ---------------------------------------------------------------------------
  // Synchronous convenience overloads (callers supply the key explicitly —
  // useful in Drift DAOs that already hold the key from an earlier await).
  // ---------------------------------------------------------------------------

  /// Encrypts [plain] synchronously using the supplied [key].
  static String encrypt(String plain, enc.Key key) =>
      _encryptWithKey(plain, key);

  /// Decrypts synchronously using the supplied [key].  Returns null on error.
  static String? decrypt(String cipher, enc.Key key) =>
      _decryptWithKey(cipher, key);

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  static String _encryptWithKey(String plain, enc.Key key) {
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encrypt(plain, iv: iv);
    return '${iv.base64}$_separator${encrypted.base64}';
  }

  static String? _decryptWithKey(String cipher, enc.Key key) {
    try {
      final parts = cipher.split(_separator);
      if (parts.length < 2) return null;
      final iv = enc.IV.fromBase64(parts[0]);
      // Rejoin in case the ciphertext itself contained a dot (shouldn't, but
      // base64 doesn't use dots, so this is defensive).
      final payload = parts.sublist(1).join(_separator);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
      return encrypter.decrypt64(payload, iv: iv);
    } on Object catch (e) {
      AppLogger.w('LocalEncryption.decrypt failed: $e');
      return null;
    }
  }

  /// Generates a cryptographically random 32-byte key, base64-encoded.
  static String randomKey([int bytes = 32]) {
    final r = Random.secure();
    final b = Uint8List(bytes);
    for (var i = 0; i < bytes; i++) {
      b[i] = r.nextInt(256);
    }
    return base64.encode(b);
  }
}
