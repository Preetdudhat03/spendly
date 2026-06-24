import 'package:intl/intl.dart';
import 'package:spendly/models/expense.dart';

class AiInsights {
  static List<String> generate(List<Expense> expenses, double budgetLimit) {
    final List<String> insights = [];
    if (expenses.isEmpty) {
      return ['Add some expenses to get AI Insights!'];
    }

    final now = DateTime.now();
    
    // 1. Current Month & Previous Month expense split
    final currentMonthExpenses = expenses.where((e) => e.expenseDate.year == now.year && e.expenseDate.month == now.month).toList();
    final prevMonthExpenses = expenses.where((e) {
      final prevMonth = now.month == 1 ? 12 : now.month - 1;
      final prevYear = now.month == 1 ? now.year - 1 : now.year;
      return e.expenseDate.year == prevYear && e.expenseDate.month == prevMonth;
    }).toList();

    final currentTotal = currentMonthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final prevTotal = prevMonthExpenses.fold<double>(0, (sum, e) => sum + e.amount);

    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Insight 1: Budget threshold check
    if (budgetLimit > 0) {
      final percent = currentTotal / budgetLimit;
      if (percent >= 0.9) {
        insights.add('⚠️ Budget warning: You have used ${(percent * 100).toStringAsFixed(0)}% of your monthly budget.');
      } else if (percent >= 0.7) {
        insights.add('💡 Budget notice: You have used ${(percent * 100).toStringAsFixed(0)}% of your monthly budget.');
      }
    }

    // Insight 2: Month on Month total comparison
    if (prevTotal > 0) {
      final diffPercent = ((currentTotal - prevTotal) / prevTotal) * 100;
      if (diffPercent > 0) {
        insights.add('📈 Your family spent ${diffPercent.toStringAsFixed(0)}% more this month compared to last month.');
      } else if (diffPercent < 0) {
        insights.add('📉 Your family spending decreased by ${diffPercent.abs().toStringAsFixed(0)}% compared to last month!');
      }
    }

    // Insight 3: Category level MoM comparison (specifically for Food / Fuel / Groceries)
    final Map<String, double> currentCats = {};
    for (var e in currentMonthExpenses) {
      currentCats[e.category] = (currentCats[e.category] ?? 0) + e.amount;
    }

    final Map<String, double> prevCats = {};
    for (var e in prevMonthExpenses) {
      prevCats[e.category] = (prevCats[e.category] ?? 0) + e.amount;
    }

    // Look for significant category change
    String? categoryWithIncrease;
    double largestCatIncrease = 0;
    
    currentCats.forEach((cat, amt) {
      final prevAmt = prevCats[cat] ?? 0;
      if (prevAmt > 0 && amt > prevAmt) {
        final increase = amt - prevAmt;
        if (increase > largestCatIncrease) {
          largestCatIncrease = increase;
          categoryWithIncrease = cat;
        }
      }
    });

    if (categoryWithIncrease != null) {
      insights.add('💸 $categoryWithIncrease expenses increased by ${currencyFormat.format(largestCatIncrease)} this month.');
    }

    // Insight 4: Most expensive day of the week
    final Map<int, double> dayOfWeekSpending = {};
    for (var e in currentMonthExpenses) {
      final day = e.expenseDate.weekday;
      dayOfWeekSpending[day] = (dayOfWeekSpending[day] ?? 0) + e.amount;
    }

    if (dayOfWeekSpending.isNotEmpty) {
      var peakDay = 1;
      var peakSpending = 0.0;
      dayOfWeekSpending.forEach((day, spending) {
        if (spending > peakSpending) {
          peakSpending = spending;
          peakDay = day;
        }
      });
      
      final weekdayName = _getWeekdayName(peakDay);
      insights.add('📅 Your highest spending day this month was $weekdayName.');
    }

    // Insight 5: Payment method preference
    final Map<String, int> paymentCounts = {};
    for (var e in currentMonthExpenses) {
      paymentCounts[e.paymentMethod] = (paymentCounts[e.paymentMethod] ?? 0) + 1;
    }

    if (paymentCounts.isNotEmpty) {
      var preferredMethod = 'UPI';
      var maxCount = 0;
      paymentCounts.forEach((method, count) {
        if (count > maxCount) {
          maxCount = count;
          preferredMethod = method;
        }
      });
      insights.add('💳 ${preferredMethod.toUpperCase()} is your family\'s preferred payment method.');
    }

    // Fallback if list is too short
    if (insights.isEmpty) {
      insights.add('✨ Keep logging expenses to see detailed monthly comparisons!');
    }

    return insights;
  }

  static String _getWeekdayName(int day) {
    switch (day) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Sunday';
    }
  }
}
