import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/utils/ai_insights.dart';
import 'package:spendly/models/expense.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseState = ref.watch(expenseProvider);
    final budgetState = ref.watch(budgetProvider);

    final now = DateTime.now();
    final currentMonthExpenses = expenseState.expenses.where((e) {
      return e.expenseDate.year == now.year && e.expenseDate.month == now.month;
    }).toList();

    final monthTotal = currentMonthExpenses.fold<double>(0, (sum, item) => sum + item.amount);
    final budgetLimit = budgetState.currentBudget?.monthlyBudget ?? 20000.0;

    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // AI Insights
    final insights = AiInsights.generate(expenseState.expenses, budgetLimit);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Analytics'),
      ),
      body: expenseState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : currentMonthExpenses.isEmpty
              ? _buildEmptyState(context)
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overview total
                      _buildMonthOverviewCard(context, monthTotal, currencyFormat),
                      const SizedBox(height: 24),

                      // Category Breakdown Pie Chart
                      Text('Category Breakdown', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      _buildCategoryBreakdownCard(context, currentMonthExpenses, monthTotal),
                      const SizedBox(height: 24),

                      // Spending Trend Line Chart
                      Text('Spending Trend', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      _buildTrendLineChartCard(context, currentMonthExpenses),
                      const SizedBox(height: 24),

                      // Highest Category Card
                      _buildHighestCategoryCard(context, currentMonthExpenses, currencyFormat),
                      const SizedBox(height: 24),

                      // Family Member Contributions
                      Text('Contributions', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      _buildMemberContributionsCard(context, currentMonthExpenses, currencyFormat),
                      const SizedBox(height: 24),

                      // AI Insights Card
                      Text('AI Insights', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      _buildAiInsightsCard(context, insights),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No expenses logged this month yet.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Once family members log expenses, charts and insights will automatically generate here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthOverviewCard(BuildContext context, double total, NumberFormat fmt) {
    return Card(
      color: Theme.of(context).primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Spent This Month',
                  style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 6),
                Text(
                  'Monthly Summary',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            Text(
              fmt.format(total),
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdownCard(BuildContext context, List<Expense> expenses, double total) {
    final Map<String, double> catTotals = {};
    for (var e in expenses) {
      catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amount;
    }

    final sortedCats = catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final List<PieChartSectionData> sections = [];
    for (int i = 0; i < sortedCats.length; i++) {
      final entry = sortedCats[i];
      final percent = (entry.value / total) * 100;
      sections.add(
        PieChartSectionData(
          color: _getCategoryColor(entry.key),
          value: entry.value,
          title: '${percent.toStringAsFixed(0)}%',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedCats.length,
              itemBuilder: (context, index) {
                final entry = sortedCats[index];
                final col = _getCategoryColor(entry.key);
                final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        currencyFormat.format(entry.value),
                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
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
  }

  Widget _buildTrendLineChartCard(BuildContext context, List<Expense> expenses) {
    // Group spending by day
    final Map<int, double> dailySpending = {};
    for (var e in expenses) {
      final day = e.expenseDate.day;
      dailySpending[day] = (dailySpending[day] ?? 0) + e.amount;
    }

    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final List<FlSpot> spots = [];

    double cumulative = 0;
    for (int day = 1; day <= daysInMonth; day++) {
      cumulative += dailySpending[day] ?? 0.0;
      spots.add(FlSpot(day.toDouble(), cumulative));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.only(top: 24.0, right: 24.0, left: 12.0, bottom: 12.0),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 5000,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: const Color(0xFFE2E8F0),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 7,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          'Day ${value.toInt()}',
                          style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 10000,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          '₹${(value / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Theme.of(context).primaryColor,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(context).primaryColor.withOpacity(0.15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHighestCategoryCard(BuildContext context, List<Expense> expenses, NumberFormat fmt) {
    final Map<String, double> catTotals = {};
    for (var e in expenses) {
      catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amount;
    }

    if (catTotals.isEmpty) return const SizedBox.shrink();

    final highestEntry = catTotals.entries.reduce((a, b) => a.value > b.value ? a : b);

    return Card(
      color: const Color(0xFFFEE2E2), // Soft pink-red background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
              child: const Icon(Icons.trending_up, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Highest Spending Category',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF991B1B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    highestEntry.key,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF7F1D1D)),
                  ),
                ],
              ),
            ),
            Text(
              fmt.format(highestEntry.value),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF7F1D1D)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMemberContributionsCard(BuildContext context, List<Expense> expenses, NumberFormat fmt) {
    final Map<String, double> memberTotals = {};
    final Map<String, String> memberNames = {};
    for (var e in expenses) {
      memberTotals[e.createdBy] = (memberTotals[e.createdBy] ?? 0) + e.amount;
      memberNames[e.createdBy] = e.createdByName;
    }

    final totalSpent = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final sortedMembers = memberTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: sortedMembers.map((entry) {
            final name = memberNames[entry.key] ?? 'Member';
            final percent = totalSpent > 0 ? entry.value / totalSpent : 0.0;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        '${fmt.format(entry.value)} (${(percent * 100).toStringAsFixed(0)}%)',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                      )
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 8,
                      color: Theme.of(context).primaryColor,
                      backgroundColor: const Color(0xFFE2E8F0),
                    ),
                  )
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAiInsightsCard(BuildContext context, List<String> insights) {
    return Card(
      color: const Color(0xFFEFF6FF), // Soft blue background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFDBEAFE)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: insights.map((insight) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1D4ED8))),
                  Expanded(
                    child: Text(
                      insight,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: Color(0xFF1E3A8A)),
                    ),
                  )
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFF59E0B); // Amber/Orange
      case 'groceries':
        return const Color(0xFF10B981); // Emerald/Green
      case 'petrol':
      case 'fuel':
        return const Color(0xFF3B82F6); // Blue
      case 'recharges':
        return const Color(0xFF06B6D4); // Cyan
      case 'travel':
        return const Color(0xFF14B8A6); // Teal
      case 'gas':
        return const Color(0xFFF97316); // Orange
      case 'electricity':
      case 'utility':
        return const Color(0xFF8B5CF6); // Purple
      case 'medical':
        return const Color(0xFFEF4444); // Red
      case 'insurances':
        return const Color(0xFF4F46E5); // Indigo
      case 'shopping':
        return const Color(0xFFEC4899); // Pink
      case 'rent':
        return const Color(0xFF78350F); // Brown
      case 'entertainment':
        return const Color(0xFFF43F5E); // Rose
      case 'education':
        return const Color(0xFF636AE8); // Violet
      default:
        return const Color(0xFF64748B); // Slate
    }
  }
}
