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
  final _limitController = TextEditingController(text: '8,000');
  String _selectedCategory = 'Food';
  final _selectedPeriod = 'Monthly';
  final _alertPercent = 80;

  final List<Map<String, dynamic>> _categories = const [
    {'name': 'Food', 'icon': Icons.restaurant_rounded},
    {'name': 'Transport', 'icon': Icons.directions_car_rounded},
    {'name': 'Shopping', 'icon': Icons.shopping_bag_outlined},
    {'name': 'Bills', 'icon': Icons.receipt_long_outlined},
    {'name': 'Entertainment', 'icon': Icons.movie_outlined},
    {'name': 'Health', 'icon': Icons.medical_services_outlined},
    {'name': 'Education', 'icon': Icons.school_outlined},
  ];

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  void _onSave() {
    final cleanNum = double.tryParse(_limitController.text.replaceAll(',', '')) ?? 8000.0;
    final budget = BudgetItem(
      id: 'b_${DateTime.now().millisecondsSinceEpoch}',
      category: _selectedCategory,
      emoji: '',
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

          // Category selection
          Text(
            'Category',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: subTextColor),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((c) {
                final isSelected = _selectedCategory == c['name'];
                final icon = c['icon'] as IconData;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () => setState(() {
                      _selectedCategory = c['name'] as String;
                    }),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryLight.withValues(alpha: 0.12)
                            : cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryLight : outlineColor,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            icon,
                            size: 18,
                            color: isSelected ? AppTheme.primaryLight : subTextColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            c['name'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppTheme.primaryLight : textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 18),

          // Limit input
          Text(
            'Limit',
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
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
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
