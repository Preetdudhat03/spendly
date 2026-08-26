import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';

class MemberComparisonChart extends StatelessWidget {
  final AnalyticsState state;

  const MemberComparisonChart({super.key, required this.state});

  Color _getMemberColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFF636AE8); // Violet
      case 1:
        return const Color(0xFFEC4899); // Pink
      case 2:
        return const Color(0xFF10B981); // Emerald
      case 3:
        return const Color(0xFFF59E0B); // Amber
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  @override
  Widget build(BuildContext context) {
    if (state.diagnostic == null || state.diagnostic!.memberInsights.isEmpty) {
      return const SizedBox.shrink();
    }

    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    double maxSpending = 100.0;
    final List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < state.memberShares.length; i++) {
      final member = state.memberShares[i];
      maxSpending = max(maxSpending, member.totalSpent);

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: member.totalSpent,
              color: _getMemberColor(i),
              width: 24,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    maxSpending = maxSpending * 1.15;

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
                      'Member Spend Chart',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Compare totals and usage patterns',
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

            // Chart area
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxSpending,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) =>
                          colorScheme.surfaceContainerHigh.withOpacity(0.95),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final idx = group.x.toInt();
                        if (idx < 0 || idx >= state.memberShares.length)
                          return null;
                        final member = state.memberShares[idx];
                        return BarTooltipItem(
                          '${member.name}\nTotal: ${currencyFmt.format(member.totalSpent)}\nAvg: ${currencyFmt.format(member.average)}\nEntries: ${member.count}',
                          TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 11,
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
                          if (idx >= 0 && idx < state.memberShares.length) {
                            final name = state.memberShares[idx].name;
                            final shortName = name.split(' ').first;
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                shortName,
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
          ],
        ),
      ),
    );
  }
}
