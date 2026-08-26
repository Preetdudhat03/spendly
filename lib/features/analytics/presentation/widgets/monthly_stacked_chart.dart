import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';
import 'package:spendly/features/analytics/presentation/widgets/category_donut_chart.dart';
import 'package:spendly/models/expense.dart';
import 'package:spendly/core/providers/state_providers.dart';

class MonthlyStackedChart extends StatelessWidget {
  final AnalyticsState state;

  const MonthlyStackedChart({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return _StackedChartConsumer(state: state);
  }
}

class _StackedChartConsumer extends ConsumerWidget {
  final AnalyticsState state;

  const _StackedChartConsumer({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseState = ref.watch(expenseProvider);
    final allExpenses = expenseState.expenses;

    if (allExpenses.isEmpty) {
      return const SizedBox.shrink();
    }

    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    // Calculate last 6 months
    final now = DateTime.now();
    final List<DateTime> months = [];
    for (int i = 5; i >= 0; i--) {
      months.add(DateTime(now.year, now.month - i, 1));
    }

    // Build stacked bar group data
    double maxMonthTotal = 1000.0;
    final List<BarChartGroupData> barGroups = [];
    final monthFormat = DateFormat('MMM');

    // To prevent rendering cluttered categories, we'll keep track of active categories for the legend
    final Set<String> categoriesSeen = {};

    for (int i = 0; i < months.length; i++) {
      final month = months[i];
      final monthExpenses = allExpenses.where((e) {
        return e.expenseDate.year == month.year &&
            e.expenseDate.month == month.month;
      }).toList();

      final Map<String, double> catSums = {};
      double monthTotal = 0;
      for (var e in monthExpenses) {
        catSums[e.category] = (catSums[e.category] ?? 0) + e.amount;
        monthTotal += e.amount;
        categoriesSeen.add(e.category);
      }

      maxMonthTotal = max(maxMonthTotal, monthTotal);

      // Build stack items
      final List<BarChartRodStackItem> stackItems = [];
      double currentSum = 0;

      // Sort categories to maintain visual stability
      final sortedCats = catSums.keys.toList()..sort();

      for (var cat in sortedCats) {
        final amt = catSums[cat] ?? 0.0;
        if (amt > 0) {
          final meta = getCategoryMetadata(context, cat);
          stackItems.add(
            BarChartRodStackItem(currentSum, currentSum + amt, meta.color),
          );
          currentSum += amt;
        }
      }

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: monthTotal,
              rodStackItems: stackItems,
              color: Colors
                  .transparent, // Background color when stack items don't cover
              width: 22,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    maxMonthTotal = maxMonthTotal * 1.15;

    // Show legend for up to 8 top categories in the list
    final List<String> legendCategories = categoriesSeen.toList();
    if (legendCategories.length > 8) {
      legendCategories.removeRange(8, legendCategories.length);
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
                      'Monthly Distribution',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Category splits over the last 6 months',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.bar_chart, size: 20, color: colorScheme.primary),
              ],
            ),
            const SizedBox(height: 24),

            // Bar Chart Area
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxMonthTotal,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) =>
                          colorScheme.surfaceContainerHigh.withOpacity(0.95),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final monthIdx = group.x.toInt();
                        if (monthIdx < 0 || monthIdx >= months.length)
                          return null;

                        final month = months[monthIdx];
                        final monthExpenses = allExpenses.where((e) {
                          return e.expenseDate.year == month.year &&
                              e.expenseDate.month == month.month;
                        }).toList();

                        // Group spending by category to compile tooltip text
                        final Map<String, double> catSums = {};
                        for (var e in monthExpenses) {
                          catSums[e.category] =
                              (catSums[e.category] ?? 0) + e.amount;
                        }

                        final listLines = catSums.entries
                            .map(
                              (e) => '${e.key}: ${currencyFmt.format(e.value)}',
                            )
                            .join('\n');

                        return BarTooltipItem(
                          '${DateFormat('MMMM yyyy').format(month)}\nTotal: ${currencyFmt.format(rod.toY)}\n\n$listLines',
                          TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          String formatted = '';
                          if (value >= 1000) {
                            formatted =
                                '₹${(value / 1000).toStringAsFixed(0)}k';
                          } else {
                            formatted = '₹${value.toStringAsFixed(0)}';
                          }
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              formatted,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < months.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                monthFormat.format(months[idx]),
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.outlineVariant.withOpacity(0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Legend indicators
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: legendCategories.map((cat) {
                final meta = getCategoryMetadata(context, cat);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      meta.iconPath,
                      width: 12,
                      height: 12,
                      colorFilter: ColorFilter.mode(
                        meta.color,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      meta.name,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
