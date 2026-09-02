import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../splash/widgets/animated_money_pouch.dart';
import 'monthly_income_screen.dart';

class InitialBalanceScreen extends StatefulWidget {
  const InitialBalanceScreen({super.key});

  @override
  State<InitialBalanceScreen> createState() => _InitialBalanceScreenState();
}

class _InitialBalanceScreenState extends State<InitialBalanceScreen> {
  final AppStateModel _appState = AppStateModel();
  
  // Clean integer string state ('0' is the clean resting state)
  String _digits = '0';
  static const int _maxDigits = 9; // Cap at 9 digits (999,999,999) to prevent overflow

  double get _currentAmount {
    return double.tryParse(_digits) ?? 0.0;
  }

  String get _formattedDisplay {
    final numVal = int.tryParse(_digits);
    if (numVal == null || numVal == 0) return '0';
    return _formatWithCommas(_digits);
  }

  String _formatWithCommas(String digits) {
    if (digits.length <= 3) return digits;
    final isUsd = _appState.currency == AppCurrency.usd;

    if (isUsd) {
      final regExp = RegExp(r'\B(?=(\d{3})+(?!\d))');
      return digits.replaceAll(regExp, ',');
    } else {
      // South Asian (Nepali/Indian) numbering system: e.g. 1,50,000
      final len = digits.length;
      final lastThree = digits.substring(len - 3);
      String remaining = digits.substring(0, len - 3);

      if (remaining.isNotEmpty) {
        final regExp = RegExp(r'\B(?=(\d{2})+(?!\d))');
        remaining = remaining.replaceAll(regExp, ',');
        return '$remaining,$lastThree';
      } else {
        return lastThree;
      }
    }
  }

  // 🧠 Robust Custom Keypad Logic handling all edge cases & constraints
  void _onKeyPress(String key) {
    setState(() {
      if (key == '←') {
        // Clean Erasure State:
        // If single digit (or already '0'), reset back to integer '0'
        if (_digits.length <= 1 || _digits == '0') {
          _digits = '0';
        } else {
          _digits = _digits.substring(0, _digits.length - 1);
        }
      } else if (key == '0' || key == '00') {
        // Prevent Double Zero Bug:
        // If current value is '0', pressing 0 or 00 does absolutely nothing
        if (_digits == '0') {
          return;
        }
        
        // Character Limit Constraints:
        if (key == '00') {
          if (_digits.length + 2 <= _maxDigits) {
            _digits += '00';
          }
        } else {
          if (_digits.length + 1 <= _maxDigits) {
            _digits += '0';
          }
        }
      } else {
        // Non-zero digits (1-9)
        if (_digits == '0') {
          _digits = key;
        } else if (_digits.length < _maxDigits) {
          _digits += key;
        }
      }
    });
  }

  // Dynamic Typography scaling based on formatted text length
  double _calculateDynamicFontSize(String text) {
    if (text.length <= 5) return 42.0;       // e.g. 1,000
    if (text.length <= 7) return 36.0;       // e.g. 1,50,000
    if (text.length <= 9) return 30.0;       // e.g. 15,00,000
    return 26.0;                             // e.g. 99,99,99,999
  }

  void _onContinue() {
    _appState.setInitialBalance(_currentAmount);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MonthlyIncomeScreen(),
      ),
    );
  }

  void _onSkip() {
    _appState.setInitialBalance(0.0);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MonthlyIncomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
    final subTextColor =
        isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight;
    final cardBg = isDark ? AppTheme.cardColor : AppTheme.surfaceLight;
    final borderColor =
        isDark ? const Color(0xFF243348) : const Color(0xFFE2E8F0);

    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        final lang = _appState.language;
        final curr = _appState.currentCurrencyData;
        final displayString = _formattedDisplay;
        final dynamicFontSize = _calculateDynamicFontSize(displayString);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: textColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
            // Premium progress bar at 100% (Step 2 of 2)
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: Stack(
                children: [
                  Container(
                    height: 4,
                    width: double.infinity,
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                  ),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 1.0, // Step 2 of 2 -> 100%
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 14),

                        // Icon / Pouch visual
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const ThailiPouchIcon(size: 36),
                        ),

                        const SizedBox(height: 14),

                        // Headline & description
                        Text(
                          AppStrings.whatsInYourThaili(lang),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppStrings.startWithBalance(lang),
                          style: TextStyle(
                            fontSize: 15,
                            color: subTextColor,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Amount Display Box with auto-scaling typography
                        Container(
                          width: double.infinity,
                          height: 94,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _digits != '0'
                                  ? AppTheme.primaryLight.withValues(alpha: 0.6)
                                  : borderColor,
                              width: _digits != '0' ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '${curr.symbol} ',
                                style: TextStyle(
                                  fontSize: dynamicFontSize * 0.68,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.accentGold,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  displayString,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: dynamicFontSize,
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // ── Perfectly Symmetrical Keypad & Balanced Bottom Actions ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Symmetrical Keypad Grid with unified 12.0 horizontal & vertical gaps
                      _buildKeypadRow(['1', '2', '3'], textColor, cardBg, borderColor),
                      const SizedBox(height: 12),
                      _buildKeypadRow(['4', '5', '6'], textColor, cardBg, borderColor),
                      const SizedBox(height: 12),
                      _buildKeypadRow(['7', '8', '9'], textColor, cardBg, borderColor),
                      const SizedBox(height: 12),
                      _buildKeypadRow(['00', '0', '←'], textColor, cardBg, borderColor),

                      // Generous breathing room between Keypad & Continue button
                      const SizedBox(height: 24),

                      // Primary CTA Continue Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryLight,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            shadowColor:
                                AppTheme.primaryLight.withValues(alpha: 0.3),
                          ),
                          child: Text(
                            AppStrings.continueButton(lang),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                      // Balanced spacing between Continue button & Secondary action
                      const SizedBox(height: 14),

                      // Secondary Link Option: "I'll add this later"
                      TextButton(
                        onPressed: _onSkip,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(120, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(
                          AppStrings.addLater(lang),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: subTextColor,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKeypadRow(
      List<String> keys, Color textColor, Color cardBg, Color borderColor) {
    return Row(
      children: keys.map((key) {
        final isBackspace = key == '←';
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0), // 12.0 total horizontal gap
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onKeyPress(key),
                // Uniform 16px corner radius for ALL keys including backspace
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: isBackspace
                        ? AppTheme.accentGold.withValues(alpha: 0.10)
                        : cardBg,
                    // Completely unified curvature
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isBackspace
                          ? AppTheme.accentGold.withValues(alpha: 0.35)
                          : borderColor.withValues(alpha: 0.7),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      )
                    ],
                  ),
                  child: Center(
                    child: isBackspace
                        ? const Icon(
                            Icons.backspace_outlined,
                            size: 22,
                            color: AppTheme.accentGold,
                          )
                        : Text(
                            key,
                            style: TextStyle(
                              fontSize: key == '00' ? 18 : 22,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
