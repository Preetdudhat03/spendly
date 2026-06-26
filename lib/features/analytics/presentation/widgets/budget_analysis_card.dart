import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';

class BudgetAnalysisCard extends StatelessWidget {
  final AnalyticsState state;

  const BudgetAnalysisCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final spent = state.totalSpent;
    final budget = state.budgetLimit;
    final remaining = state.budgetRemaining;
    final progress = state.budgetProgressPercent;

    // Forecast calculation
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final daysElapsed = max(1, now.day);
    
    // Project based on daily average
    final projectedSpend = state.dailyAverage * daysInMonth;
    final isExceededForecast = projectedSpend > budget;
    final forecastExceedAmount = max(0.0, projectedSpend - budget);

    String forecastMessage = '';
    Color forecastBg = Colors.emerald.withOpacity(0.06);
    Color forecastBorder = Colors.emerald.withOpacity(0.2);
    Color forecastTextColor = Colors.emerald[800]!;
    IconData forecastIcon = Icons.check_circle_outline;

    if (isExceededForecast && budget > 0) {
      forecastMessage = 'If spending continues at current pace, you will exceed your budget by ${currencyFmt.format(forecastExceedAmount)} (Projected total: ${currencyFmt.format(projectedSpend)}).';
      forecastBg = Colors.rose.withOpacity(0.06);
      forecastBorder = Colors.rose.withOpacity(0.2);
      forecastTextColor = Colors.rose[800]!;
      forecastIcon = Icons.warning_amber_rounded;
    } else {
      forecastMessage = 'You are on track to stay within your budget. Projected monthly total: ${currencyFmt.format(projectedSpend)}.';
    }

    Color progressColor = Colors.emerald;
    if (progress >= 0.8) {
      progressColor = Colors.rose;
    } else if (progress >= 0.5) {
      progressColor = Colors.orange;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: Color(0xFFF1F5F9)),
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
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Adherence and monthly forecasting',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
                      _buildInfoRow(context, 'Monthly Budget', currencyFmt.format(budget), Colors.grey[800]!),
                      const SizedBox(height: 10),
                      _buildInfoRow(context, 'Total Spent', currencyFmt.format(spent), progressColor),
                      const SizedBox(height: 10),
                      _buildInfoRow(context, 'Remaining', currencyFmt.format(remaining), remaining > 0 ? Colors.emerald : Colors.grey),
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
                            backgroundColor: const Color(0xFFF1F5F9),
                            color: progressColor,
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
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
                                color: Colors.grey[500],
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

  Widget _buildInfoRow(BuildContext context, String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
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
