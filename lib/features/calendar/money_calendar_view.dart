import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';

class MoneyCalendarView extends StatefulWidget {
  final String currSymbol;

  const MoneyCalendarView({
    super.key,
    required this.currSymbol,
  });

  @override
  State<MoneyCalendarView> createState() => _MoneyCalendarViewState();
}

class _MoneyCalendarViewState extends State<MoneyCalendarView>
    with TickerProviderStateMixin {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  // Track pop animation controllers per day
  final Map<int, AnimationController> _popControllers = {};

  late final DateTime _minMonth = DateTime(DateTime.now().year - 1, 1, 1);
  late final DateTime _maxMonth = DateTime(DateTime.now().year + 2, 12, 31);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _selectedDate = now;
  }

  @override
  void dispose() {
    for (final controller in _popControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  AnimationController _getPopController(int dayKey) {
    if (!_popControllers.containsKey(dayKey)) {
      _popControllers[dayKey] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      );
    }
    return _popControllers[dayKey]!;
  }

  void _onDaySelected(DateTime date) {
    HapticFeedback.lightImpact();
    final controller = _getPopController(date.day);
    controller.forward(from: 0.0).then((_) {
      controller.reverse();
    });

    setState(() {
      _selectedDate = date;
    });
  }

  void _changeMonth(int offset) {
    final next = DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
    if (next.isBefore(_minMonth) || next.isAfter(_maxMonth)) return;
    setState(() {
      _currentMonth = next;
      // Adjust selected date if day exceeds current month total days
      final daysInNewMonth = DateTime(next.year, next.month + 1, 0).day;
      final newDay = _selectedDate.day.clamp(1, daysInNewMonth);
      _selectedDate = DateTime(next.year, next.month, newDay);
    });
  }

  // ── Helper filter method for single day ─────────────────────────
  List<TransactionItem> _txsForDate(DateTime date, List<TransactionItem> allTxs) {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;

    return allTxs.where((t) {
      final dateLower = t.date.toLowerCase();
      if (isToday && dateLower.contains('today')) return true;
      if (isYesterday && dateLower.contains('yesterday')) return true;

      // Check standard date string or numeric day matching
      final monthNameShort = _getMonthName(date.month).substring(0, 3).toLowerCase();
      if (dateLower.contains(monthNameShort) && dateLower.contains('${date.day}')) {
        return true;
      }
      return false;
    }).toList();
  }

  // ── Helper filter method for entire month ──────────────────────
  List<TransactionItem> _txsForMonth(DateTime month, List<TransactionItem> allTxs) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final Set<String> matchedIds = {};
    final List<TransactionItem> results = [];

    for (int d = 1; d <= daysInMonth; d++) {
      final forDay = _txsForDate(DateTime(month.year, month.month, d), allTxs);
      for (final tx in forDay) {
        if (matchedIds.add(tx.id)) {
          results.add(tx);
        }
      }
    }
    return results;
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateModel();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
    final subTextColor = isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight;
    final cardBg = isDark ? AppTheme.cardColor : AppTheme.surfaceLight;
    final outlineColor = isDark ? const Color(0xFF243348) : const Color(0xFFE2E8F0);

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final allTxs = appState.transactions;
        final selectedDayTxs = _txsForDate(_selectedDate, allTxs);
        final monthTxs = _txsForMonth(_currentMonth, allTxs);

        final dayIncome = selectedDayTxs
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (s, t) => s + t.amount);
        final dayExpense = selectedDayTxs
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (s, t) => s + t.amount);

        final monthIncome = monthTxs
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (s, t) => s + t.amount);
        final monthExpense = monthTxs
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (s, t) => s + t.amount);

        final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
        final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday; // 1 = Mon, 7 = Sun
        // Start grid with Sunday = 0
        final leadingBlanks = firstWeekday % 7;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header & Statement Subtitle ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Money Calendar',
                          style: TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w900, color: textColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Monthly statement & daily log',
                          style: TextStyle(fontSize: 14, color: subTextColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history_edu_rounded, size: 16, color: AppTheme.primaryLight),
                        const SizedBox(width: 4),
                        Text(
                          '1 Yr History',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── Month Navigator Header ──────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: outlineColor.withValues(alpha: 0.7)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left_rounded, color: textColor),
                      onPressed: _currentMonth.isAfter(_minMonth) ? () => _changeMonth(-1) : null,
                      visualDensity: VisualDensity.compact,
                    ),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 18, color: AppTheme.primaryLight),
                        const SizedBox(width: 8),
                        Text(
                          '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right_rounded, color: textColor),
                      onPressed: _currentMonth.isBefore(_maxMonth) ? () => _changeMonth(1) : null,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Full Month Calendar Grid (Bullet Journal Style) ─────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: outlineColor.withValues(alpha: 0.6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Weekday headers (equally divided across 7 columns)
                    Row(
                      children: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((d) {
                        return Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Calendar Days Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: leadingBlanks + daysInMonth,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.95,
                      ),
                      itemBuilder: (context, index) {
                        if (index < leadingBlanks) {
                          return const SizedBox.shrink();
                        }
                        final dayNum = index - leadingBlanks + 1;
                        final date = DateTime(_currentMonth.year, _currentMonth.month, dayNum);
                        final isSelected = _selectedDate.year == date.year &&
                            _selectedDate.month == date.month &&
                            _selectedDate.day == date.day;

                        final dayTxs = _txsForDate(date, allTxs);
                        final hasIncome = dayTxs.any((t) => t.type == TransactionType.income);
                        final hasExpense = dayTxs.any((t) => t.type == TransactionType.expense);
                        final hasBoth = hasIncome && hasExpense;

                        final popController = _getPopController(dayNum);

                        return AnimatedBuilder(
                          animation: popController,
                          builder: (context, child) {
                            final scale = 1.0 + (popController.value * 0.2);
                            return Transform.scale(
                              scale: scale,
                              child: child,
                            );
                          },
                          child: InkWell(
                            onTap: () => _onDaySelected(date),
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryLight
                                    : (dayTxs.isNotEmpty
                                        ? AppTheme.primaryLight.withValues(alpha: 0.07)
                                        : Colors.transparent),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryLight
                                      : (dayTxs.isNotEmpty
                                          ? AppTheme.primaryLight.withValues(alpha: 0.3)
                                          : Colors.transparent),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$dayNum',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                      color: isSelected ? Colors.white : textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // Bullet-journal dot indicators
                                  if (dayTxs.isEmpty)
                                    const SizedBox(height: 5)
                                  else if (hasBoth)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 4.5,
                                          height: 4.5,
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.white : const Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 2.5),
                                        Container(
                                          width: 4.5,
                                          height: 4.5,
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.white70 : const Color(0xFFEF4444),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white
                                            : (hasIncome
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFEF4444)),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),
                    Divider(height: 1, color: outlineColor.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),

                    // Dot legend (Wrap prevents overflow on narrow screens)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _buildLegendItem(const Color(0xFF10B981), 'Income', textColor),
                        _buildLegendItem(const Color(0xFFEF4444), 'Expense', textColor),
                        _buildLegendItem(AppTheme.primaryLight, 'Active Day', textColor),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Month Total Statement Summary ───────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: outlineColor.withValues(alpha: 0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${_getMonthName(_currentMonth.month)} Monthly Statement',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${monthTxs.length} txs',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Inflow',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF047857))),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.currSymbol} ${_formatNumber(monthIncome)}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Outflow',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFB91C1C))),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.currSymbol} ${_formatNumber(monthExpense)}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFFB91C1C)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Selected Date Breakdown ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: outlineColor.withValues(alpha: 0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${_getMonthName(_selectedDate.month).substring(0, 3)} ${_selectedDate.day}, ${_selectedDate.year}',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'Day Balance: ${widget.currSymbol} ${_formatNumber(dayIncome - dayExpense)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: (dayIncome - dayExpense) >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5).withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Income',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF065F46))),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.currSymbol} ${_formatNumber(dayIncome)}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2).withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Expenses',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF991B1B))),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.currSymbol} ${_formatNumber(dayExpense)}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Day Transactions List ────────────────────────────────────
              Text(
                'Day Transactions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
              ),
              const SizedBox(height: 10),

              if (selectedDayTxs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: outlineColor.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.event_busy_outlined, size: 28, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 6),
                      Text('No transactions recorded on this date',
                          style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              else
                ...selectedDayTxs.map((t) {
                  final isInc = t.type == TransactionType.income;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
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
                            Text(t.emoji, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.title,
                                    style: TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
                                Text(t.category,
                                    style: TextStyle(fontSize: 11, color: subTextColor)),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '${isInc ? '+' : '−'} ${widget.currSymbol} ${_formatNumber(t.amount)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isInc ? const Color(0xFF10B981) : textColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 70),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(Color dotColor, String label, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor.withValues(alpha: 0.8)),
        ),
      ],
    );
  }

  String _formatNumber(double amount) {
    final intVal = amount.toInt();
    final digits = intVal.toString();
    if (digits.length <= 3) return digits;
    final lastThree = digits.substring(digits.length - 3);
    final remaining = digits.substring(0, digits.length - 3);
    final regExp = RegExp(r'\B(?=(\d{2})+(?!\d))');
    final formattedRem = remaining.replaceAll(regExp, ',');
    return '$formattedRem,$lastThree';
  }
}
