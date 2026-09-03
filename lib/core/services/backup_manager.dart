import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../state/app_state.dart';

/// Periodic and on-demand local data backup manager.
class BackupManager {
  static Timer? _backupTimer;

  /// Start periodic auto-backup (every 24 hours).
  static void startAutoBackup(AppStateModel appState) {
    _backupTimer?.cancel();
    _backupTimer = Timer.periodic(const Duration(hours: 24), (_) {
      performBackup(appState);
    });
  }

  /// Perform a JSON snapshot backup of application data.
  static Future<String?> performBackup(AppStateModel appState) async {
    try {
      final backupData = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'balance': appState.initialBalance,
        'transactions': appState.transactions.map((t) => t.toJson()).toList(),
        'budgets': appState.budgets.map((b) => b.toJson()).toList(),
        'goals': appState.goals.map((g) => g.toJson()).toList(),
        'recurring': appState.recurring.map((r) => r.toJson()).toList(),
      };

      final jsonString = jsonEncode(backupData);
      debugPrint('Backup completed successfully at ${DateTime.now()}');
      return jsonString;
    } catch (e, stack) {
      debugPrint('Error performing backup: $e\n$stack');
      return null;
    }
  }

  /// Stop the auto backup timer.
  static void dispose() {
    _backupTimer?.cancel();
    _backupTimer = null;
  }
}
