import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';

class FinancialSummaryCards extends StatelessWidget {
  final AnalyticsState state;

  const FinancialSummaryCards({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    // Calculate budget status color
    final progress = state.budgetProgressPercent;
    Color budgetProgressColor = Colors.green;
    if (progress >= 0.8) {
      budgetProgressColor = Colors.red;
    } else if (progress >= 0.5) {
      budgetProgressColor = Colors.orange;
    }

    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 142,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        children: [
          // 1. Total Spent Card
          _buildSummaryCard(
            context,
            title: 'Total Spent',
            value: currencyFmt.format(
              state.summary?.totalSpend.currentValue ?? state.totalSpent,
            ),
            icon: Icons.account_balance_wallet_outlined,
            iconColor: colorScheme.primary,
            cardBg: colorScheme.primary.withOpacity(0.12),
            bottomWidget: Row(
              children: [
                Icon(
                  (state.summary?.totalSpend.percentageChange ??
                              state.totalSpentDiffPercent) >=
                          0
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: 14,
                  color:
                      (state.summary?.totalSpend.percentageChange ??
                              state.totalSpentDiffPercent) >=
                          0
                      ? Colors.red
                      : Colors.green,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${(state.summary?.totalSpend.percentageChange ?? state.totalSpentDiffPercent).abs().toStringAsFixed(0)}% vs last period',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color:
                          (state.summary?.totalSpend.percentageChange ??
                                  state.totalSpentDiffPercent) >=
                              0
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Daily Average Card
          _buildSummaryCard(
            context,
            title: 'Daily Average',
            value:
                '${currencyFmt.format(state.summary?.dailyAverage.currentValue ?? state.dailyAverage)}/day',
            icon: Icons.analytics_outlined,
            iconColor: Colors.blue,
            cardBg: Colors.blue.withOpacity(0.12),
            bottomWidget: Row(
              children: [
                Icon(
                  (state.summary?.dailyAverage.percentageChange ??
                              state.dailyAverageDiffPercent) >=
                          0
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: 14,
                  color:
                      (state.summary?.dailyAverage.percentageChange ??
                              state.dailyAverageDiffPercent) >=
                          0
                      ? Colors.red
                      : Colors.green,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'vs previous period',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Budget Remaining Card
          _buildSummaryCard(
            context,
            title: 'Budget Remaining',
            value: currencyFmt.format(state.budgetRemaining),
            icon: Icons.pie_chart_outline,
            iconColor: budgetProgressColor,
            cardBg: budgetProgressColor.withOpacity(0.12),
            bottomWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${state.budgetLimit.toStringAsFixed(0)} Limit',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: budgetProgressColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    color: budgetProgressColor,
                    backgroundColor: colorScheme.surfaceContainerHigh,
                  ),
                ),
              ],
            ),
          ),

          // 4. Total Transactions Card
          _buildSummaryCard(
            context,
            title: 'Total Transactions',
            value:
                '${state.summary?.transactionCount.currentValue.toInt() ?? state.totalTransactions} Entries',
            icon: Icons.receipt_long_outlined,
            iconColor: Colors.orange,
            cardBg: Colors.orange.withOpacity(0.12),
            bottomWidget: Text(
              '${state.summary?.transactionCount.previousValue.toInt() ?? state.prevTotalTransactions} in last period',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // 5. Active Members Card
          _buildSummaryCard(
            context,
            title: 'Active Members',
            value: '${state.activeMembersCount} Members',
            icon: Icons.people_outline,
            iconColor: Colors.purple,
            cardBg: Colors.purple.withOpacity(0.12),
            bottomWidget: Text(
              'Family Shared Account',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color cardBg,
    required Widget bottomWidget,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Icon and Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Row 2: Value
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          // Row 3: Trend/Detail
          bottomWidget,
        ],
      ),
    );
  }
}
