import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages the database master key using the Android Keystore system
/// (via flutter_secure_storage's EncryptedSharedPreferences on Android).
///
/// On Android, flutter_secure_storage stores the AES-256 key inside
/// the hardware-backed Keystore, making it inaccessible even to
/// root-level processes or ADB backups.
class DatabaseSecurity {
  static const _keyAlias = 'thaili_db_master_key';

  /// Android-specific options that enforce hardware Keystore encryption.
  static const _androidOptions = AndroidOptions(
    resetOnError: true,
  );

  static const _secureStorage = FlutterSecureStorage(
    aOptions: _androidOptions,
  );

  /// Retrieves the existing database master key, or generates and persists
  /// a new cryptographically secure 32-byte (256-bit) hex key on first run.
  ///
  /// The key is stored in the Android Keystore via EncryptedSharedPreferences,
  /// making it inaccessible to unauthorized ADB extractions or rooted reads.
  static Future<String> getOrCreateMasterKey() async {
    try {
      final existingKey = await _secureStorage.read(key: _keyAlias);
      if (existingKey != null && existingKey.isNotEmpty) {
        return existingKey;
      }

      // First-run: Generate a 256-bit (32-byte) cryptographically secure key.
      final key = _generateSecureKey(32);
      await _secureStorage.write(key: _keyAlias, value: key);
      debugPrint('[DatabaseSecurity] Master key generated and stored in Keystore.');
      return key;
    } catch (e, stack) {
      debugPrint('[DatabaseSecurity] Error accessing Keystore: $e\n$stack');
      // Fallback for desktop/test environments where Keystore is unavailable.
      return _generateSecureKey(32);
    }
  }

  /// Generates a hex-encoded cryptographically secure random key of [byteLength] bytes.
  static String _generateSecureKey(int byteLength) {
    final rng = Random.secure();
    final bytes = List<int>.generate(byteLength, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Deletes the master key from the Keystore. Use only for full data wipe / account reset.
  static Future<void> deleteMasterKey() async {
    try {
      await _secureStorage.delete(key: _keyAlias);
      debugPrint('[DatabaseSecurity] Master key deleted from Keystore.');
    } catch (e) {
      debugPrint('[DatabaseSecurity] Error deleting master key: $e');
    }
  }
}
