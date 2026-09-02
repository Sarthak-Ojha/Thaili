import 'package:flutter/material.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';

class ReadyCompletionScreen extends StatelessWidget {
  const ReadyCompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateModel();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
    final subTextColor =
        isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight;

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final lang = appState.language;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 20),

                  // Center Celebration Card
                  Column(
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryLight.withValues(alpha: 0.12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryLight.withValues(alpha: 0.20),
                              blurRadius: 30,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '🎉',
                            style: TextStyle(fontSize: 64),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      Text(
                        lang == AppLanguage.nepali
                            ? 'तपाईं तयार हुनुहुन्छ! 🎉'
                            : "You're ready. 🎉",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      Text(
                        lang == AppLanguage.nepali
                            ? 'तपाईंको थैली सेटअप सम्पन्न भयो। अब आफ्नो खर्च, आम्दानी र बचतलाई सहज रूपमा ट्र्याक गर्नुहोस्।'
                            : 'Your Thaili is configured. Take total control of your money, smart spending, and savings goals.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: subTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),

                  // Open My Thaili Action Button
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            AppStateModel().completeOnboarding();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryLight,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 3,
                            shadowColor: AppTheme.primaryLight.withValues(alpha: 0.35),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                lang == AppLanguage.nepali
                                    ? 'मेरो थैली खोल्नुहोस्'
                                    : 'Open My Thaili',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
