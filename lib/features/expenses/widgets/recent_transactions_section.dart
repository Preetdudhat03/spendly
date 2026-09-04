import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/features/expenses/widgets/expense_detail_modal.dart';
import 'package:spendly/models/expense.dart';

class RecentTransactionsSection extends ConsumerWidget {
  final List<Expense> expenses;
  final NumberFormat currencyFormat;

  const RecentTransactionsSection({
    super.key,
    required this.expenses,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final displayExpenses = expenses.length > 5 ? expenses.take(5).toList() : expenses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Recent Expenses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                letterSpacing: -0.2,
              ),
            ),
            TextButton(
              onPressed: () {
                context.push('/expenses');
              },
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // List or Empty State
        if (expenses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? colorScheme.outline.withOpacity(0.4)
                    : colorScheme.outline.withOpacity(0.8),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.receipt,
                    size: 28,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'No expenses logged yet this month',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap the + button to add your first expense',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayExpenses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final exp = displayExpenses[index];
              return _RecentTransactionTile(
                exp: exp,
                currencyFormat: currencyFormat,
              );
            },
          ),
      ],
    );
  }
}

class _RecentTransactionTile extends ConsumerWidget {
  final Expense exp;
  final NumberFormat currencyFormat;

  const _RecentTransactionTile({
    required this.exp,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final catColor = getCategoryColor(exp.category);
    final iconPath = getCategoryIconPath(exp.category);
    final dayStr = DateFormat('dd MMM').format(exp.expenseDate);
    final expenseTitle = exp.description.isEmpty ? exp.category : exp.description;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? colorScheme.outline.withOpacity(0.4)
              : colorScheme.outline.withOpacity(0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.12)
                : colorScheme.shadow.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showExpenseDetail(context, ref, exp),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Category Icon Badge
                Container(
                  width: 42,
                  height: 42,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SvgPicture.asset(
                    iconPath,
                    colorFilter: ColorFilter.mode(catColor, BlendMode.srcIn),
                  ),
                ),
                const SizedBox(width: 12),

                // Description & Subtitle Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expenseTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            'by ${exp.createdByName}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            ' • $dayStr',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Amount
                Text(
                  '-${currencyFormat.format(exp.amount)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFEF4444),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 6),

                // Delete Action Button
                IconButton(
                  icon: Icon(
                    LucideIcons.trash2,
                    size: 16,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: () {
                    _showDeleteConfirm(context, ref, exp.id);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Expense?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Are you sure you want to remove this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              ref.read(expenseProvider.notifier).deleteExpense(id);
              Navigator.pop(context);
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}
