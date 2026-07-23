import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendly/features/analytics/presentation/widgets/category_donut_chart.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';
import 'package:spendly/models/expense.dart';
import 'package:spendly/features/analytics/presentation/widgets/drill_down_sheet.dart';

class SpendingHeatmap extends StatelessWidget {
  final AnalyticsState state;
  final List<Expense> allExpenses;

  const SpendingHeatmap({
    super.key,
    required this.state,
    required this.allExpenses,
  });

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

  void _showDayExpenses(BuildContext context, DateTime date, double totalAmount, List<Expense> allExpenses) {
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFmt = DateFormat('EEEE, MMMM d, yyyy');

    final dayExpenses = allExpenses.where((e) {
      final d = e.expenseDate;
      return d.year == date.year && d.month == date.month && d.day == date.day;
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Daily Spend History',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateFmt.format(date),
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currencyFmt.format(totalAmount),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              dayExpenses.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('No expenses logged on this day.')),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: dayExpenses.length,
                      itemBuilder: (context, idx) {
                        final exp = dayExpenses[idx];
                        final meta = getCategoryMetadata(context, exp.category);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: meta.color.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(meta.emoji, style: const TextStyle(fontSize: 16)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exp.description.isEmpty ? meta.name : exp.description,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'By ${exp.createdByName} • ${exp.paymentMethod}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                currencyFmt.format(exp.amount),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
          ),
        );
      },
    );
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
                                          _showDayExpenses(context, day, amount, allExpenses);
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
