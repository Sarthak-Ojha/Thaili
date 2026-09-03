import 'package:flutter/material.dart';
import '../../core/services/number_formatter.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';

class RecurringTransactionsView extends StatefulWidget {
  final String currSymbol;

  const RecurringTransactionsView({
    super.key,
    required this.currSymbol,
  });

  @override
  State<RecurringTransactionsView> createState() => _RecurringTransactionsViewState();
}

class _RecurringTransactionsViewState extends State<RecurringTransactionsView> {
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
        final recurringList = appState.recurring;
        final totalMonthly = recurringList.fold(0.0, (s, r) => s + r.amount);

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
                      Text('Recurring', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: textColor)),
                      const SizedBox(height: 2),
                      Text('Upcoming subscriptions & fixed bills', style: TextStyle(fontSize: 13, color: subTextColor)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddRecurringDialog(context, widget.currSymbol),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add recurring', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Total Monthly Fixed Outflow Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: outlineColor.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Monthly Fixed Outflow', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: subTextColor)),
                        const SizedBox(height: 4),
                        Text('${widget.currSymbol} ${_formatNumber(totalMonthly)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.repeat_rounded, color: AppTheme.primaryLight, size: 24),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text('Active Subscriptions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textColor)),
              const SizedBox(height: 12),

              // Recurring Items (NTC, Internet, Rent, Netflix)
              ...recurringList.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Container(
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
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 22))),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
                                const SizedBox(height: 2),
                                Text(item.category, style: TextStyle(fontSize: 12, color: subTextColor)),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${widget.currSymbol} ${_formatNumber(item.amount)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textColor)),
                            const SizedBox(height: 2),
                            Text('/ ${item.frequency}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subTextColor)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 60),
            ],
          ),
        );
      },
    );
  }

  void _showAddRecurringDialog(BuildContext context, String currSymbol) {
    final titleController = TextEditingController(text: 'Gym Membership');
    final amountController = TextEditingController(text: '2000');
    String emoji = '💪';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(left: 24, right: 24, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 18),
            const Text('Add Recurring Bill', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Amount ($currSymbol)', border: const OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                  if (amount > 0) {
                    AppStateModel().addRecurring(
                      RecurringTransaction(
                        id: 'r_${DateTime.now().millisecondsSinceEpoch}',
                        title: titleController.text.trim(),
                        emoji: emoji,
                        amount: amount,
                      ),
                    );
                  }
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryLight, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Save Recurring', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(double amount) => NumberFormatter.format(amount);
}
