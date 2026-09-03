import 'package:flutter/material.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';

class CreateBudgetDialog extends StatefulWidget {
  final String currSymbol;

  const CreateBudgetDialog({
    super.key,
    required this.currSymbol,
  });

  @override
  State<CreateBudgetDialog> createState() => _CreateBudgetDialogState();
}

class _CreateBudgetDialogState extends State<CreateBudgetDialog> {
  final _titleController = TextEditingController();
  final _limitController = TextEditingController();
  final _selectedPeriod = 'Monthly';
  final _alertPercent = 80;

  @override
  void dispose() {
    _titleController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  void _onSave() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a budget title'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final cleanNum = double.tryParse(_limitController.text.replaceAll(',', '').trim()) ?? 0.0;
    if (cleanNum <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid budget limit amount'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final budget = BudgetItem(
      id: 'b_${DateTime.now().millisecondsSinceEpoch}',
      category: title,
      emoji: '🎯',
      spent: 0.0,
      limit: cleanNum,
      period: _selectedPeriod,
      alertPercent: _alertPercent,
    );

    AppStateModel().addBudget(budget);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
    final subTextColor =
        isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight;
    final cardBg = isDark ? AppTheme.cardColor : AppTheme.surfaceLight;
    final outlineColor =
        isDark ? const Color(0xFF243348) : const Color(0xFFE2E8F0);

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: outlineColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'New Budget',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),

          // Budget Title input
          Text(
            'Budget Title',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: subTextColor),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outlineColor),
            ),
            child: TextField(
              controller: _titleController,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
              decoration: InputDecoration(
                hintText: 'e.g. Dining Out, Fuel, Groceries',
                hintStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: subTextColor.withValues(alpha: 0.5)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Limit input
          Text(
            'Budget Limit',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: subTextColor),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outlineColor),
            ),
            child: Row(
              children: [
                Text(
                  '${widget.currSymbol} ',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.accentGold),
                ),
                Expanded(
                  child: TextField(
                    controller: _limitController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: subTextColor.withValues(alpha: 0.5)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Period & Alert percentage
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Period', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: subTextColor)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: outlineColor)),
                      child: Text(_selectedPeriod, style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Alert when', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: subTextColor)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: outlineColor)),
                      child: Text('$_alertPercent%', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.accentGold)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
              child: const Text(
                'Create Budget',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
