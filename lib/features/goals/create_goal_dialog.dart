import 'package:flutter/material.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';

class CreateGoalDialog extends StatefulWidget {
  final String currSymbol;

  const CreateGoalDialog({
    super.key,
    required this.currSymbol,
  });

  @override
  State<CreateGoalDialog> createState() => _CreateGoalDialogState();
}

class _CreateGoalDialogState extends State<CreateGoalDialog> {
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  void _onSave() {
    final cleanNum = double.tryParse(_targetController.text.replaceAll(',', '')) ?? 0.0;
    final now = DateTime.now();
    final goal = FinancialGoal(
      id: 'g_${now.millisecondsSinceEpoch}',
      title: _titleController.text.trim().isEmpty ? 'Financial Goal' : _titleController.text.trim(),
      emoji: '🎯',
      targetAmount: cleanNum > 0 ? cleanNum : 50000.0,
      currentAmount: 0.0,
      estimatedCompletion: '${_getMonthName(now.month)} ${now.year + 1}',
    );

    AppStateModel().addGoal(goal);
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
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 44, height: 4, decoration: BoxDecoration(color: outlineColor, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),

            Text(
              'New Goal',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textColor),
            ),
            const SizedBox(height: 16),

            // Goal Title
            Text('Goal Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: subTextColor)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: outlineColor)),
              child: TextField(
                controller: _titleController,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
                decoration: InputDecoration(
                  hintText: 'e.g. New Laptop, Dashain Trip',
                  hintStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: subTextColor.withValues(alpha: 0.5)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Target Amount
            Text('Target Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: subTextColor)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: outlineColor)),
              child: Row(
                children: [
                  Text('${widget.currSymbol} ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.accentGold)),
                  Expanded(
                    child: TextField(
                      controller: _targetController,
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

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: const Text('Create Goal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
