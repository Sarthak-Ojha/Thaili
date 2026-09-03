import 'package:flutter/material.dart';
import '../../core/services/category_manager.dart';
import '../../core/services/transaction_validator.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_constants.dart';
import '../../core/theme/app_theme.dart';

class TransactionEditDialog extends StatefulWidget {
  final TransactionItem transaction;
  final String currSymbol;

  const TransactionEditDialog({
    super.key,
    required this.transaction,
    required this.currSymbol,
  });

  @override
  State<TransactionEditDialog> createState() => _TransactionEditDialogState();
}

class _TransactionEditDialogState extends State<TransactionEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late TransactionType _type;
  late String _category;
  late String _emoji;
  late String _paymentMethod;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.transaction.title);
    _amountController =
        TextEditingController(text: widget.transaction.amount.toStringAsFixed(0));
    _noteController = TextEditingController(text: widget.transaction.note);
    _type = widget.transaction.type;
    _category = widget.transaction.category;
    _emoji = widget.transaction.emoji;
    _paymentMethod = widget.transaction.paymentMethod;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.replaceAll(',', '').trim()) ??
        widget.transaction.amount;

    final updated = widget.transaction.copyWith(
      title: _titleController.text.trim(),
      amount: amount,
      type: _type,
      category: _category,
      emoji: _emoji,
      note: _noteController.text.trim(),
      paymentMethod: _paymentMethod,
    );

    AppStateModel().editTransaction(updated);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;
    final subTextColor = isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight;
    final cardBg = isDark ? AppTheme.cardColor : AppTheme.surfaceLight;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Transaction',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Transaction Type Selector
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _type = TransactionType.expense),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _type == TransactionType.expense
                              ? const Color(0xFFFEE2E2)
                              : cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _type == TransactionType.expense
                                ? const Color(0xFFEF4444)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Expense',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _type == TransactionType.expense
                                  ? const Color(0xFFEF4444)
                                  : subTextColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _type = TransactionType.income),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _type == TransactionType.income
                              ? const Color(0xFFD1FAE5)
                              : cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _type == TransactionType.income
                                ? const Color(0xFF10B981)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Income',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _type == TransactionType.income
                                  ? const Color(0xFF10B981)
                                  : subTextColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title Field
              TextFormField(
                controller: _titleController,
                validator: TransactionValidator.validateTitle,
                decoration: InputDecoration(
                  labelText: 'Title / Description',
                  hintText: 'e.g. Grocery Shopping',
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 14),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: TransactionValidator.validateAmount,
                decoration: InputDecoration(
                  labelText: 'Amount (${widget.currSymbol})',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),

              // Category Selector Chips
              Text(
                'Category',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: subTextColor),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: CategoryManager.defaultCategories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = CategoryManager.defaultCategories[index];
                    final isSelected = _category.toLowerCase() == cat.name.toLowerCase();
                    return ChoiceChip(
                      label: Text('${cat.emoji} ${cat.name}'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _category = cat.name;
                            _emoji = cat.emoji;
                          });
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Note Field
              TextFormField(
                controller: _noteController,
                validator: TransactionValidator.validateNotes,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Optional Notes',
                  hintText: 'Additional details...',
                  prefixIcon: const Icon(Icons.notes_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
