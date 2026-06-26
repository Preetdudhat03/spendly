import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';

class SpendingTrendChart extends StatelessWidget {
  final AnalyticsState state;

  const SpendingTrendChart({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.trendSpots.isEmpty) {
      return const SizedBox.shrink();
    }

    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFmt = DateFormat('MMM d');

    // Find min and max for chart styling
    double maxAmount = 1000;
    for (var spot in state.trendSpots) {
      maxAmount = max(maxAmount, spot.cumulativeAmount);
    }
    for (var spot in state.prevTrendSpots) {
      maxAmount = max(maxAmount, spot.cumulativeAmount);
    }
    // Add 15% padding on top
    maxAmount = maxAmount * 1.15;

    // Build fl spots
    final List<FlSpot> currentSpots = [];
    for (int i = 0; i < state.trendSpots.length; i++) {
      currentSpots.add(FlSpot(i.toDouble(), state.trendSpots[i].cumulativeAmount));
    }

    final List<FlSpot> prevSpots = [];
    for (int i = 0; i < state.prevTrendSpots.length; i++) {
      prevSpots.add(FlSpot(i.toDouble(), state.prevTrendSpots[i].cumulativeAmount));
    }

    // Daily stats calculations
    double highestDayAmount = 0.0;
    DateTime? highestDayDate;
    double lowestDayAmount = double.infinity;
    DateTime? lowestDayDate;

    for (var spot in state.trendSpots) {
      if (spot.amount > highestDayAmount) {
        highestDayAmount = spot.amount;
        highestDayDate = spot.date;
      }
      if (spot.amount < lowestDayAmount && spot.amount > 0) {
        lowestDayAmount = spot.amount;
        lowestDayDate = spot.date;
      }
    }
    if (lowestDayAmount == double.infinity) {
      lowestDayAmount = 0.0;
    }

    // Responsive width based on data count to allow horizontal scrolling
    final screenWidth = MediaQuery.of(context).size.width;
    final chartContentWidth = max(screenWidth - 48, state.trendSpots.length * 36.0);

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
            // Chart Title & Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spending Trend',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cumulative spending trajectory',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                // Legend indicators
                Row(
                  children: [
                    _buildLegendItem(context, 'This Period', Theme.of(context).primaryColor, false),
                    const SizedBox(width: 12),
                    if (prevSpots.isNotEmpty)
                      _buildLegendItem(context, 'Last Period', Colors.grey[400]!, true),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Interactive Chart Area with scroll
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: chartContentWidth,
                height: 220,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: const Color(0xFFF1F5F9),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: max(1.0, (state.trendSpots.length / 6).floorToDouble()),
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx >= 0 && idx < state.trendSpots.length) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  dateFmt.format(state.trendSpots[idx].date),
                                  style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: max(100.0, (maxAmount / 4).roundToDouble()),
                          reservedSize: 42,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox.shrink();
                            String formatted = '';
                            if (value >= 1000) {
                              formatted = '₹${(value / 1000).toStringAsFixed(1)}k';
                            } else {
                              formatted = '₹${value.toStringAsFixed(0)}';
                            }
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                formatted,
                                style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (state.trendSpots.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxAmount,
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => Colors.black.withOpacity(0.85),
                        tooltipRoundedRadius: 12,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((barSpot) {
                            final idx = barSpot.x.toInt();
                            final isPrev = barSpot.barIndex == 1;
                            
                            DateTime date;
                            double totalAmt;
                            double dailyAmt;

                            if (isPrev) {
                              if (idx >= 0 && idx < state.prevTrendSpots.length) {
                                date = state.prevTrendSpots[idx].date;
                                totalAmt = state.prevTrendSpots[idx].cumulativeAmount;
                                dailyAmt = state.prevTrendSpots[idx].amount;
                              } else {
                                return null;
                              }
                            } else {
                              if (idx >= 0 && idx < state.trendSpots.length) {
                                date = state.trendSpots[idx].date;
                                totalAmt = state.trendSpots[idx].cumulativeAmount;
                                dailyAmt = state.trendSpots[idx].amount;
                              } else {
                                return null;
                              }
                            }

                            final title = isPrev ? 'Last Period' : 'This Period';
                            return LineTooltipItem(
                              '$title\n${dateFmt.format(date)}\nCum: ${currencyFmt.format(totalAmt)}\nDaily: ${currencyFmt.format(dailyAmt)}',
                              const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      // 1. Current Period Line
                      LineChartBarData(
                        spots: currentSpots,
                        isCurved: true,
                        color: Theme.of(context).primaryColor,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor.withOpacity(0.16),
                              Theme.of(context).primaryColor.withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      // 2. Previous Period Dotted Line
                      if (prevSpots.isNotEmpty)
                        LineChartBarData(
                          spots: prevSpots,
                          isCurved: true,
                          color: Colors.grey[400],
                          barWidth: 2,
                          dashArray: [6, 6],
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        ),
                    ],
                  ),
                  duration: const Duration(milliseconds: 250),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            
            // Statistics Grid below
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                return GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isNarrow ? 2 : 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 8,
                    childAspectRatio: isNarrow ? 1.8 : 1.3,
                  ),
                  children: [
                    _buildStatItem(
                      context,
                      label: 'Highest Spend Day',
                      value: highestDayAmount > 0 ? currencyFmt.format(highestDayAmount) : '₹0',
                      subtext: highestDayDate != null ? dateFmt.format(highestDayDate) : '-',
                    ),
                    _buildStatItem(
                      context,
                      label: 'Lowest Spend Day',
                      value: lowestDayAmount > 0 ? currencyFmt.format(lowestDayAmount) : '₹0',
                      subtext: lowestDayDate != null ? dateFmt.format(lowestDayDate) : '-',
                    ),
                    _buildStatItem(
                      context,
                      label: 'Daily Average',
                      value: currencyFmt.format(state.dailyAverage),
                      subtext: 'Across filter range',
                    ),
                    _buildStatItem(
                      context,
                      label: 'Expense Entries',
                      value: '${state.totalTransactions}',
                      subtext: 'Logged logs',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color, bool isDotted) {
    return Row(
      children: [
        if (isDotted)
          Row(
            children: List.generate(
              3,
              (i) => Container(
                width: 4,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                color: color,
              ),
            ),
          )
        else
          Container(
            width: 12,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, {required String label, required String value, required String subtext}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtext,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}
