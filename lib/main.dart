// Thaili — Personal Finance App
// Developed by Sarthak Ojha
// © 2026 Sarthak Ojha. All rights reserved.

import 'package:flutter/material.dart';

import 'core/database/app_database.dart';
import 'core/database/database_security.dart';
import 'core/services/backup_manager.dart';
import 'core/services/error_handler.dart';
import 'core/state/app_state.dart';
import 'core/storage/cache_eviction_manager.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorHandler.setupGlobalErrorHandling();

  // ── Offline-First Database Initialization ──────────────────────────────
  // 1. Generate (or retrieve) the hardware-backed Keystore master key.
  await DatabaseSecurity.getOrCreateMasterKey();

  // 2. Open the SQLite database and apply any pending schema migrations.
  await AppDatabase.instance.database;

  // 3. Initialize app state: runs legacy migration then loads from SQLite.
  await AppStateModel().init();

  // 4. Prune stale export files (TTL 48h / 30 MB quota) at startup.
  CacheEvictionManager.prune();

  // 5. Start the periodic 24-hour auto-backup timer.
  BackupManager.startAutoBackup(AppStateModel());

  runApp(const ThailiApp());
}

class ThailiApp extends StatelessWidget {
  const ThailiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStateModel(),
      builder: (context, _) {
        final appState = AppStateModel();
        return MaterialApp(
          title: 'Thaili',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme, // Light mode (default)
          darkTheme: AppTheme.darkTheme, // Dark mode (system-triggered)
          themeMode: appState.themeMode,
          builder: (context, child) {
            if (child == null) return const SizedBox.shrink();
            final width = MediaQuery.sizeOf(context).width;

            // When window is compact (mobile/default desktop companion), render full width
            if (width <= 520) {
              return child;
            }

            // When user expands or maximizes the window, center the app with max-width 480
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              color: isDark ? const Color(0xFF070C13) : const Color(0xFFE8E3DA),
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.45 : 0.08,
                        ),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRect(child: child),
                ),
              ),
            );
          },
          home: SplashScreen(isReturningUser: appState.isOnboarded),
        );
      },
    );
  }
}
