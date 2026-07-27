import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';
import 'package:spendly/models/expense.dart';
import 'package:spendly/features/analytics/presentation/widgets/category_donut_chart.dart';
import 'package:spendly/features/analytics/presentation/widgets/drill_down_sheet.dart';
class SpendingCalendar extends StatelessWidget {
  final AnalyticsState state;

  const SpendingCalendar({super.key, required this.state});

  Color _getDayIntensityColor(BuildContext context, double amount) {
    final primary = Theme.of(context).primaryColor;
    if (amount <= 0) return Colors.transparent;
    if (amount <= 500) return primary.withOpacity(0.12);
    if (amount <= 2000) return primary.withOpacity(0.45);
    return primary;
  }

  Color _getDayTextColor(BuildContext context, double amount) {
    final colorScheme = Theme.of(context).colorScheme;
    if (amount > 2000) return Colors.white;
    return colorScheme.onSurface;
  }

  void _showDayExpenses(BuildContext context, DateTime date, double totalAmount) {
    if (totalAmount <= 0) return;
    
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFmt = DateFormat('EEEE, MMMM d, yyyy');

    // Filter all expenses for this specific day
    final dayExpenses = state.filteredExpenses.where((e) {
      final d = e.expenseDate;
      return d.year == date.year && d.month == date.month && d.day == date.day;
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

    DrillDownSheet.show(
      context,
      title: dateFmt.format(date),
      subtitle: 'Daily transaction list',
      icon: Icons.calendar_today,
      color: Theme.of(context).colorScheme.primary,
      totalAmount: totalAmount,
      expenses: dayExpenses,
      aiSummary: 'You logged ${dayExpenses.length} transactions on this day.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    
    final offset = firstDayOfMonth.weekday - 1;

    final List<Widget> gridItems = [];
    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    // Weekday headers
    for (var day in weekDays) {
      gridItems.add(
        Center(
          child: Text(
            day,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // Padded cells before the first of the month
    for (int i = 0; i < offset; i++) {
      gridItems.add(Container());
    }

    // Days of the month
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(now.year, now.month, day);
      final amount = state.calendarData[date] ?? 0.0;
      final bgColor = _getDayIntensityColor(context, amount);
      final textColor = _getDayTextColor(context, amount);

      gridItems.add(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showDayExpenses(context, date, amount),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: bgColor == Colors.transparent ? colorScheme.surfaceContainerHigh.withOpacity(0.3) : bgColor,
              shape: BoxShape.circle,
              border: date.day == now.day
                  ? Border.all(color: colorScheme.primary, width: 1.5)
                  : null,
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                if (amount > 0)
                  Positioned(
                    bottom: 4,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        '₹${amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 6.5,
                          fontWeight: FontWeight.bold,
                          color: textColor.withOpacity(0.85),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

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
                      'Spending Calendar',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Daily expense map for ${DateFormat('MMMM yyyy').format(now)}',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                Icon(Icons.calendar_month, size: 20, color: colorScheme.primary),
              ],
            ),
            const SizedBox(height: 20),

            // Calendar Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: gridItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, idx) => gridItems[idx],
            ),
            const SizedBox(height: 12),

            // Legend indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Intensity:', style: TextStyle(fontSize: 10.5, color: colorScheme.onSurfaceVariant)),
                const SizedBox(width: 6),
                Container(width: 8, height: 8, decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.12), shape: BoxShape.circle)),
                const SizedBox(width: 3),
                Text('Under ₹500', style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant)),
                const SizedBox(width: 10),
                Container(width: 8, height: 8, decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.45), shape: BoxShape.circle)),
                const SizedBox(width: 3),
                Text('₹500 - ₹2000', style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant)),
                const SizedBox(width: 10),
                Container(width: 8, height: 8, decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle)),
                const SizedBox(width: 3),
                Text('Above ₹2000', style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
