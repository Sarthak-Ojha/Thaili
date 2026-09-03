import 'package:flutter/material.dart';
import '../../core/services/number_formatter.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';

class TransactionDetailsSheet extends StatelessWidget {
  final TransactionItem transaction;
  final String currSymbol;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TransactionDetailsSheet({
    super.key,
    required this.transaction,
    required this.currSymbol,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
    final subTextColor =
        isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight;
    final cardBg = isDark ? AppTheme.cardColor : AppTheme.surfaceLight;
    final outlineColor =
        isDark ? const Color(0xFF243348) : const Color(0xFFE2E8F0);
    final isIncome = transaction.type == TransactionType.income;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
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
          const SizedBox(height: 20),

          // Emoji Icon Badge
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: (isIncome ? const Color(0xFF34D399) : AppTheme.primaryLight)
                  .withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                transaction.emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            transaction.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),

          // Category Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: outlineColor),
            ),
            child: Text(
              transaction.category,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: subTextColor,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Amount
          Text(
            '${isIncome ? '+' : '−'} $currSymbol ${_formatNumber(transaction.amount)}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: isIncome ? const Color(0xFF34D399) : textColor,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 24),

          // Metadata Grid (Date, Payment Method)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: outlineColor),
            ),
            child: Column(
              children: [
                _buildMetaRow(
                  icon: '📅',
                  label: 'Date',
                  value: transaction.date == 'Today'
                      ? () {
                          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                          final now = DateTime.now();
                          return '${months[now.month - 1]} ${now.day}, ${now.year}';
                        }()
                      : transaction.date,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
                Divider(height: 20, color: outlineColor.withValues(alpha: 0.6)),
                _buildMetaRow(
                  icon: '💵',
                  label: 'Payment Method',
                  value: transaction.paymentMethod,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
                if (transaction.note.isNotEmpty) ...[
                  Divider(height: 20, color: outlineColor.withValues(alpha: 0.6)),
                  _buildMetaRow(
                    icon: '📝',
                    label: 'Note',
                    value: transaction.note,
                    textColor: textColor,
                    subTextColor: subTextColor,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons: Edit & Delete
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onEdit();
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text(
                    'Edit',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryLight,
                    side: const BorderSide(color: AppTheme.primaryLight, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text(
                    'Delete',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE2E2),
                    foregroundColor: const Color(0xFFEF4444),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMetaRow({
    required String icon,
    required String label,
    required String value,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: subTextColor, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
        ),
      ],
    );
  }

  String _formatNumber(double amount) => NumberFormatter.format(amount);
}
