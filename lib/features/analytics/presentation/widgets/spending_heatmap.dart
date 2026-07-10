import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';
import 'drill_down_sheet.dart';

class SpendingHeatmap extends StatelessWidget {
  final AnalyticsState state;

  const SpendingHeatmap({super.key, required this.state});

  Color _getCellColor(BuildContext context, double amount) {
    final primary = Theme.of(context).primaryColor;
    if (amount <= 0) {
      return const Color(0xFFF1F5F9); // Empty state grey
    } else if (amount <= 500) {
      return primary.withOpacity(0.20); // Light
    } else if (amount <= 2000) {
      return primary.withOpacity(0.55); // Medium
    } else {
      return primary; // Dark/Full
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFmt = DateFormat('EEE, MMM d');

    // Retrieve heatmap sorted keys
    final days = state.heatmapData.keys.toList()..sort();
    if (days.isEmpty) return const SizedBox.shrink();

    // Group days into 12 rows of 7 days
    final List<List<DateTime>> weeks = [];
    for (int i = 0; i < 12; i++) {
      if (i * 7 < days.length) {
        weeks.add(days.sublist(i * 7, min((i + 1) * 7, days.length)));
      }
    }

    final weekdayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

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
                      'Spending Heatmap',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Identify spending frequency patterns',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                Icon(Icons.grid_on, size: 20, color: Theme.of(context).primaryColor.withOpacity(0.7)),
              ],
            ),
            const SizedBox(height: 20),

            // Heatmap Grid Area
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Labels for Weeks (Optional, e.g. "W12", "W1" or "Month" indicators)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24), // Offset for day headers
                    ...List.generate(weeks.length, (idx) {
                      // Show month indicator for first day of week
                      if (weeks[idx].isNotEmpty) {
                        final firstDay = weeks[idx].first;
                        if (firstDay.day <= 7) {
                          return Container(
                            height: 22,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              DateFormat('MMM').format(firstDay),
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey[400]),
                            ),
                          );
                        }
                      }
                      return const SizedBox(height: 22);
                    }),
                  ],
                ),
                const SizedBox(width: 8),

                // Main Heatmap Grid
                Expanded(
                  child: Column(
                    children: [
                      // Weekday Headers (Columns)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: weekdayNames.map((name) {
                          return Expanded(
                            child: Center(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),

                      // Weeks rows
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: weeks.length,
                        itemBuilder: (context, weekIdx) {
                          final week = weeks[weekIdx];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(7, (dayIdx) {
                                if (dayIdx < week.length) {
                                  final day = week[dayIdx];
                                  final amount = state.heatmapData[day] ?? 0.0;
                                  return Expanded(
                                    child: Tooltip(
                                      triggerMode: TooltipTriggerMode.tap,
                                      message: '${dateFmt.format(day)}: ${currencyFmt.format(amount)}',
                                      child: GestureDetector(
                                        onTap: () {
                                          final dayExpenses = state.filteredExpenses.where((e) {
                                            return e.expenseDate.year == day.year &&
                                                e.expenseDate.month == day.month &&
                                                e.expenseDate.day == day.day;
                                          }).toList()
                                            ..sort((a, b) => b.amount.compareTo(a.amount));

                                          if (dayExpenses.isNotEmpty) {
                                            DrillDownSheet.show(
                                              context,
                                              title: dateFmt.format(day),
                                              subtitle: 'Daily transaction list',
                                              icon: Icons.calendar_today,
                                              color: Theme.of(context).primaryColor,
                                              totalAmount: amount,
                                              expenses: dayExpenses,
                                              aiSummary: 'You logged ${dayExpenses.length} transactions on this day.',
                                            );
                                          }
                                        },
                                        child: Container(
                                          height: 16,
                                          margin: const EdgeInsets.symmetric(horizontal: 3),
                                          decoration: BoxDecoration(
                                            color: _getCellColor(context, amount),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  return Expanded(child: Container());
                                }
                              }),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Legend Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Less', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                const SizedBox(width: 4),
                Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 3),
                Container(width: 12, height: 12, decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.20), borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 3),
                Container(width: 12, height: 12, decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.55), borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 3),
                Container(width: 12, height: 12, decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 4),
                Text('More', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
