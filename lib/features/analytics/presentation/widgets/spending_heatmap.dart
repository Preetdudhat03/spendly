import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';
import 'drill_down_sheet.dart';

import 'package:spendly/models/expense.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'spending_heatmap_explorer.dart';
import 'package:spendly/core/providers/state_providers.dart';

class SpendingHeatmap extends ConsumerWidget {
  final AnalyticsState state;
  final List<Expense> allExpenses;

  const SpendingHeatmap({
    super.key,
    required this.state,
    required this.allExpenses,
  });

  Color _getCellColor(BuildContext context, double amount) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    if (amount <= 0) {
      return colorScheme.surfaceContainerHigh.withOpacity(0.5);
    } else if (amount <= 500) {
      return primary.withOpacity(0.30);
    } else if (amount <= 2000) {
      return primary.withOpacity(0.65);
    } else {
      return primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final dateFmt = DateFormat('EEE, MMM d');
    final colorScheme = Theme.of(context).colorScheme;

    final selectedMemberId = ref.watch(analyticsMemberFilterProvider);
    final familyState = ref.watch(familyProvider);
    String? activeMemberName;
    List<Expense> explorerExpenses = allExpenses;
    if (selectedMemberId != null) {
      explorerExpenses = allExpenses
          .where((e) => e.createdBy == selectedMemberId)
          .toList();
      try {
        final member = familyState.members.firstWhere(
          (m) => m.userId == selectedMemberId,
        );
        activeMemberName = member.displayName;
      } catch (_) {}
    }

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
                      'Spending Heatmap',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Identify spending frequency patterns',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Open Spending Heatmap Explorer',
                  icon: Icon(
                    Icons.grid_on,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  onPressed: () {
                    final initialYear = state.dateRange.start.year;
                    SpendingHeatmapExplorer.show(
                      context,
                      expenses: explorerExpenses,
                      initialYear: initialYear,
                      activeMemberName: activeMemberName,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Heatmap Grid Area
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    ...List.generate(weeks.length, (idx) {
                      if (weeks[idx].isNotEmpty) {
                        final firstDay = weeks[idx].first;
                        if (firstDay.day <= 7) {
                          return Container(
                            height: 22,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              DateFormat('MMM').format(firstDay),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
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
                      // Weekday Headers
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: weekdayNames.map((name) {
                          return Expanded(
                            child: Center(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurfaceVariant,
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
                                      message:
                                          '${dateFmt.format(day)}: ${currencyFmt.format(amount)}',
                                      child: GestureDetector(
                                        onTap: () {
                                          final dayExpenses =
                                              allExpenses.where((e) {
                                                return e.expenseDate.year ==
                                                        day.year &&
                                                    e.expenseDate.month ==
                                                        day.month &&
                                                    e.expenseDate.day ==
                                                        day.day;
                                              }).toList()..sort(
                                                (a, b) => b.amount.compareTo(
                                                  a.amount,
                                                ),
                                              );

                                          DrillDownSheet.show(
                                            context,
                                            title: dateFmt.format(day),
                                            subtitle: 'Daily transaction list',
                                            icon: Icons.calendar_today,
                                            color: colorScheme.primary,
                                            totalAmount: amount,
                                            expenses: dayExpenses,
                                            aiSummary:
                                                'You logged ${dayExpenses.length} transactions on this day.',
                                          );
                                        },
                                        child: Container(
                                          height: 16,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getCellColor(
                                              context,
                                              amount,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: colorScheme.outline
                                                  .withOpacity(0.3),
                                              width: 0.5,
                                            ),
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
                Text(
                  'Less',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.30),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 3),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 3),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'More',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
