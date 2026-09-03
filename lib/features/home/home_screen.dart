import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/services/number_formatter.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../analytics/analytics_view.dart';
import '../budgets/create_budget_dialog.dart';
import '../calendar/money_calendar_view.dart';
import '../export/export_data_dialog.dart';
import '../goals/create_goal_dialog.dart';
import '../recurring/recurring_transactions_view.dart';
import '../splash/widgets/animated_money_pouch.dart';
import '../transactions/transaction_details_sheet.dart';
import '../transactions/transaction_edit_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentNavIndex = 0;
  String _searchQuery = '';
  String _selectedTxFilter = 'All'; // 'All', 'Income', 'Expense'
  Timer? _searchDebounce;

  // ── Radial FAB ────────────────────────────────────────────────────────
  bool _isFabOpen = false;
  late AnimationController _fabController;
  late Animation<double> _fabRotation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fabRotation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _fabController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _searchQuery = query);
      }
    });
  }

  void _toggleFab() {
    setState(() => _isFabOpen = !_isFabOpen);
    _isFabOpen ? _fabController.forward() : _fabController.reverse();
  }

  void _closeFab() {
    if (!_isFabOpen) return;
    setState(() => _isFabOpen = false);
    _fabController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateModel();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
    final subTextColor =
        isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight;
    final cardBg = isDark ? AppTheme.cardColor : AppTheme.surfaceLight;
    final outlineColor = isDark ? const Color(0xFF243348) : const Color(0xFFE2E8F0);

    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Stack(
      children: [
        ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final lang = appState.language;
        final curr = appState.currentCurrencyData;
        final userName = appState.userName;
        final goals = appState.goals;
        final budgets = appState.budgets;
        final transactions = appState.transactions;

        // Metrics — derived from actual logged transactions
        final bakiBalance = appState.initialBalance;
        final incomeAmount = transactions
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (sum, t) => sum + t.amount);
        final spentAmount = transactions
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (sum, t) => sum + t.amount);
        final totalBudgetSpent = appState.totalBudgetSpent;
        final totalBudgetLimit = appState.totalBudgetLimit;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryLight.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const SpittingPouchIcon(size: 28, interval: Duration(seconds: 4)),
                ),
                const SizedBox(width: 10),
                Text(
                  'THAILI',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    fontSize: 18,
                    color: textColor,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () => setState(() => _currentNavIndex = 6), // Jump to Calendar
                icon: Icon(Icons.calendar_today_rounded,
                    color: textColor.withValues(alpha: 0.65), size: 20),
                tooltip: 'Money Calendar',
              ),
              IconButton(
                onPressed: () => setState(() => _currentNavIndex = 5), // Jump to Analytics (Charts & Graphs)
                icon: Icon(Icons.insert_chart_outlined_rounded,
                    color: textColor.withValues(alpha: 0.65), size: 22),
                tooltip: 'Analytics & Charts',
              ),
              IconButton(
                onPressed: () => setState(() => _currentNavIndex = 9), // Jump to Settings & More
                icon: Icon(Icons.settings_outlined,
                    color: textColor.withValues(alpha: 0.65), size: 22),
                tooltip: 'Settings',
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: IndexedStack(
            index: _currentNavIndex,
            children: [
              // Tab 0: Home Overview (BAKI + Quick Highlights)
              _buildHomeDashboard(
                lang: lang,
                userName: userName.isNotEmpty ? userName : (lang == AppLanguage.nepali ? 'साथी' : 'Friend'),
                currSymbol: curr.symbol,
                bakiBalance: bakiBalance,
                incomeAmount: incomeAmount,
                spentAmount: spentAmount,
                cardBg: cardBg,
                outlineColor: outlineColor,
                textColor: textColor,
                subTextColor: subTextColor,
              ),

              // Tab 1: Section 10 - Transactions Screen
              _buildTransactionsTab(
                transactions: transactions,
                currSymbol: curr.symbol,
                cardBg: cardBg,
                outlineColor: outlineColor,
                textColor: textColor,
                subTextColor: subTextColor,
              ),

              // Tab 2: Section 11 & 12 - Budgets Screen
              _buildBudgetsTab(
                budgets: budgets,
                totalSpent: totalBudgetSpent,
                totalLimit: totalBudgetLimit,
                currSymbol: curr.symbol,
                cardBg: cardBg,
                outlineColor: outlineColor,
                textColor: textColor,
                subTextColor: subTextColor,
              ),

              // Tab 3: Section 13 - Goals Screen
              _buildGoalsTab(
                goals: goals,
                currSymbol: curr.symbol,
                cardBg: cardBg,
                outlineColor: outlineColor,
                textColor: textColor,
                subTextColor: subTextColor,
              ),

              // Tab 4: Analytics Graphs & Charts View
              AnalyticsView(currSymbol: curr.symbol),

              // Tab 5: Analytics Graphs & Charts View
              AnalyticsView(currSymbol: curr.symbol),

              // Tab 6: Money Calendar (1-Year Statement & Daily Logs)
              MoneyCalendarView(currSymbol: curr.symbol),

              // Tab 7: Recurring Transactions (NTC, Internet, Rent, Subscriptions)
              RecurringTransactionsView(currSymbol: curr.symbol),

              // Tab 8: Local Storage View
              const SizedBox.shrink(),

              // Tab 9: Settings & Preferences Screen
              _buildMoreTab(
                lang: lang,
                userName: userName,
                appState: appState,
                cardBg: cardBg,
                outlineColor: outlineColor,
                textColor: textColor,
                subTextColor: subTextColor,
              ),
            ],
          ),
          // ── Radial FAB ───────────────────────────────────────────────
          floatingActionButton: _buildMainFAB(),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          // ── Bottom Navigation Bar (Home | Transactions | Budgets | Goals | More) ─
          bottomNavigationBar: BottomAppBar(
            elevation: 8,
            color: isDark ? AppTheme.surface : AppTheme.surfaceLight,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, AppStrings.navHome(lang)),
                _buildNavItem(1, Icons.receipt_long_rounded, AppStrings.navTransactions(lang)),
                const SizedBox(width: 44), // Notch gap
                _buildNavItem(2, Icons.pie_chart_outline_rounded, AppStrings.navBudgets(lang)),
                _buildNavItem(3, Icons.flag_outlined, AppStrings.navGoals(lang)),
              ],
            ),
          ),
        );
      },
    ),
        // ── Dim overlay when FAB is open ─────────────────────────────────
        if (_isFabOpen)
          GestureDetector(
            onTap: _closeFab,
            child: Container(
              color: Colors.black.withValues(alpha: 0.40),
            ),
          ),
        // ── FAB Sub-action Buttons ────────────────────────────────────────
        ...(_isFabOpen
            ? _buildFabSubButtons(
                context,
                bottomPad,
                textColor,
                cardBg,
                outlineColor,
              )
            : <Widget>[]),
      ],
    );
  }

  String _getFormattedCurrentDate(AppLanguage lang) {
    const enDays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    const enMonths = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const neDays = [
      'सोमवार', 'मंगलबार', 'बुधबार', 'बिहीबार', 'शुक्रबार', 'शनिबार', 'आइतबार'
    ];
    const neMonths = [
      'जनवरी', 'फेब्रुअरी', 'मार्च', 'अप्रिल', 'मे', 'जुन',
      'जुलाई', 'अगस्ट', 'सेप्टेम्बर', 'अक्टोबर', 'नोभेम्बर', 'डिसेम्बर'
    ];
    final now = DateTime.now();
    if (lang == AppLanguage.nepali) {
      return '${neDays[now.weekday - 1]}, ${now.day} ${neMonths[now.month - 1]} ${now.year}';
    }
    return '${enDays[now.weekday - 1]}, ${enMonths[now.month - 1]} ${now.day}, ${now.year}';
  }

  String _getCurrentMonthName([bool includeYear = false]) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final now = DateTime.now();
    final monthStr = months[now.month - 1];
    return includeYear ? '$monthStr ${now.year}' : monthStr;
  }

  // ══════════════════════════════════════════════════════════════════════
  // TAB 0: HOME OVERVIEW
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildHomeDashboard({
    required AppLanguage lang,
    required String userName,
    required String currSymbol,
    required double bakiBalance,
    required double incomeAmount,
    required double spentAmount,
    required Color cardBg,
    required Color outlineColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Accurate Daily Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang == AppLanguage.nepali ? 'नमस्ते, $userName' : 'Namaste, $userName',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _getFormattedCurrentDate(lang),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Main BAKI Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF14B8A6),
                  Color(0xFF0F766E),
                  Color(0xFF042F2E),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'THAILI BALANCE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.0,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Available this month',
                        style: TextStyle(
                          color: AppTheme.goldLight,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '$currSymbol ${_formatNumber(bakiBalance)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Income vs Spent Metrics Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // ↑ Income
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF34D399).withValues(alpha: 0.20),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_upward_rounded, size: 16, color: Color(0xFF34D399)),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Income', style: TextStyle(fontSize: 11, color: Colors.white70)),
                                Text('$currSymbol ${_formatNumber(incomeAmount)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 28, color: Colors.white24),
                      const SizedBox(width: 14),
                      // ↓ Spent
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF87171).withValues(alpha: 0.20),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFFF87171)),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Spent', style: TextStyle(fontSize: 11, color: Colors.white70)),
                                Text('$currSymbol ${_formatNumber(spentAmount)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick Navigation Shortcuts
          Row(
            children: [
              Expanded(
                child: _buildSectionShortcut(
                  title: 'Budgets',
                  subtitle: AppStateModel().budgets.isEmpty ? 'No budget yet' : '${AppStateModel().budgets.length} active categories',
                  icon: Icons.pie_chart_outline_rounded,
                  color: AppTheme.primaryLight,
                  cardBg: cardBg,
                  outlineColor: outlineColor,
                  textColor: textColor,
                  onTap: () => setState(() => _currentNavIndex = 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSectionShortcut(
                  title: 'Savings Goals',
                  subtitle: AppStateModel().goals.isEmpty ? 'Set a target' : '${AppStateModel().goals.length} savings goals',
                  icon: Icons.flag_outlined,
                  color: AppTheme.accentGold,
                  cardBg: cardBg,
                  outlineColor: outlineColor,
                  textColor: textColor,
                  onTap: () => setState(() => _currentNavIndex = 3),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent Activity Preview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
              ),
              TextButton(
                onPressed: () => setState(() => _currentNavIndex = 1),
                child: const Text(
                  'See all →',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (AppStateModel().transactions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: outlineColor.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 32, color: subTextColor.withValues(alpha: 0.6)),
                  const SizedBox(height: 8),
                  Text(
                    lang == AppLanguage.nepali ? 'कुनै कारोबार भेटिएन' : 'No transactions yet',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lang == AppLanguage.nepali ? 'नयाँ खर्च वा आम्दानी थप्न + थिच्नुहोस्' : 'Tap + below to log your first transaction',
                    style: TextStyle(fontSize: 12, color: subTextColor),
                  ),
                ],
              ),
            )
          else
            ...AppStateModel().transactions.take(3).map((tx) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildTransactionTile(
                  item: tx,
                  currSymbol: currSymbol,
                  cardBg: cardBg,
                  outlineColor: outlineColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  onTap: () => _showTransactionDetails(context, tx, currSymbol),
                ),
              );
            }),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // TAB 1: SECTION 10 - TRANSACTIONS SCREEN
  // Search, Filters (All, Income, Expense), Swipe Edit/Delete, Tap Details
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildTransactionsTab({
    required List<TransactionItem> transactions,
    required String currSymbol,
    required Color cardBg,
    required Color outlineColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    // Filter & Search Logic
    final filtered = transactions.where((t) {
      if (_selectedTxFilter == 'Income' && t.type != TransactionType.income) return false;
      if (_selectedTxFilter == 'Expense' && t.type != TransactionType.expense) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return t.title.toLowerCase().contains(query) ||
            t.category.toLowerCase().contains(query) ||
            t.note.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    // Grouping by dates
    final datesSet = <String>{'Today', 'Yesterday'};
    for (final t in filtered) {
      datesSet.add(t.date);
    }
    final dates = datesSet.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transactions',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: textColor),
          ),
          const SizedBox(height: 16),

          // Search Bar: 🔍 Search transactions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outlineColor.withValues(alpha: 0.7)),
            ),
            child: TextField(
              onChanged: _onSearchChanged,
              style: TextStyle(fontSize: 15, color: textColor),
              decoration: InputDecoration(
                icon: Icon(Icons.search_rounded, color: subTextColor, size: 22),
                hintText: 'Search transactions',
                hintStyle: TextStyle(fontSize: 14, color: subTextColor),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Filters: All | Income | Expense
          Row(
            children: [
              _buildFilterChip('All', _selectedTxFilter == 'All', () => setState(() => _selectedTxFilter = 'All')),
              const SizedBox(width: 8),
              _buildFilterChip('Income', _selectedTxFilter == 'Income', () => setState(() => _selectedTxFilter = 'Income')),
              const SizedBox(width: 8),
              _buildFilterChip('Expense', _selectedTxFilter == 'Expense', () => setState(() => _selectedTxFilter = 'Expense')),
            ],
          ),

          const SizedBox(height: 20),

          // Grouped Transaction List
          ...dates.map((date) {
            final txsInDate = filtered.where((t) => t.date == date).toList();
            if (txsInDate.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDayHeader(date, subTextColor),
                const SizedBox(height: 8),
                ...txsInDate.map((tx) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Dismissible(
                      key: Key(tx.id),
                      direction: DismissDirection.horizontal,
                      background: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerLeft,
                        child: const Row(
                          children: [
                            Icon(Icons.edit_rounded, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Edit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      secondaryBackground: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            SizedBox(width: 8),
                            Icon(Icons.delete_outline_rounded, color: Colors.white),
                          ],
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.endToStart) {
                          AppStateModel().deleteTransaction(tx.id);
                          return true;
                        } else {
                          // Edit trigger
                          _showEditTransactionDialog(context, tx, currSymbol);
                          return false;
                        }
                      },
                      child: _buildTransactionTile(
                        item: tx,
                        currSymbol: currSymbol,
                        cardBg: cardBg,
                        outlineColor: outlineColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        onTap: () => _showTransactionDetails(context, tx, currSymbol),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ],
            );
          }),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // TAB 2: SECTION 11 & 12 - BUDGETS SCREEN
  // August, Overall 72% used, Category Bars (Food, Transport, Shopping 120%), + Create Budget
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildBudgetsTab({
    required List<BudgetItem> budgets,
    required double totalSpent,
    required double totalLimit,
    required String currSymbol,
    required Color cardBg,
    required Color outlineColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    final overallSpent = totalSpent;
    final overallLimit = totalLimit;
    final overallPercent = overallLimit > 0 ? ((overallSpent / overallLimit) * 100).toInt() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Budgets', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: textColor)),
                  const SizedBox(height: 2),
                  Text(_getCurrentMonthName(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primaryLight)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateBudgetSheet(context, currSymbol),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create Budget', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Overall Budget Card (Dynamic)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F766E), Color(0xFF115E59), Color(0xFF042F2E)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(color: AppTheme.primary.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Overall Budget', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12)),
                      child: Text('$overallPercent% used', style: const TextStyle(color: AppTheme.goldLight, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  overallLimit > 0
                      ? '$currSymbol ${_formatNumber(overallSpent)} / $currSymbol ${_formatNumber(overallLimit)}'
                      : '$currSymbol 0 / $currSymbol 0',
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 0.2),
                ),
                const SizedBox(height: 16),
                Stack(
                  children: [
                    Container(height: 10, width: double.infinity, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(5))),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: overallLimit > 0 ? (overallSpent / overallLimit).clamp(0.0, 1.0) : 0.0,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppTheme.goldLight, AppTheme.accentGold]),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          Text('Your Budgets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
          const SizedBox(height: 14),

          if (budgets.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: outlineColor.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 32, color: subTextColor.withValues(alpha: 0.6)),
                  const SizedBox(height: 8),
                  Text('No budgets created yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
                  const SizedBox(height: 4),
                  Text('Tap "Create Budget" above to track spending limits', style: TextStyle(fontSize: 12, color: subTextColor)),
                ],
              ),
            )
          else
            ...budgets.map((b) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Dismissible(
                  key: Key(b.id),
                  direction: DismissDirection.startToEnd, // Swiping right to remove
                  background: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.centerLeft,
                    child: const Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Delete Budget',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onDismissed: (_) {
                    AppStateModel().deleteBudget(b.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${b.category} budget removed'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  child: _buildBudgetCategoryBar(
                    emoji: b.emoji,
                    category: b.category,
                    spent: b.spent,
                    limit: b.limit,
                    currSymbol: currSymbol,
                    cardBg: cardBg,
                    outlineColor: outlineColor,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    isOverbudget: b.limit > 0 && b.spent > b.limit,
                  ),
                ),
              );
            }),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildBudgetCategoryBar({
    required String emoji,
    required String category,
    required double spent,
    required double limit,
    required String currSymbol,
    required Color cardBg,
    required Color outlineColor,
    required Color textColor,
    required Color subTextColor,
    required bool isOverbudget,
  }) {
    final pct = limit > 0 ? (spent / limit) : 0.0;
    final pctInt = (pct * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverbudget ? const Color(0xFFEF4444).withValues(alpha: 0.4) : outlineColor.withValues(alpha: 0.6),
          width: isOverbudget ? 1.5 : 1,
        ),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isOverbudget
                          ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                          : AppTheme.primaryLight.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      size: 18,
                      color: isOverbudget ? const Color(0xFFEF4444) : AppTheme.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(category, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
                ],
              ),
              if (isOverbudget)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
                  child: Text('$pctInt% Over', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w800)),
                )
              else
                Text(
                  '$currSymbol ${_formatNumber(spent)} / $currSymbol ${_formatNumber(limit)}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: subTextColor),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Visual Progress Bar
          Stack(
            children: [
              Container(height: 8, width: double.infinity, decoration: BoxDecoration(color: outlineColor.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(4))),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct.clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOverbudget ? const Color(0xFFEF4444) : AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('food') || cat.contains('snack') || cat.contains('restaurant')) return Icons.restaurant_rounded;
    if (cat.contains('transport') || cat.contains('fuel') || cat.contains('bus') || cat.contains('taxi')) return Icons.directions_car_rounded;
    if (cat.contains('shopping') || cat.contains('cloth')) return Icons.shopping_bag_outlined;
    if (cat.contains('bill') || cat.contains('util')) return Icons.receipt_long_outlined;
    if (cat.contains('entertainment') || cat.contains('movie')) return Icons.movie_outlined;
    if (cat.contains('health') || cat.contains('med')) return Icons.medical_services_outlined;
    if (cat.contains('education') || cat.contains('course') || cat.contains('school')) return Icons.school_outlined;
    return Icons.pie_chart_outline_rounded;
  }

  // ══════════════════════════════════════════════════════════════════════
  // TAB 3: SECTION 13 - GOALS SCREEN
  // Top Card: New Laptop 48%, 72,000 / 150,000, 78,000 remaining, Dec 2026
  // Other Goals: Emergency Fund, Dashain Trip, Course, + New Goal
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildGoalsTab({
    required List<FinancialGoal> goals,
    required String currSymbol,
    required Color cardBg,
    required Color outlineColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    final topGoal = goals.isNotEmpty ? goals.first : null;
    final otherGoals = goals.length > 1 ? goals.sublist(1) : <FinancialGoal>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Savings Goals', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: textColor)),
              ElevatedButton.icon(
                onPressed: () => _showCreateGoalSheet(context, currSymbol),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Goal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (goals.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: outlineColor.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Icon(Icons.flag_outlined, size: 36, color: subTextColor.withValues(alpha: 0.6)),
                  const SizedBox(height: 10),
                  Text('No savings goals yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
                  const SizedBox(height: 4),
                  Text('Tap "New Goal" above to start tracking your targets', style: TextStyle(fontSize: 12, color: subTextColor)),
                ],
              ),
            )
          else ...[
            // Top Active Goal Card
            if (topGoal != null)
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
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
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.accentGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.flag_rounded, color: AppTheme.accentGold, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Text(topGoal.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.accentGold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                          child: Text('${topGoal.percent.toInt()}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.goldDark)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Progress Bar
                    Stack(
                      children: [
                        Container(height: 10, width: double.infinity, decoration: BoxDecoration(color: outlineColor.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(5))),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: topGoal.progressFactor,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppTheme.accentGold, AppTheme.accentOrange]),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$currSymbol ${_formatNumber(topGoal.currentAmount)} / $currSymbol ${_formatNumber(topGoal.targetAmount)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor)),
                        Text('$currSymbol ${_formatNumber(topGoal.remaining)} remaining', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.accentGold)),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Divider(height: 1, color: outlineColor.withValues(alpha: 0.6)),
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Estimated completion:', style: TextStyle(fontSize: 12, color: subTextColor, fontWeight: FontWeight.w600)),
                        Text(topGoal.estimatedCompletion, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textColor)),
                      ],
                    ),
                  ],
                ),
              ),

            if (otherGoals.isNotEmpty) ...[
              const SizedBox(height: 26),
              Text('Other goals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
              const SizedBox(height: 12),

              ...otherGoals.map((g) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: _buildSecondaryGoalCard(g, currSymbol, cardBg, outlineColor, textColor, subTextColor),
                );
              }),
            ],
          ],

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildSecondaryGoalCard(FinancialGoal goal, String currSymbol, Color cardBg, Color outlineColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.savings_rounded, color: AppTheme.primaryLight, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
                  const SizedBox(height: 2),
                  Text('$currSymbol ${_formatNumber(goal.currentAmount)} of $currSymbol ${_formatNumber(goal.targetAmount)}', style: TextStyle(fontSize: 12, color: subTextColor)),
                ],
              ),
            ],
          ),
          Text('${goal.percent.toInt()}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primaryLight)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // TAB 9: SETTINGS, PRIVACY & DATA MANAGEMENT
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildMoreTab({
    required AppLanguage lang,
    required String userName,
    required AppStateModel appState,
    required Color cardBg,
    required Color outlineColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings & Preferences', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: textColor)),
          const SizedBox(height: 18),

          // ── Appearance Section (Light | Dark | System) ─────────────────
          Text('Appearance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: subTextColor)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outlineColor.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                _buildSegmentButton('Light', appState.themeMode == ThemeMode.light, () => appState.setThemeMode(ThemeMode.light), textColor),
                _buildSegmentButton('Dark', appState.themeMode == ThemeMode.dark, () => appState.setThemeMode(ThemeMode.dark), textColor),
                _buildSegmentButton('System', appState.themeMode == ThemeMode.system, () => appState.setThemeMode(ThemeMode.system), textColor),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Language Section (English | नेपाली) ────────────────────────
          Text('Language / भाषा', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: subTextColor)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outlineColor.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                _buildSegmentButton('English', appState.language == AppLanguage.english, () => appState.setLanguage(AppLanguage.english), textColor),
                _buildSegmentButton('नेपाली', appState.language == AppLanguage.nepali, () => appState.setLanguage(AppLanguage.nepali), textColor),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Currency Section ──────────────────────────────────────────
          Text('Currency', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: subTextColor)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: AppTheme.primaryLight.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: Center(child: Text(appState.currentCurrencyData.symbol, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primaryLight))),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appState.currentCurrencyData.getName(lang), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
                        Text(appState.currentCurrencyData.getSubtext(lang), style: TextStyle(fontSize: 11, color: subTextColor)),
                      ],
                    ),
                  ],
                ),
                PopupMenuButton<AppCurrency>(
                  onSelected: (curr) => appState.setCurrency(curr),
                  icon: Icon(Icons.swap_horiz_rounded, color: AppTheme.primaryLight),
                  itemBuilder: (ctx) => AppStateModel.supportedCurrencies.map((c) {
                    return PopupMenuItem(value: c.currency, child: Text(c.getName(lang)));
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const SizedBox(height: 24),

          // ── Data & Storage Section (Export Only - 100% Offline App) ────
          Text('Data & Storage', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: subTextColor)),
          const SizedBox(height: 10),

          _buildActionCard(
            icon: Icons.file_download_outlined,
            title: 'Export Your Data',
            subtitle: 'Download CSV or PDF transaction ledger locally',
            color: AppTheme.accentGold,
            cardBg: cardBg,
            outlineColor: outlineColor,
            textColor: textColor,
            subTextColor: subTextColor,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => const ExportDataDialog(),
            ),
          ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String label, bool isSelected, VoidCallback onTap, Color textColor) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color cardBg,
    required Color outlineColor,
    required Color textColor,
    required Color subTextColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: outlineColor.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: subTextColor)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: subTextColor),
          ],
        ),
      ),
    );
  }



  // ══════════════════════════════════════════════════════════════════════
  // DIALOGS & ACTION SHEETS
  // ══════════════════════════════════════════════════════════════════════
  void _showTransactionDetails(BuildContext context, TransactionItem item, String currSymbol) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransactionDetailsSheet(
        transaction: item,
        currSymbol: currSymbol,
        onEdit: () => _showEditTransactionDialog(context, item, currSymbol),
        onDelete: () => AppStateModel().deleteTransaction(item.id),
      ),
    );
  }

  void _showEditTransactionDialog(BuildContext context, TransactionItem item, String currSymbol) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransactionEditDialog(
        transaction: item,
        currSymbol: currSymbol,
      ),
    );
  }

  void _showCreateBudgetSheet(BuildContext context, String currSymbol) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateBudgetDialog(currSymbol: currSymbol),
    );
  }

  void _showCreateGoalSheet(BuildContext context, String currSymbol) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateGoalDialog(currSymbol: currSymbol),
    );
  }

  void _showAddTransactionDialog(
    BuildContext context,
    String currSymbol,
    Color textColor,
    Color cardBg,
    Color outlineColor, {
    TransactionType initialType = TransactionType.expense,
  }) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    TransactionType type = initialType;
    String selectedExpenseCategory = 'Food';
    String selectedExpenseEmoji = '🍔';

    final expenseCategories = [
      {'name': 'Food', 'emoji': '🍔'},
      {'name': 'Shopping', 'emoji': '🛍️'},
      {'name': 'Travel', 'emoji': '✈️'},
      {'name': 'Bills', 'emoji': '🧾'},
      {'name': 'Entertainment', 'emoji': '🎬'},
      {'name': 'Health', 'emoji': '🏥'},
      {'name': 'Education', 'emoji': '📚'},
      {'name': 'Transport', 'emoji': '🚗'},
      {'name': 'Misc', 'emoji': '📦'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final subTextColor = isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight;

          return Container(
            padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24),
            decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28))),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                              color: outlineColor,
                              borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 18),
                  Text('Add Transaction',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textColor)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(
                              () => type = TransactionType.expense),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: type == TransactionType.expense
                                  ? const Color(0xFFFEE2E2)
                                  : cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: type == TransactionType.expense
                                      ? const Color(0xFFEF4444)
                                      : outlineColor),
                            ),
                            child: const Center(
                                child: Text('Expense',
                                    style: TextStyle(
                                        color: Color(0xFFEF4444),
                                        fontWeight: FontWeight.w700))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(
                              () => type = TransactionType.income),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: type == TransactionType.income
                                  ? const Color(0xFFD1FAE5)
                                  : cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: type == TransactionType.income
                                      ? const Color(0xFF10B981)
                                      : outlineColor),
                            ),
                            child: const Center(
                                child: Text('Income',
                                    style: TextStyle(
                                        color: Color(0xFF10B981),
                                        fontWeight: FontWeight.w700))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Title Field (ONLY for Income)
                  if (type == TransactionType.income) ...[
                    TextField(
                      controller: titleController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Title (e.g. Salary)',
                        hintText: 'Salary',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Amount Field
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount ($currSymbol)',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Selection (ONLY for Expenses)
                  if (type == TransactionType.expense) ...[
                    Text('Select Category',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: subTextColor)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: expenseCategories.map((cat) {
                        final isSelected =
                            selectedExpenseCategory == cat['name'];
                        return InkWell(
                          onTap: () => setModalState(() {
                            selectedExpenseCategory = cat['name']!;
                            selectedExpenseEmoji = cat['emoji']!;
                          }),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryLight.withValues(alpha: 0.15)
                                  : cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryLight
                                    : outlineColor,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(cat['emoji']!,
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  cat['name']!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? AppTheme.primaryLight
                                        : textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ] else
                    const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        final amount =
                            double.tryParse(amountController.text.trim()) ?? 0.0;
                        if (amount > 0) {
                          String formattedTitle;
                          if (type == TransactionType.expense) {
                            formattedTitle = selectedExpenseCategory;
                          } else {
                            final rawTitle = titleController.text.trim();
                            if (rawTitle.isEmpty) {
                              formattedTitle = 'Salary';
                            } else {
                              formattedTitle = rawTitle.split(RegExp(r'\s+')).map((w) {
                                if (w.isEmpty) return '';
                                return w[0].toUpperCase() + w.substring(1);
                              }).join(' ');
                            }
                          }

                          AppStateModel().addTransaction(
                            TransactionItem(
                              id: 't_${DateTime.now().millisecondsSinceEpoch}',
                              title: formattedTitle,
                              category: type == TransactionType.expense
                                  ? selectedExpenseCategory
                                  : 'Income',
                              emoji: type == TransactionType.expense
                                  ? selectedExpenseEmoji
                                  : '💰',
                              amount: amount,
                              type: type,
                              date: 'Today',
                              paymentMethod: 'Cash',
                              note: 'Logged via Quick Add',
                            ),
                          );
                        }
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryLight,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: const Text('Save Transaction',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }



  // ══════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildTransactionTile({
    required TransactionItem item,
    required String currSymbol,
    required Color cardBg,
    required Color outlineColor,
    required Color textColor,
    required Color subTextColor,
    VoidCallback? onTap,
  }) {
    final isIncome = item.type == TransactionType.income;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: outlineColor.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(item.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textColor)),
                      const SizedBox(height: 2),
                      Text(item.category, style: TextStyle(fontSize: 11, color: subTextColor)),
                    ],
                  ),
                ],
              ),
              Text(
                '${isIncome ? '+' : '−'} $currSymbol ${_formatNumber(item.amount)}',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isIncome ? const Color(0xFF34D399) : textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionShortcut({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color cardBg,
    required Color outlineColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: outlineColor.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.55))),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : null,
      ),
    );
  }

  Widget _buildDayHeader(String text, Color subTextColor) {
    return Text(
      text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: subTextColor, letterSpacing: 0.5),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // RADIAL FAB HELPERS
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildMainFAB() {
    return RotationTransition(
      turns: _fabRotation,
      child: FloatingActionButton(
        onPressed: _toggleFab,
        backgroundColor: AppTheme.primaryLight,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  List<Widget> _buildFabSubButtons(
    BuildContext context,
    double bottomPad,
    Color textColor,
    Color cardBg,
    Color outlineColor,
  ) {
    final currSymbol = AppStateModel().currentCurrencyData.symbol;
    return [
      // ── Add Expense (fans left) ──────────────────────────────────────
      Positioned(
        bottom: bottomPad + 108,
        left: 0,
        right: 0,
        child: Center(
          child: AnimatedBuilder(
            animation: _fabController,
            builder: (_, child) => Transform.translate(
              offset: Offset(-105 * _fabController.value, 0),
              child: Opacity(opacity: _fabController.value, child: child!),
            ),
            child: _buildSubFabButton(
              icon: Icons.remove_circle_outline_rounded,
              label: 'Add Expense',
              accentColor: const Color(0xFFEF4444),
              cardBg: cardBg,
              outlineColor: outlineColor,
              textColor: textColor,
              onTap: () {
                _closeFab();
                _showAddTransactionDialog(
                  context,
                  currSymbol,
                  textColor,
                  cardBg,
                  outlineColor,
                  initialType: TransactionType.expense,
                );
              },
            ),
          ),
        ),
      ),
      // ── Add Income (fans right) ─────────────────────────────────────
      Positioned(
        bottom: bottomPad + 108,
        left: 0,
        right: 0,
        child: Center(
          child: AnimatedBuilder(
            animation: _fabController,
            builder: (_, child) => Transform.translate(
              offset: Offset(105 * _fabController.value, 0),
              child: Opacity(opacity: _fabController.value, child: child!),
            ),
            child: _buildSubFabButton(
              icon: Icons.add_circle_outline_rounded,
              label: 'Add Income',
              accentColor: AppTheme.primaryLight,
              cardBg: cardBg,
              outlineColor: outlineColor,
              textColor: textColor,
              onTap: () {
                _closeFab();
                _showAddTransactionDialog(
                  context,
                  currSymbol,
                  textColor,
                  cardBg,
                  outlineColor,
                  initialType: TransactionType.income,
                );
              },
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildSubFabButton({
    required IconData icon,
    required String label,
    required Color accentColor,
    required Color cardBg,
    required Color outlineColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: outlineColor.withValues(alpha: 0.8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentNavIndex == index;
    final color = isSelected ? AppTheme.primaryLight : const Color(0xFF94A3B8);

    return InkWell(
      onTap: () => setState(() => _currentNavIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryLight.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: color,
                letterSpacing: isSelected ? 0.2 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(double amount) => NumberFormatter.format(amount);
}
