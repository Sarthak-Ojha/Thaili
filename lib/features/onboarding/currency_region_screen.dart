import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';

class CurrencyRegionScreen extends StatefulWidget {
  const CurrencyRegionScreen({super.key});

  @override
  State<CurrencyRegionScreen> createState() => _CurrencyRegionScreenState();
}

class _CurrencyRegionScreenState extends State<CurrencyRegionScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: AppStateModel().userName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    AppStateModel().completeOnboarding();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
      (route) => false,
    );
  }

  void _onGetStarted() {
    final enteredName = _nameController.text.trim();
    if (enteredName.isNotEmpty) {
      AppStateModel().setUserName(enteredName);
    }
    _navigateToHome();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateModel();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
    final subTextColor =
        isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight;
    final unselectedCardBg =
        isDark ? AppTheme.cardColor : AppTheme.surfaceLight;
    final unselectedBorderColor =
        isDark ? const Color(0xFF243348) : const Color(0xFFE2E8F0);

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final lang = appState.language;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Headline
                  Text(
                    lang == AppLanguage.nepali ? 'तपाईंको प्रोफाइल र सेटअप' : 'Welcome to Thaili',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lang == AppLanguage.nepali ? 'तपाईंको नाम र प्राथमिकता छान्नुहोस्' : 'Personalize your financial workspace',
                    style: TextStyle(
                      fontSize: 14,
                      color: subTextColor,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 👤 User Introduction Field (Name)
                  _buildSectionLabel(lang == AppLanguage.nepali ? 'तपाईंको नाम' : 'Your Name', textColor),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: unselectedCardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: unselectedBorderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        icon: const Icon(Icons.person_rounded, color: AppTheme.primaryLight, size: 22),
                        hintText: lang == AppLanguage.nepali ? 'नाम लेख्नुहोस्' : 'Enter your name',
                        hintStyle: TextStyle(
                          fontSize: 15,
                          color: subTextColor.withValues(alpha: 0.7),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section Title: Primary Currency
                  _buildSectionLabel(AppStrings.primaryCurrencySection(lang), textColor),
                  const SizedBox(height: 12),

                  // Currency Selection Cards (NPR, USD, INR)
                  ...AppStateModel.supportedCurrencies.map((curr) {
                    final isSelected = appState.currency == curr.currency;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: _buildCurrencyTile(
                        currency: curr,
                        lang: lang,
                        isSelected: isSelected,
                        cardBg: unselectedCardBg,
                        borderColor: unselectedBorderColor,
                        textColor: textColor,
                        onTap: () => appState.setCurrency(curr.currency),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // Section Title: Language / भाषा
                  _buildSectionLabel(AppStrings.languageSection(lang), textColor),
                  const SizedBox(height: 12),

                  // Language Options: English & Nepali
                  Row(
                    children: [
                      Expanded(
                        child: _buildLanguageOption(
                          label: AppStrings.englishLabel(lang),
                          subLabel: AppStrings.englishSubLabel(lang),
                          isSelected: appState.language == AppLanguage.english,
                          onTap: () => appState.setLanguage(AppLanguage.english),
                          cardBg: unselectedCardBg,
                          borderColor: unselectedBorderColor,
                          textColor: textColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildLanguageOption(
                          label: AppStrings.nepaliLabel(lang),
                          subLabel: AppStrings.nepaliSubLabel(lang),
                          isSelected: appState.language == AppLanguage.nepali,
                          onTap: () => appState.setLanguage(AppLanguage.nepali),
                          cardBg: unselectedCardBg,
                          borderColor: unselectedBorderColor,
                          textColor: textColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Direct One-Click Finish -> Launch My Thaili Home Dashboard
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _onGetStarted,
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
                        lang == AppLanguage.nepali ? 'सुरु गर्नुहोस्' : 'Get Started',
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
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String label, Color color) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: color.withValues(alpha: 0.70),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildCurrencyTile({
    required CurrencyData currency,
    required AppLanguage lang,
    required bool isSelected,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryLight.withValues(alpha: 0.08)
                : cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.primaryLight : borderColor,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryLight.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryLight.withValues(alpha: 0.18)
                      : AppTheme.accentGold.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    currency.symbol,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? AppTheme.primaryLight : AppTheme.goldDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currency.getName(lang),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currency.getSubtext(lang),
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String label,
    required String subLabel,
    required bool isSelected,
    required VoidCallback onTap,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryLight.withValues(alpha: 0.08)
                : cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppTheme.primaryLight : borderColor,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryLight.withValues(alpha: 0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppTheme.primaryLight : textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: textColor.withValues(alpha: 0.50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
