import 'package:flutter/material.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import 'ready_completion_screen.dart';

class GoalCardOption {
  final String id;
  final IconData icon;
  final String emoji;
  final String titleEn;
  final String titleNe;
  final double defaultTarget;

  const GoalCardOption({
    required this.id,
    required this.icon,
    required this.emoji,
    required this.titleEn,
    required this.titleNe,
    required this.defaultTarget,
  });

  String getTitle(AppLanguage lang) => lang == AppLanguage.nepali ? titleNe : titleEn;
}

class FinancialGoalScreen extends StatefulWidget {
  const FinancialGoalScreen({super.key});

  @override
  State<FinancialGoalScreen> createState() => _FinancialGoalScreenState();
}

class _FinancialGoalScreenState extends State<FinancialGoalScreen> {
  final AppStateModel _appState = AppStateModel();

  final List<GoalCardOption> _goalOptions = const [
    GoalCardOption(id: 'laptop', icon: Icons.laptop_mac_rounded, emoji: '💻', titleEn: 'Laptop', titleNe: 'ल्यापटप', defaultTarget: 150000),
    GoalCardOption(id: 'travel', icon: Icons.flight_takeoff_rounded, emoji: '✈️', titleEn: 'Travel', titleNe: 'यात्रा', defaultTarget: 80000),
    GoalCardOption(id: 'home', icon: Icons.home_rounded, emoji: '🏠', titleEn: 'Home', titleNe: 'घर', defaultTarget: 500000),
    GoalCardOption(id: 'education', icon: Icons.school_rounded, emoji: '🎓', titleEn: 'Education', titleNe: 'शिक्षा', defaultTarget: 200000),
    GoalCardOption(id: 'vehicle', icon: Icons.directions_car_rounded, emoji: '🚗', titleEn: 'Vehicle', titleNe: 'सवारी साधन', defaultTarget: 350000),
    GoalCardOption(id: 'emergency', icon: Icons.health_and_safety_rounded, emoji: '🛡️', titleEn: 'Emergency fund', titleNe: 'आपतकालीन कोष', defaultTarget: 100000),
    GoalCardOption(id: 'custom', icon: Icons.flag_rounded, emoji: '🎯', titleEn: 'Custom', titleNe: 'अन्य लक्ष्य', defaultTarget: 50000),
  ];

  late String _selectedGoalId;
  late TextEditingController _targetAmountController;

  @override
  void initState() {
    super.initState();
    _selectedGoalId = 'laptop';
    _targetAmountController = TextEditingController();
  }

  @override
  void dispose() {
    _targetAmountController.dispose();
    super.dispose();
  }

  void _onCreateGoal() {
    final selectedOpt = _goalOptions.firstWhere(
      (g) => g.id == _selectedGoalId,
      orElse: () => _goalOptions[0],
    );

    final cleanNum = double.tryParse(_targetAmountController.text.replaceAll(',', '')) ?? selectedOpt.defaultTarget;

    _appState.setGoal(
      FinancialGoal(
        id: selectedOpt.id,
        title: selectedOpt.getTitle(_appState.language),
        emoji: selectedOpt.emoji,
        targetAmount: cleanNum,
        currentAmount: (cleanNum * 0.48), // default realistic progress
      ),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ReadyCompletionScreen(),
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

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
            // Step 4 progress line (85%)
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
                    widthFactor: 0.85,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Headline
                  Text(
                    lang == AppLanguage.nepali
                        ? 'तपाईं केका लागि बचत गर्दै हुनुहुन्छ?'
                        : 'What are you saving for?',
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
                        ? 'आफ्नो पहिलो वित्तीय लक्ष्य निर्धारण गर्नुहोस्।'
                        : 'Set your first financial milestone with Thaili.',
                    style: TextStyle(
                      fontSize: 14,
                      color: subTextColor,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Goal Category Cards (Horizontal / Grid wrap)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _goalOptions.map((opt) {
                              final isSelected = _selectedGoalId == opt.id;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedGoalId = opt.id;
                                    _targetAmountController.text =
                                        opt.defaultTarget.toInt().toString().replaceAllMapped(
                                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                            (m) => '${m[1]},');
                                  });
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: (MediaQuery.of(context).size.width - 68) / 2,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primaryLight.withValues(alpha: 0.10)
                                        : cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? AppTheme.primaryLight : borderColor,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Text(opt.emoji, style: const TextStyle(fontSize: 22)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          opt.getTitle(lang),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                            color: isSelected ? AppTheme.primaryLight : textColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 24),

                          // Target Amount Input Card
                          Text(
                            lang == AppLanguage.nepali ? 'लक्ष्य रकम' : 'Target Amount',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textColor.withValues(alpha: 0.70),
                            ),
                          ),
                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.primaryLight.withValues(alpha: 0.4),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${curr.symbol} ',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.accentGold,
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _targetAmountController,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: textColor,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _onCreateGoal,
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
                        lang == AppLanguage.nepali ? 'लक्ष्य सिर्जना गर्नुहोस्' : 'Create Goal',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
