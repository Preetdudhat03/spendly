import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';

class BudgetAnalysisCard extends StatelessWidget {
  final AnalyticsState state;

  const BudgetAnalysisCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final spent = state.totalSpent;
    final budget = state.budgetLimit;
    final remaining = state.budgetRemaining;
    final progress = state.budgetProgressPercent;

    // Forecast calculation
    final projectedSpend =
        state.budgetForecast?.projectedTotal ?? state.projectedMonthEnd;
    final isExceededForecast = projectedSpend > budget;
    final forecastExceedAmount =
        state.budgetForecast?.expectedOverrun ?? state.expectedOverspend;

    String forecastMessage = '';
    Color forecastBg = Colors.green.withOpacity(0.06);
    Color forecastBorder = Colors.green.withOpacity(0.2);
    Color forecastTextColor = Colors.green[800]!;
    IconData forecastIcon = Icons.check_circle_outline;

    if (isExceededForecast && budget > 0) {
      forecastMessage =
          'If spending continues at current pace, you will exceed your budget by ${currencyFmt.format(forecastExceedAmount)} (Projected total: ${currencyFmt.format(projectedSpend)}).';
      forecastBg = Colors.red.withOpacity(0.06);
      forecastBorder = Colors.red.withOpacity(0.2);
      forecastTextColor = Colors.red[800]!;
      forecastIcon = Icons.warning_amber_rounded;
    } else {
      forecastMessage =
          'You are on track to stay within your budget. Projected monthly total: ${currencyFmt.format(projectedSpend)}.';
    }

    Color progressColor = Colors.green;
    if (progress >= 0.8) {
      progressColor = Colors.red;
    } else if (progress >= 0.5) {
      progressColor = Colors.orange;
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget Analysis',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Adherence and monthly forecasting',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.pie_chart, size: 20, color: progressColor),
              ],
            ),
            const SizedBox(height: 20),

            // Top area: Info vs Circular gauge
            Row(
              children: [
                // Info Columns
                Expanded(
                  child: Column(
                    children: [
                      _buildInfoRow(
                        context,
                        'Monthly Budget',
                        currencyFmt.format(budget),
                        colorScheme.onSurface,
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        context,
                        'Total Spent',
                        currencyFmt.format(spent),
                        progressColor,
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        context,
                        'Remaining',
                        currencyFmt.format(remaining),
                        remaining > 0
                            ? Colors.green
                            : colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Circular Progress Gauge
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    children: [
                      Center(
                        child: SizedBox(
                          width: 86,
                          height: 86,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 10,
                            backgroundColor: colorScheme.surfaceContainerHigh,
                            color: progressColor,
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              budget > 0
                                  ? '${(spent / budget * 100).toStringAsFixed(0)}%'
                                  : '0%',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: progressColor,
                              ),
                            ),
                            Text(
                              'spent',
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Forecast card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: forecastBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: forecastBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(forecastIcon, size: 18, color: forecastTextColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      forecastMessage,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: forecastTextColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
