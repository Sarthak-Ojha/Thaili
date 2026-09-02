import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import 'financial_goal_screen.dart';

class MonthlyIncomeScreen extends StatefulWidget {
  const MonthlyIncomeScreen({super.key});

  @override
  State<MonthlyIncomeScreen> createState() => _MonthlyIncomeScreenState();
}

class _MonthlyIncomeScreenState extends State<MonthlyIncomeScreen> {
  final AppStateModel _appState = AppStateModel();

  // Default: 50,000
  String _digits = '50000';
  IncomeFrequency _selectedFrequency = IncomeFrequency.monthly;
  static const int _maxDigits = 9;

  double get _currentAmount => double.tryParse(_digits) ?? 0.0;

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

  void _onKeyPress(String key) {
    setState(() {
      if (key == '←') {
        if (_digits.length <= 1 || _digits == '0') {
          _digits = '0';
        } else {
          _digits = _digits.substring(0, _digits.length - 1);
        }
      } else if (key == '0' || key == '00') {
        if (_digits == '0') return;
        if (key == '00') {
          if (_digits.length + 2 <= _maxDigits) _digits += '00';
        } else {
          if (_digits.length + 1 <= _maxDigits) _digits += '0';
        }
      } else {
        if (_digits == '0') {
          _digits = key;
        } else if (_digits.length < _maxDigits) {
          _digits += key;
        }
      }
    });
  }

  double _calculateDynamicFontSize(String text) {
    if (text.length <= 5) return 42.0;
    if (text.length <= 7) return 36.0;
    if (text.length <= 9) return 30.0;
    return 26.0;
  }

  void _onContinue() {
    _appState.setMonthlyIncome(_currentAmount, _selectedFrequency);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FinancialGoalScreen(),
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
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
            // Step 3 progress line (60%)
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: Stack(
                children: [
                  Container(
                    height: 4,
                    width: double.infinity,
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  ),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.66,
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

                        // Icon badge
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.trending_up_rounded,
                            color: AppTheme.primaryLight,
                            size: 28,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Headline & Description
                        Text(
                          lang == AppLanguage.nepali
                              ? 'तपाईं सामान्यतया कति प्राप्त गर्नुहुन्छ?'
                              : 'How much do you usually receive?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lang == AppLanguage.nepali
                              ? 'यसले थैलीलाई तपाईंको खर्च योजना बनाउन मद्दत गर्छ।'
                              : 'This helps Thaili understand your spending.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: subTextColor,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Income Display Box
                        Container(
                          width: double.infinity,
                          height: 88,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
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

                        const SizedBox(height: 18),

                        // Frequency selector chips: Monthly | Weekly | Irregular
                        Row(
                          children: [
                            _buildFrequencyChip(
                              label: lang == AppLanguage.nepali ? 'मासिक' : 'Monthly',
                              freq: IncomeFrequency.monthly,
                              cardBg: cardBg,
                              borderColor: borderColor,
                              textColor: textColor,
                            ),
                            const SizedBox(width: 8),
                            _buildFrequencyChip(
                              label: lang == AppLanguage.nepali ? 'साप्ताहिक' : 'Weekly',
                              freq: IncomeFrequency.weekly,
                              cardBg: cardBg,
                              borderColor: borderColor,
                              textColor: textColor,
                            ),
                            const SizedBox(width: 8),
                            _buildFrequencyChip(
                              label: lang == AppLanguage.nepali ? 'अनियमित' : 'Irregular',
                              freq: IncomeFrequency.irregular,
                              cardBg: cardBg,
                              borderColor: borderColor,
                              textColor: textColor,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // Keypad & Continue Action
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildKeypadRow(['1', '2', '3'], textColor, cardBg, borderColor),
                      const SizedBox(height: 10),
                      _buildKeypadRow(['4', '5', '6'], textColor, cardBg, borderColor),
                      const SizedBox(height: 10),
                      _buildKeypadRow(['7', '8', '9'], textColor, cardBg, borderColor),
                      const SizedBox(height: 10),
                      _buildKeypadRow(['00', '0', '←'], textColor, cardBg, borderColor),

                      const SizedBox(height: 20),

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
                            shadowColor: AppTheme.primaryLight.withValues(alpha: 0.3),
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

                      const SizedBox(height: 16),
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

  Widget _buildFrequencyChip({
    required String label,
    required IncomeFrequency freq,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
  }) {
    final isSelected = _selectedFrequency == freq;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedFrequency = freq),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryLight.withValues(alpha: 0.12)
                : cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryLight : borderColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.primaryLight : textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(
      List<String> keys, Color textColor, Color cardBg, Color borderColor) {
    return Row(
      children: keys.map((key) {
        final isBackspace = key == '←';
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onKeyPress(key),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isBackspace
                        ? AppTheme.accentGold.withValues(alpha: 0.10)
                        : cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isBackspace
                          ? AppTheme.accentGold.withValues(alpha: 0.35)
                          : borderColor.withValues(alpha: 0.7),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: isBackspace
                        ? const Icon(
                            Icons.backspace_outlined,
                            size: 20,
                            color: AppTheme.accentGold,
                          )
                        : Text(
                            key,
                            style: TextStyle(
                              fontSize: key == '00' ? 17 : 20,
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
