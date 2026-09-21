import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

/// Key-value repository for lightweight app settings that are not sensitive
/// enough to require Keystore storage (e.g. theme mode, language, currency).
///
/// Sensitive data (master DB key) lives in [DatabaseSecurity] via Keystore.
/// Scalar settings (theme, locale) still use SharedPreferences for speed.
/// This repository handles any structured settings we want to query relationally.
class SettingsRepository {
  final AppDatabase _appDb;

  SettingsRepository({AppDatabase? appDb})
      : _appDb = appDb ?? AppDatabase.instance;

  // ── Read ────────────────────────────────────────────────────────────────

  Future<String?> get(String key) async {
    try {
      final db = await _appDb.database;
      final rows = await db.query(
        'app_metadata',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      return rows.isEmpty ? null : rows.first['value'] as String?;
    } catch (e) {
      debugPrint('[SettingsRepository.get] Error for key=$key: $e');
      return null;
    }
  }

  Future<Map<String, String>> getAll() async {
    try {
      final db = await _appDb.database;
      final rows = await db.query('app_metadata');
      return {
        for (final row in rows) row['key'] as String: row['value'] as String,
      };
    } catch (e) {
      debugPrint('[SettingsRepository.getAll] Error: $e');
      return {};
    }
  }

  // ── Write ───────────────────────────────────────────────────────────────

  Future<void> set(String key, String value) async {
    try {
      final db = await _appDb.database;
      await db.insert(
        'app_metadata',
        {
          'key': key,
          'value': value,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('[SettingsRepository.set] Error for key=$key: $e');
    }
  }

  Future<void> delete(String key) async {
    try {
      final db = await _appDb.database;
      await db.delete('app_metadata', where: 'key = ?', whereArgs: [key]);
    } catch (e) {
      debugPrint('[SettingsRepository.delete] Error for key=$key: $e');
    }
  }
}
