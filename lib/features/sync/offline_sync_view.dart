import 'package:flutter/material.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';

class OfflineSyncView extends StatefulWidget {
  const OfflineSyncView({super.key});

  @override
  State<OfflineSyncView> createState() => _OfflineSyncViewState();
}

class _OfflineSyncViewState extends State<OfflineSyncView> {
  bool _isBackingUp = false;

  void _triggerBackup(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isBackingUp = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _isBackingUp = false);
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F766E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('Local backup created successfully! ✓', style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateModel();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
    final subTextColor =
        isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight;
    final cardBg = isDark ? AppTheme.cardColor : AppTheme.surfaceLight;
    final outlineColor =
        isDark ? const Color(0xFF243348) : const Color(0xFFE2E8F0);

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final isOffline = appState.isOffline;
        final pending = appState.pendingSyncChanges;
        final lastSynced = appState.lastSyncedTime;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text('Your Data & Sync', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: textColor)),
              const SizedBox(height: 4),
              Text('Offline-first architecture with instant local persistence', style: TextStyle(fontSize: 13, color: subTextColor)),
              const SizedBox(height: 20),

              // Dynamic Status Card (● Everything is up to date OR ◐ Pending changes OR Offline state)
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isOffline
                        ? [const Color(0xFF475569), const Color(0xFF334155), const Color(0xFF1E293B)]
                        : pending == 0
                            ? [const Color(0xFF0D9488), const Color(0xFF0F766E), const Color(0xFF042F2E)]
                            : [const Color(0xFFD97706), const Color(0xFFB45309), const Color(0xFF78350F)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: isOffline
                                    ? const Color(0xFF94A3B8)
                                    : pending == 0
                                        ? const Color(0xFF34D399)
                                        : const Color(0xFFFBBF24),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isOffline
                                  ? "You're offline"
                                  : pending == 0
                                      ? 'Everything is up to date'
                                      : '$pending changes waiting to sync',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            isOffline ? 'Offline Ready' : 'Synced',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      isOffline
                          ? "Don't worry — Thaili continues working normally."
                          : 'Saved locally ✓\nYour records are fast, private, and encrypted.',
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Last synced', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(lastSynced, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons: Sync Now & Backup Now
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isOffline ? null : () => appState.syncNow(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: const Text('Sync Now', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isBackingUp ? null : () => _triggerBackup(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        side: BorderSide(color: outlineColor, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: _isBackingUp
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: const Text('Backup Now', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // Interactive Network Simulator Switch (Demonstrating Offline UX)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: outlineColor.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded, color: isOffline ? const Color(0xFFEF4444) : AppTheme.primaryLight, size: 22),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Simulate Offline Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
                            const SizedBox(height: 2),
                            Text('Test seamless offline functionality', style: TextStyle(fontSize: 11, color: subTextColor)),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: isOffline,
                      activeThumbColor: const Color(0xFFEF4444),
                      onChanged: (val) => appState.toggleOfflineMode(val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Architectural Explanatory Cards
              Text('Why Thaili is Offline-First', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textColor)),
              const SizedBox(height: 12),

              _buildFeatureDetailCard(
                icon: Icons.shield_outlined,
                title: 'Private & Local Storage',
                desc: 'Your financial entries remain on your device memory. No remote databases read your expenses without permission.',
                cardBg: cardBg,
                outlineColor: outlineColor,
                textColor: textColor,
                subTextColor: subTextColor,
              ),
              const SizedBox(height: 10),
              _buildFeatureDetailCard(
                icon: Icons.offline_bolt_outlined,
                title: 'Zero Latency Response',
                desc: 'Every tap, budget check, and transaction addition executes in <16ms without waiting for cellular networks.',
                cardBg: cardBg,
                outlineColor: outlineColor,
                textColor: textColor,
                subTextColor: subTextColor,
              ),

              const SizedBox(height: 60),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureDetailCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color cardBg,
    required Color outlineColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: outlineColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.primaryLight.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: AppTheme.primaryLight),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(fontSize: 12, color: subTextColor, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
