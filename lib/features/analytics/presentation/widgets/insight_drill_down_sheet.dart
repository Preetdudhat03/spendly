import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spendly/features/analytics/models/analytics_models.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';
import 'package:spendly/features/expenses/widgets/expense_detail_modal.dart';
import 'package:spendly/models/expense.dart';

class InsightDrillDownSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double currentSpend;
  final PeriodComparison? trend;
  final int transactionCount;
  final double averageTransaction;
  final double largestTransaction;
  final double percentageOfTotal;
  final String? extraStatLabel;
  final String? extraStatValue;
  final List<Expense> expenses;

  const InsightDrillDownSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.currentSpend,
    this.trend,
    required this.transactionCount,
    required this.averageTransaction,
    required this.largestTransaction,
    required this.percentageOfTotal,
    this.extraStatLabel,
    this.extraStatValue,
    this.expenses = const [],
  });

  static void showForCategory(
    BuildContext context, {
    required CategoryInsight insight,
    required IconData icon,
    required Color color,
    List<Expense> expenses = const [],
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InsightDrillDownSheet(
        title: insight.categoryName,
        subtitle: 'Category Insights',
        icon: icon,
        color: color,
        currentSpend: insight.currentSpend,
        trend: insight.trend,
        transactionCount: insight.transactionCount,
        averageTransaction: insight.averageTransaction,
        largestTransaction: insight.largestTransaction,
        percentageOfTotal: insight.percentageOfTotal,
        expenses: expenses,
      ),
    );
  }

  static void showForMember(
    BuildContext context, {
    required MemberInsight insight,
    List<Expense> expenses = const [],
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InsightDrillDownSheet(
        title: insight.memberName,
        subtitle: 'Member Insights',
        icon: Icons.person,
        color: Colors.purple,
        currentSpend: insight.currentSpend,
        trend: insight.trend,
        transactionCount: insight.transactionCount,
        averageTransaction: insight.averageTransaction,
        largestTransaction: 0, // MemberInsight doesn't have largestTransaction
        percentageOfTotal: insight.percentageOfTotal,
        extraStatLabel: 'Top Category',
        extraStatValue: insight.topCategory,
        expenses: expenses,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color:
                Theme.of(context).cardTheme.color ??
                Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFmt.format(currentSpend),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                        Text(
                          '${percentageOfTotal.toStringAsFixed(1)}% of total',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 90.0),
                  children: [
                    if (trend != null) _buildTrendCard(context, currencyFmt),
                    if (trend != null) const SizedBox(height: 24),

                    Text(
                      'Deep Analytics',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        _buildStatBox(
                          context,
                          'Transactions',
                          '$transactionCount',
                          Icons.receipt_long,
                          Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        _buildStatBox(
                          context,
                          'Average Txn',
                          currencyFmt.format(averageTransaction),
                          Icons.calculate,
                          Colors.teal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        if (largestTransaction > 0)
                          _buildStatBox(
                            context,
                            'Largest Txn',
                            currencyFmt.format(largestTransaction),
                            Icons.shopping_bag,
                            Colors.orange,
                          ),
                        if (largestTransaction > 0 && extraStatLabel != null)
                          const SizedBox(width: 12),
                        if (extraStatLabel != null)
                          _buildStatBox(
                            context,
                            extraStatLabel!,
                            extraStatValue ?? '-',
                            Icons.star,
                            Colors.purple,
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Transactions Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transactions (${expenses.length})',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (expenses.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'No individual transactions found for this period.',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      Consumer(
                        builder: (context, ref, _) {
                          final dateFmt = DateFormat('MMM d, yyyy • h:mm a');
                          return Column(
                            children: expenses.map((exp) {
                              return InkWell(
                                onTap: () => showExpenseDetail(context, ref, exp),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8.0),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14.0,
                                    vertical: 12.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withOpacity(0.12),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: color.withOpacity(0.15),
                                        radius: 20,
                                        child: Text(
                                          exp.createdByName.isNotEmpty
                                              ? exp.createdByName
                                                  .substring(0, 1)
                                                  .toUpperCase()
                                              : 'M',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              exp.description.isEmpty
                                                  ? exp.category
                                                  : exp.description,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${exp.createdByName} • ${exp.paymentMethod} • ${dateFmt.format(exp.expenseDate)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        currencyFmt.format(exp.amount),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendCard(BuildContext context, NumberFormat currencyFmt) {
    final t = trend!;
    final isIncrease = t.direction == TrendDirection.increase;
    final colorScheme = Theme.of(context).colorScheme;

    if (t.direction == TrendDirection.stable) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('No change compared to the previous period.'),
      );
    }

    final trendColor = isIncrease ? Colors.red : Colors.green;
    final icon = isIncrease ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: trendColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: trendColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: trendColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isIncrease ? "Increased" : "Decreased"} by ${t.percentageChange.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: trendColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Difference: ${isIncrease ? "+" : "-"}${currencyFmt.format(t.absoluteChange)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
    BuildContext context,
    String label,
    String value,
    IconData statIcon,
    Color statColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: statColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statColor.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(statIcon, size: 20, color: statColor),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: statColor,
                fontWeight: FontWeight.w900,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
