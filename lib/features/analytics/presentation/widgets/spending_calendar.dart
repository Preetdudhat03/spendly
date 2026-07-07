import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';
import 'package:spendly/models/expense.dart';
import 'package:spendly/features/analytics/presentation/widgets/category_donut_chart.dart';

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
    if (amount > 2000) return Colors.white;
    return Colors.black87;
  }

  void _showDayExpenses(BuildContext context, DateTime date, double totalAmount) {
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFmt = DateFormat('EEEE, MMMM d, yyyy');

    // Filter all expenses for this specific day
    final dayExpenses = state.filteredExpenses.where((e) {
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
              Expanded(
                child: dayExpenses.isEmpty
                    ? const Center(child: Text('No expenses logged on this day.'))
                    : ListView.builder(
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
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    
    // Calculate calendar grid padding (days offset)
    // weekday is 1 (Mon) to 7 (Sun)
    final offset = firstDayOfMonth.weekday - 1;

    final List<Widget> gridItems = [];
    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    // Weekday headers
    for (var day in weekDays) {
      gridItems.add(
        Center(
          child: Text(
            day,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
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
          onTap: () => _showDayExpenses(context, date, amount),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: date.day == now.day
                  ? Border.all(color: Theme.of(context).primaryColor, width: 1.5)
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
                          color: textColor.withOpacity(0.8),
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
                      'Spending Calendar',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Daily expense map for ${DateFormat('MMMM yyyy').format(now)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                Icon(Icons.calendar_month, size: 20, color: Theme.of(context).primaryColor),
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
                Text('Intensity:', style: TextStyle(fontSize: 10.5, color: Colors.grey[500])),
                const SizedBox(width: 6),
                Container(width: 8, height: 8, decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.12), shape: BoxShape.circle)),
                const SizedBox(width: 3),
                Text('Under ₹500', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                const SizedBox(width: 10),
                Container(width: 8, height: 8, decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.45), shape: BoxShape.circle)),
                const SizedBox(width: 3),
                Text('₹500 - ₹2000', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                const SizedBox(width: 10),
                Container(width: 8, height: 8, decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle)),
                const SizedBox(width: 3),
                Text('Above ₹2000', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
