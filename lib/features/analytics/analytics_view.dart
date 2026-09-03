import 'package:flutter/material.dart';
import '../../core/services/number_formatter.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';

class AnalyticsView extends StatefulWidget {
  final String currSymbol;

  const AnalyticsView({
    super.key,
    required this.currSymbol,
  });

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  int _selectedTab = 0; // 0: Spending, 1: Income, 2: Savings

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
        final txs = appState.transactions;
        final expenseTxs =
            txs.where((t) => t.type == TransactionType.expense).toList();
        final incomeTxs =
            txs.where((t) => t.type == TransactionType.income).toList();

        final totalExpenses = expenseTxs.fold(0.0, (s, t) => s + t.amount);
        final totalIncome = incomeTxs.fold(0.0, (s, t) => s + t.amount);
        final netSavings = totalIncome - totalExpenses;
        final savingsRate =
            totalIncome > 0 ? ((netSavings / totalIncome) * 100).clamp(0.0, 100.0) : 0.0;

        // Current active list depending on selected tab
        final activeTxs = _selectedTab == 0
            ? expenseTxs
            : (_selectedTab == 1 ? incomeTxs : txs);

        // Compute Category Breakdown for active tab
        final Map<String, double> categorySums = {};
        if (_selectedTab == 0) {
          for (final t in expenseTxs) {
            categorySums[t.category] = (categorySums[t.category] ?? 0.0) + t.amount;
          }
        } else if (_selectedTab == 1) {
          for (final t in incomeTxs) {
            categorySums[t.category] = (categorySums[t.category] ?? 0.0) + t.amount;
          }
        }

        final sortedCategories = categorySums.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final maxCategoryAmount = sortedCategories.isNotEmpty
            ? sortedCategories.first.value
            : 1.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Money',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: textColor)),
                      const SizedBox(height: 2),
                      Text(
                        () {
                          const months = [
                            'January', 'February', 'March', 'April', 'May', 'June',
                            'July', 'August', 'September', 'October', 'November', 'December'
                          ];
                          final now = DateTime.now();
                          return '${months[now.month - 1]} ${now.year}';
                        }(),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryLight),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.insights_rounded,
                            size: 14, color: AppTheme.primaryLight),
                        SizedBox(width: 4),
                        Text('Analytics',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryLight)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Tabs: Spending | Income | Savings
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: outlineColor),
                ),
                child: Row(
                  children: [
                    _buildTabButton(0, 'Spending', textColor),
                    _buildTabButton(1, 'Income', textColor),
                    _buildTabButton(2, 'Savings', textColor),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              if (activeTxs.isEmpty && _selectedTab != 2)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(22),
                    border:
                        Border.all(color: outlineColor.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.query_stats_rounded,
                          size: 48,
                          color: subTextColor.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text(
                        _selectedTab == 0
                            ? 'No spending records yet'
                            : 'No income records yet',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textColor),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Log transactions to see real real-time category breakdowns and trends.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: subTextColor),
                      ),
                    ],
                  ),
                )
              else if (_selectedTab == 0 || _selectedTab == 1) ...[
                // Overview Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: outlineColor.withValues(alpha: 0.6)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedTab == 0
                                ? 'Total Spending'
                                : 'Total Income',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: textColor),
                          ),
                          Text(
                            '${widget.currSymbol} ${_formatNumber(_selectedTab == 0 ? totalExpenses : totalIncome)}',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: _selectedTab == 0
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF10B981)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Real Category Distribution Bars
                      if (sortedCategories.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Category Breakdown',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: subTextColor)),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 120,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: sortedCategories.take(5).map((entry) {
                                  final val = entry.value;
                                  final label = entry.key;
                                  return _buildBar(
                                    label,
                                    val,
                                    maxCategoryAmount,
                                    widget.currSymbol,
                                    textColor,
                                    subTextColor,
                                    isIncome: _selectedTab == 1,
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Top Categories Detailed List
                if (sortedCategories.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: outlineColor.withValues(alpha: 0.6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedTab == 0
                              ? 'Expense categories'
                              : 'Income categories',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: textColor),
                        ),
                        const SizedBox(height: 16),
                        ...sortedCategories.map((entry) {
                          final baseTotal = _selectedTab == 0 ? totalExpenses : totalIncome;
                          final pct = baseTotal > 0 ? (entry.value / baseTotal) : 0.0;
                          final pctInt = (pct * 100).toInt();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildCategoryRank(
                              entry.key,
                              '${widget.currSymbol} ${_formatNumber(entry.value)} ($pctInt%)',
                              pct,
                              _selectedTab == 0
                                  ? AppTheme.primaryLight
                                  : const Color(0xFF10B981),
                              textColor,
                              subTextColor,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
              ] else ...[
                // Tab 2: Savings Screen (Real Data)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: outlineColor.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Net Financial Summary',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: textColor)),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSummaryTile(
                            'Total Income',
                            '+${widget.currSymbol} ${_formatNumber(totalIncome)}',
                            const Color(0xFF10B981),
                            cardBg,
                            outlineColor,
                          ),
                          const SizedBox(width: 12),
                          _buildSummaryTile(
                            'Total Expenses',
                            '-${widget.currSymbol} ${_formatNumber(totalExpenses)}',
                            const Color(0xFFEF4444),
                            cardBg,
                            outlineColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: netSavings >= 0
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: netSavings >= 0
                                ? const Color(0xFF34D399).withValues(alpha: 0.4)
                                : const Color(0xFFFCA5A5).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Net Savings',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: netSavings >= 0
                                    ? const Color(0xFF065F46)
                                    : const Color(0xFF991B1B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.currSymbol} ${_formatNumber(netSavings)}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: netSavings >= 0
                                    ? const Color(0xFF047857)
                                    : const Color(0xFFDC2626),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Savings Rate: ${savingsRate.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: netSavings >= 0
                                    ? const Color(0xFF065F46)
                                    : const Color(0xFF991B1B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 60),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryTile(
      String label, String value, Color color, Color cardBg, Color outlineColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ],
        ),
      ),
    );
  }

  String _formatNumber(double amount) => NumberFormatter.format(amount);

  Widget _buildTabButton(int index, String label, Color textColor) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
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
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBar(String label, double val, double maxVal, String currSymbol,
      Color textColor, Color subTextColor,
      {bool isIncome = false}) {
    final heightFactor = maxVal > 0 ? (val / maxVal).clamp(0.15, 1.0) : 0.15;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          val >= 1000
              ? '${(val / 1000).toStringAsFixed(1)}k'
              : val.toInt().toString(),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isIncome ? const Color(0xFF10B981) : AppTheme.primaryLight),
        ),
        const SizedBox(height: 6),
        Container(
          width: 34,
          height: 70 * heightFactor,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isIncome
                  ? [const Color(0xFF34D399), const Color(0xFF059669)]
                  : [AppTheme.primaryLight, AppTheme.primary],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 44,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: textColor),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRank(String name, String valueLabel, double pct,
      Color color, Color textColor, Color subTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor)),
            Text(valueLabel,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3))),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct.clamp(0.0, 1.0),
              child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(3))),
            ),
          ],
        ),
      ],
    );
  }
}
