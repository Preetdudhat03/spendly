import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/models/expense.dart';

enum AnalyticsFilterType {
  today,
  last7Days,
  thisMonth,
  lastMonth,
  last3Months,
  last6Months,
  thisYear,
  customDate,
}

class CategoryShare {
  final String category;
  final double amount;
  final double percentage;
  final double prevAmount;
  final double diffPercent;
  final bool isIncrease;

  CategoryShare({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.prevAmount,
    required this.diffPercent,
    required this.isIncrease,
  });
}

class MemberShare {
  final String memberId;
  final String name;
  final double totalSpent;
  final int count;
  final double average;
  final double largest;

  MemberShare({
    required this.memberId,
    required this.name,
    required this.totalSpent,
    required this.count,
    required this.average,
    required this.largest,
  });
}

class PaymentMethodShare {
  final String method;
  final double amount;
  final double percentage;
  final int count;

  PaymentMethodShare({
    required this.method,
    required this.amount,
    required this.percentage,
    required this.count,
  });
}

class TrendPoint {
  final DateTime date;
  final double amount;
  final double cumulativeAmount;

  TrendPoint({
    required this.date,
    required this.amount,
    required this.cumulativeAmount,
  });
}

class RecurringExpenseInfo {
  final String title;
  final String category;
  final double amount;
  final String frequency;
  final DateTime nextExpectedDate;

  RecurringExpenseInfo({
    required this.title,
    required this.category,
    required this.amount,
    required this.frequency,
    required this.nextExpectedDate,
  });
}

class AnalyticsState {
  final AnalyticsFilterType filterType;
  final DateTimeRange dateRange;
  final DateTimeRange previousDateRange;
  final List<Expense> filteredExpenses;
  final List<Expense> previousExpenses;
  final bool isLoading;

  // Summary Cards
  final double totalSpent;
  final double prevTotalSpent;
  final double totalSpentDiffPercent;
  final double dailyAverage;
  final double prevDailyAverage;
  final double dailyAverageDiffPercent;
  final int totalTransactions;
  final int prevTotalTransactions;
  final int activeMembersCount;
  final double budgetRemaining;
  final double budgetProgressPercent; // 0.0 to 1.0
  final double budgetLimit;

  // Breakdowns & Graphs
  final List<CategoryShare> categoryShares;
  final List<MemberShare> memberShares;
  final List<PaymentMethodShare> paymentMethodShares;
  final List<Expense> topExpenses;
  final Map<DateTime, double> heatmapData; // for weekly heatmap
  final Map<DateTime, double> calendarData; // for monthly calendar view
  final List<TrendPoint> trendSpots;
  final List<TrendPoint> prevTrendSpots;

  // Smart Patterns & AI Insights
  final double weekendAvg;
  final double weekdayAvg;
  final double weekendOverspendPercent;
  final List<RecurringExpenseInfo> recurringExpenses;
  final List<String> savingsOpportunities;
  final int financialHealthScore;
  final String healthScoreLabel;
  final List<String> aiInsights;
  final List<String> aiRecommendations;
  final Map<String, int> timeOfDayCounts;
  final Map<String, double> timeOfDayAmounts;

  AnalyticsState({
    required this.filterType,
    required this.dateRange,
    required this.previousDateRange,
    required this.filteredExpenses,
    required this.previousExpenses,
    required this.isLoading,
    required this.totalSpent,
    required this.prevTotalSpent,
    required this.totalSpentDiffPercent,
    required this.dailyAverage,
    required this.prevDailyAverage,
    required this.dailyAverageDiffPercent,
    required this.totalTransactions,
    required this.prevTotalTransactions,
    required this.activeMembersCount,
    required this.budgetRemaining,
    required this.budgetProgressPercent,
    required this.budgetLimit,
    required this.categoryShares,
    required this.memberShares,
    required this.paymentMethodShares,
    required this.topExpenses,
    required this.heatmapData,
    required this.calendarData,
    required this.trendSpots,
    required this.prevTrendSpots,
    required this.weekendAvg,
    required this.weekdayAvg,
    required this.weekendOverspendPercent,
    required this.recurringExpenses,
    required this.savingsOpportunities,
    required this.financialHealthScore,
    required this.healthScoreLabel,
    required this.aiInsights,
    required this.aiRecommendations,
    required this.timeOfDayCounts,
    required this.timeOfDayAmounts,
  });

  factory AnalyticsState.initial(DateTimeRange range, DateTimeRange prevRange) {
    return AnalyticsState(
      filterType: AnalyticsFilterType.thisMonth,
      dateRange: range,
      previousDateRange: prevRange,
      filteredExpenses: [],
      previousExpenses: [],
      isLoading: false,
      totalSpent: 0,
      prevTotalSpent: 0,
      totalSpentDiffPercent: 0,
      dailyAverage: 0,
      prevDailyAverage: 0,
      dailyAverageDiffPercent: 0,
      totalTransactions: 0,
      prevTotalTransactions: 0,
      activeMembersCount: 0,
      budgetRemaining: 0,
      budgetProgressPercent: 0,
      budgetLimit: 0,
      categoryShares: [],
      memberShares: [],
      paymentMethodShares: [],
      topExpenses: [],
      heatmapData: {},
      calendarData: {},
      trendSpots: [],
      prevTrendSpots: [],
      weekendAvg: 0,
      weekdayAvg: 0,
      weekendOverspendPercent: 0,
      recurringExpenses: [],
      savingsOpportunities: [],
      financialHealthScore: 100,
      healthScoreLabel: 'Excellent',
      aiInsights: [],
      aiRecommendations: [],
      timeOfDayCounts: const {},
      timeOfDayAmounts: const {},
    );
  }

  AnalyticsState copyWith({
    AnalyticsFilterType? filterType,
    DateTimeRange? dateRange,
    DateTimeRange? previousDateRange,
    List<Expense>? filteredExpenses,
    List<Expense>? previousExpenses,
    bool? isLoading,
    double? totalSpent,
    double? prevTotalSpent,
    double? totalSpentDiffPercent,
    double? dailyAverage,
    double? prevDailyAverage,
    double? dailyAverageDiffPercent,
    int? totalTransactions,
    int? prevTotalTransactions,
    int? activeMembersCount,
    double? budgetRemaining,
    double? budgetProgressPercent,
    double? budgetLimit,
    List<CategoryShare>? categoryShares,
    List<MemberShare>? memberShares,
    List<PaymentMethodShare>? paymentMethodShares,
    List<Expense>? topExpenses,
    Map<DateTime, double>? heatmapData,
    Map<DateTime, double>? calendarData,
    List<TrendPoint>? trendSpots,
    List<TrendPoint>? prevTrendSpots,
    double? weekendAvg,
    double? weekdayAvg,
    double? weekendOverspendPercent,
    List<RecurringExpenseInfo>? recurringExpenses,
    List<String>? savingsOpportunities,
    int? financialHealthScore,
    String? healthScoreLabel,
    List<String>? aiInsights,
    List<String>? aiRecommendations,
    Map<String, int>? timeOfDayCounts,
    Map<String, double>? timeOfDayAmounts,
  }) {
    return AnalyticsState(
      filterType: filterType ?? this.filterType,
      dateRange: dateRange ?? this.dateRange,
      previousDateRange: previousDateRange ?? this.previousDateRange,
      filteredExpenses: filteredExpenses ?? this.filteredExpenses,
      previousExpenses: previousExpenses ?? this.previousExpenses,
      isLoading: isLoading ?? this.isLoading,
      totalSpent: totalSpent ?? this.totalSpent,
      prevTotalSpent: prevTotalSpent ?? this.prevTotalSpent,
      totalSpentDiffPercent: totalSpentDiffPercent ?? this.totalSpentDiffPercent,
      dailyAverage: dailyAverage ?? this.dailyAverage,
      prevDailyAverage: prevDailyAverage ?? this.prevDailyAverage,
      dailyAverageDiffPercent: dailyAverageDiffPercent ?? this.dailyAverageDiffPercent,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      prevTotalTransactions: prevTotalTransactions ?? this.prevTotalTransactions,
      activeMembersCount: activeMembersCount ?? this.activeMembersCount,
      budgetRemaining: budgetRemaining ?? this.budgetRemaining,
      budgetProgressPercent: budgetProgressPercent ?? this.budgetProgressPercent,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      categoryShares: categoryShares ?? this.categoryShares,
      memberShares: memberShares ?? this.memberShares,
      paymentMethodShares: paymentMethodShares ?? this.paymentMethodShares,
      topExpenses: topExpenses ?? this.topExpenses,
      heatmapData: heatmapData ?? this.heatmapData,
      calendarData: calendarData ?? this.calendarData,
      trendSpots: trendSpots ?? this.trendSpots,
      prevTrendSpots: prevTrendSpots ?? this.prevTrendSpots,
      weekendAvg: weekendAvg ?? this.weekendAvg,
      weekdayAvg: weekdayAvg ?? this.weekdayAvg,
      weekendOverspendPercent: weekendOverspendPercent ?? this.weekendOverspendPercent,
      recurringExpenses: recurringExpenses ?? this.recurringExpenses,
      savingsOpportunities: savingsOpportunities ?? this.savingsOpportunities,
      financialHealthScore: financialHealthScore ?? this.financialHealthScore,
      healthScoreLabel: healthScoreLabel ?? this.healthScoreLabel,
      aiInsights: aiInsights ?? this.aiInsights,
      aiRecommendations: aiRecommendations ?? this.aiRecommendations,
      timeOfDayCounts: timeOfDayCounts ?? this.timeOfDayCounts,
      timeOfDayAmounts: timeOfDayAmounts ?? this.timeOfDayAmounts,
    );
  }
}

// Active Filter Type State Provider
final analyticsFilterTypeProvider = StateProvider<AnalyticsFilterType>((ref) {
  return AnalyticsFilterType.thisMonth;
});

// Custom Date Range State Provider
final analyticsCustomDateRangeProvider = StateProvider<DateTimeRange?>((ref) {
  return null;
});

// Primary Analytics Calculations Provider
final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  final expenseState = ref.watch(expenseProvider);
  final budgetState = ref.watch(budgetProvider);
  final familyState = ref.watch(familyProvider);
  final filterType = ref.watch(analyticsFilterTypeProvider);
  final customRange = ref.watch(analyticsCustomDateRangeProvider);

  return AnalyticsNotifier(
    expenseState: expenseState,
    budgetState: budgetState,
    familyState: familyState,
    filterType: filterType,
    customRange: customRange,
  );
});

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  AnalyticsNotifier({
    required ExpenseState expenseState,
    required BudgetState budgetState,
    required FamilyState familyState,
    required AnalyticsFilterType filterType,
    required DateTimeRange? customRange,
  }) : super(AnalyticsNotifier._createInitialState(filterType, customRange)) {
    _calculate(expenseState, budgetState, familyState, filterType, customRange);
  }

  static AnalyticsState _createInitialState(AnalyticsFilterType filterType, DateTimeRange? customRange) {
    final ranges = _calculateDateRanges(filterType, customRange);
    return AnalyticsState.initial(ranges[0], ranges[1]);
  }

  static List<DateTimeRange> _calculateDateRanges(AnalyticsFilterType filterType, DateTimeRange? customRange) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;
    DateTime prevStart;
    DateTime prevEnd;

    switch (filterType) {
      case AnalyticsFilterType.today:
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        prevStart = start.subtract(const Duration(days: 1));
        prevEnd = end.subtract(const Duration(days: 1));
        break;
      case AnalyticsFilterType.last7Days:
        start = DateUtils.dateOnly(now.subtract(const Duration(days: 6)));
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        prevStart = start.subtract(const Duration(days: 7));
        prevEnd = start.subtract(const Duration(seconds: 1));
        break;
      case AnalyticsFilterType.thisMonth:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month, DateUtils.getDaysInMonth(now.year, now.month), 23, 59, 59);
        final lastMonthDate = DateTime(now.year, now.month - 1, 1);
        prevStart = DateTime(lastMonthDate.year, lastMonthDate.month, 1);
        prevEnd = DateTime(lastMonthDate.year, lastMonthDate.month, DateUtils.getDaysInMonth(lastMonthDate.year, lastMonthDate.month), 23, 59, 59);
        break;
      case AnalyticsFilterType.lastMonth:
        final lastMonthDate = DateTime(now.year, now.month - 1, 1);
        start = DateTime(lastMonthDate.year, lastMonthDate.month, 1);
        end = DateTime(lastMonthDate.year, lastMonthDate.month, DateUtils.getDaysInMonth(lastMonthDate.year, lastMonthDate.month), 23, 59, 59);
        
        final twoMonthsAgoDate = DateTime(now.year, now.month - 2, 1);
        prevStart = DateTime(twoMonthsAgoDate.year, twoMonthsAgoDate.month, 1);
        prevEnd = DateTime(twoMonthsAgoDate.year, twoMonthsAgoDate.month, DateUtils.getDaysInMonth(twoMonthsAgoDate.year, twoMonthsAgoDate.month), 23, 59, 59);
        break;
      case AnalyticsFilterType.last3Months:
        start = DateUtils.dateOnly(now.subtract(const Duration(days: 89)));
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        prevStart = start.subtract(const Duration(days: 90));
        prevEnd = start.subtract(const Duration(seconds: 1));
        break;
      case AnalyticsFilterType.last6Months:
        start = DateUtils.dateOnly(now.subtract(const Duration(days: 179)));
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        prevStart = start.subtract(const Duration(days: 180));
        prevEnd = start.subtract(const Duration(seconds: 1));
        break;
      case AnalyticsFilterType.thisYear:
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
        prevStart = DateTime(now.year - 1, 1, 1);
        prevEnd = DateTime(now.year - 1, 12, 31, 23, 59, 59);
        break;
      case AnalyticsFilterType.customDate:
        if (customRange != null) {
          start = DateUtils.dateOnly(customRange.start);
          end = DateTime(customRange.end.year, customRange.end.month, customRange.end.day, 23, 59, 59);
          final diff = end.difference(start);
          prevStart = start.subtract(diff);
          prevEnd = start.subtract(const Duration(seconds: 1));
        } else {
          start = DateTime(now.year, now.month, 1);
          end = DateTime(now.year, now.month, DateUtils.getDaysInMonth(now.year, now.month), 23, 59, 59);
          final lastMonthDate = DateTime(now.year, now.month - 1, 1);
          prevStart = DateTime(lastMonthDate.year, lastMonthDate.month, 1);
          prevEnd = DateTime(lastMonthDate.year, lastMonthDate.month, DateUtils.getDaysInMonth(lastMonthDate.year, lastMonthDate.month), 23, 59, 59);
        }
        break;
    }

    return [
      DateTimeRange(start: start, end: end),
      DateTimeRange(start: prevStart, end: prevEnd)
    ];
  }

  void _calculate(
    ExpenseState expenseState,
    BudgetState budgetState,
    FamilyState familyState,
    AnalyticsFilterType filterType,
    DateTimeRange? customRange,
  ) {
    if (expenseState.isLoading) {
      state = state.copyWith(isLoading: true);
      return;
    }

    final now = DateTime.now();
    final ranges = _calculateDateRanges(filterType, customRange);
    final currentRange = ranges[0];
    final prevRange = ranges[1];

    final allExpenses = expenseState.expenses;

    // Filter current expenses
    final filteredExpenses = allExpenses.where((e) {
      return e.expenseDate.isAfter(currentRange.start.subtract(const Duration(seconds: 1))) &&
          e.expenseDate.isBefore(currentRange.end.add(const Duration(seconds: 1)));
    }).toList();

    // Filter previous expenses
    final previousExpenses = allExpenses.where((e) {
      return e.expenseDate.isAfter(prevRange.start.subtract(const Duration(seconds: 1))) &&
          e.expenseDate.isBefore(prevRange.end.add(const Duration(seconds: 1)));
    }).toList();

    // 1. Total spent sums
    final totalSpent = filteredExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final prevTotalSpent = previousExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    
    double totalSpentDiffPercent = 0.0;
    if (prevTotalSpent > 0) {
      totalSpentDiffPercent = ((totalSpent - prevTotalSpent) / prevTotalSpent) * 100;
    } else if (totalSpent > 0) {
      totalSpentDiffPercent = 100.0;
    }

    // 2. Daily average
    final currentDays = max(1, currentRange.end.difference(currentRange.start).inDays + 1);
    final prevDays = max(1, prevRange.end.difference(prevRange.start).inDays + 1);
    
    double dailyAverage = 0.0;
    if (filterType == AnalyticsFilterType.thisMonth && currentRange.start.month == DateTime.now().month && currentRange.start.year == DateTime.now().year) {
      final daysElapsed = max(1, DateTime.now().day);
      dailyAverage = totalSpent / daysElapsed;
    } else {
      dailyAverage = totalSpent / currentDays;
    }

    double prevDailyAverage = prevTotalSpent / prevDays;
    double dailyAverageDiffPercent = 0.0;
    if (prevDailyAverage > 0) {
      dailyAverageDiffPercent = ((dailyAverage - prevDailyAverage) / prevDailyAverage) * 100;
    } else if (dailyAverage > 0) {
      dailyAverageDiffPercent = 100.0;
    }

    // 3. Transactions count
    final totalTransactions = filteredExpenses.length;
    final prevTotalTransactions = previousExpenses.length;

    // 4. Budget progress
    final budgetLimit = budgetState.currentBudget?.monthlyBudget ?? 20000.0;
    final budgetRemaining = max(0.0, budgetLimit - totalSpent);
    double budgetProgressPercent = budgetLimit > 0 ? (totalSpent / budgetLimit) : 0.0;
    if (budgetProgressPercent > 1.0) budgetProgressPercent = 1.0;

    // 5. Active Members
    final activeMembersCount = familyState.members.isEmpty ? 1 : familyState.members.length;

    // 6. Category breakdown
    final Map<String, double> currentCatTotals = {};
    for (var e in filteredExpenses) {
      currentCatTotals[e.category] = (currentCatTotals[e.category] ?? 0) + e.amount;
    }
    final Map<String, double> prevCatTotals = {};
    for (var e in previousExpenses) {
      prevCatTotals[e.category] = (prevCatTotals[e.category] ?? 0) + e.amount;
    }

    final categoryShares = currentCatTotals.entries.map((entry) {
      final category = entry.key;
      final amount = entry.value;
      final percentage = totalSpent > 0 ? (amount / totalSpent) * 100 : 0.0;
      final prevAmount = prevCatTotals[category] ?? 0.0;
      
      double diffPercent = 0.0;
      if (prevAmount > 0) {
        diffPercent = ((amount - prevAmount) / prevAmount) * 100;
      } else if (amount > 0) {
        diffPercent = 100.0;
      }

      return CategoryShare(
        category: category,
        amount: amount,
        percentage: percentage,
        prevAmount: prevAmount,
        diffPercent: diffPercent.abs(),
        isIncrease: amount >= prevAmount,
      );
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

    // 7. Member breakdown
    final Map<String, List<Expense>> currentMemberExpenses = {};
    for (var e in filteredExpenses) {
      currentMemberExpenses.putIfAbsent(e.createdBy, () => []).add(e);
    }
    final Map<String, String> memberIdToName = {
      for (var m in familyState.members) m.userId: m.displayName
    };

    final memberShares = currentMemberExpenses.entries.map((entry) {
      final memberId = entry.key;
      final list = entry.value;
      final name = memberIdToName[memberId] ?? list.first.createdByName;
      final mTotal = list.fold<double>(0, (sum, e) => sum + e.amount);
      final mCount = list.length;
      final mAverage = mTotal / mCount;
      final mLargest = list.fold<double>(0, (maxVal, e) => max(maxVal, e.amount));

      return MemberShare(
        memberId: memberId,
        name: name,
        totalSpent: mTotal,
        count: mCount,
        average: mAverage,
        largest: mLargest,
      );
    }).toList()..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

    // 8. Payment Method breakdown
    final Map<String, List<Expense>> paymentExpenses = {};
    for (var e in filteredExpenses) {
      paymentExpenses.putIfAbsent(e.paymentMethod, () => []).add(e);
    }
    final paymentMethodShares = paymentExpenses.entries.map((entry) {
      final method = entry.key;
      final list = entry.value;
      final amt = list.fold<double>(0, (sum, e) => sum + e.amount);
      final percentage = totalSpent > 0 ? (amt / totalSpent) * 100 : 0.0;

      return PaymentMethodShare(
        method: method,
        amount: amt,
        percentage: percentage,
        count: list.length,
      );
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

    // 9. Top Expenses
    final topExpenses = List<Expense>.from(filteredExpenses)
      ..sort((a, b) => b.amount.compareTo(a.amount));
    if (topExpenses.length > 10) {
      topExpenses.removeRange(10, topExpenses.length);
    }

    // 10. Heatmap Data (Rolling 12 weeks of daily totals)
    final heatmapData = <DateTime, double>{};
    final todayOnly = DateUtils.dateOnly(DateTime.now());
    final startOfHeatmap = todayOnly.subtract(Duration(days: 84 - (todayOnly.weekday - 1)));
    for (int i = 0; i < 84; i++) {
      final day = startOfHeatmap.add(Duration(days: i));
      heatmapData[day] = 0.0;
    }
    for (var e in allExpenses) {
      final dateOnly = DateUtils.dateOnly(e.expenseDate);
      if (heatmapData.containsKey(dateOnly)) {
        heatmapData[dateOnly] = heatmapData[dateOnly]! + e.amount;
      }
    }

    // 11. Calendar Data (For monthly view)
    final calendarData = <DateTime, double>{};
    final calMonthEnd = DateTime(now.year, now.month, DateUtils.getDaysInMonth(now.year, now.month));
    for (int d = 1; d <= calMonthEnd.day; d++) {
      calendarData[DateTime(now.year, now.month, d)] = 0.0;
    }
    for (var e in allExpenses) {
      final dateOnly = DateUtils.dateOnly(e.expenseDate);
      if (dateOnly.year == now.year && dateOnly.month == now.month) {
        calendarData[dateOnly] = (calendarData[dateOnly] ?? 0.0) + e.amount;
      }
    }

    // 12. Trend Spots (Current Period vs Previous Period)
    final List<TrendPoint> trendSpots = [];
    final List<TrendPoint> prevTrendSpots = [];

    // Setup date steps for current period
    final currentDates = <DateTime>[];
    for (int i = 0; i < currentDays; i++) {
      currentDates.add(currentRange.start.add(Duration(days: i)));
    }
    final Map<DateTime, double> currentDailySum = {
      for (var d in currentDates) DateUtils.dateOnly(d): 0.0
    };
    for (var e in filteredExpenses) {
      final dateOnly = DateUtils.dateOnly(e.expenseDate);
      if (currentDailySum.containsKey(dateOnly)) {
        currentDailySum[dateOnly] = currentDailySum[dateOnly]! + e.amount;
      }
    }
    double currentCum = 0.0;
    for (var d in currentDates) {
      final dateOnly = DateUtils.dateOnly(d);
      final amt = currentDailySum[dateOnly] ?? 0.0;
      currentCum += amt;
      trendSpots.add(TrendPoint(date: dateOnly, amount: amt, cumulativeAmount: currentCum));
    }

    // Setup date steps for previous period
    final prevDates = <DateTime>[];
    for (int i = 0; i < prevDays; i++) {
      prevDates.add(prevRange.start.add(Duration(days: i)));
    }
    final Map<DateTime, double> prevDailySum = {
      for (var d in prevDates) DateUtils.dateOnly(d): 0.0
    };
    for (var e in previousExpenses) {
      final dateOnly = DateUtils.dateOnly(e.expenseDate);
      if (prevDailySum.containsKey(dateOnly)) {
        prevDailySum[dateOnly] = prevDailySum[dateOnly]! + e.amount;
      }
    }
    double prevCum = 0.0;
    for (var d in prevDates) {
      final dateOnly = DateUtils.dateOnly(d);
      final amt = prevDailySum[dateOnly] ?? 0.0;
      prevCum += amt;
      prevTrendSpots.add(TrendPoint(date: dateOnly, amount: amt, cumulativeAmount: prevCum));
    }

    // 13. Smart Spending Patterns (Weekend overspending, Time-of-day, Recurring bills)
    double weekendSum = 0;
    int weekendDays = 0;
    double weekdaySum = 0;
    int weekdayDays = 0;
    
    final Map<DateTime, double> dailyBreakdown = {};
    for (var e in filteredExpenses) {
      final dateOnly = DateUtils.dateOnly(e.expenseDate);
      dailyBreakdown[dateOnly] = (dailyBreakdown[dateOnly] ?? 0) + e.amount;
    }

    for (var date in currentDates) {
      final dateOnly = DateUtils.dateOnly(date);
      final amt = dailyBreakdown[dateOnly] ?? 0.0;
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
        weekendSum += amt;
        weekendDays++;
      } else {
        weekdaySum += amt;
        weekdayDays++;
      }
    }

    final weekendAvg = weekendDays > 0 ? weekendSum / weekendDays : 0.0;
    final weekdayAvg = weekdayDays > 0 ? weekdaySum / weekdayDays : 0.0;
    double weekendOverspendPercent = 0.0;
    if (weekdayAvg > 0 && weekendAvg > weekdayAvg) {
      weekendOverspendPercent = ((weekendAvg - weekdayAvg) / weekdayAvg) * 100;
    }

    final Map<String, int> timeOfDayCounts = {
      'Morning': 0,
      'Afternoon': 0,
      'Evening': 0,
      'Night': 0,
    };
    final Map<String, double> timeOfDayAmounts = {
      'Morning': 0,
      'Afternoon': 0,
      'Evening': 0,
      'Night': 0,
    };

    for (var e in filteredExpenses) {
      final hour = e.expenseDate.hour;
      String category = 'Morning';
      if (hour >= 12 && hour < 17) {
        category = 'Afternoon';
      } else if (hour >= 17 && hour < 21) {
        category = 'Evening';
      } else if (hour >= 21 || hour < 6) {
        category = 'Night';
      }
      
      timeOfDayCounts[category] = timeOfDayCounts[category]! + 1;
      timeOfDayAmounts[category] = timeOfDayAmounts[category]! + e.amount;
    }

    // 14. Recurring Expenses detection
    final Map<String, List<Expense>> recurGroups = {};
    for (var e in allExpenses) {
      final normalizedTitle = e.description.trim().toLowerCase();
      if (normalizedTitle.length >= 3) {
        final key = '${e.category.toLowerCase()}_$normalizedTitle';
        recurGroups.putIfAbsent(key, () => []).add(e);
      }
    }

    final List<RecurringExpenseInfo> recurringExpenses = [];
    recurGroups.forEach((key, list) {
      if (list.length >= 2) {
        list.sort((a, b) => a.expenseDate.compareTo(b.expenseDate));
        
        int totalDaysDiff = 0;
        for (int i = 1; i < list.length; i++) {
          totalDaysDiff += list[i].expenseDate.difference(list[i - 1].expenseDate).inDays;
        }
        final double avgDaysDiff = totalDaysDiff / (list.length - 1);
        final avgAmount = list.fold<double>(0, (sum, e) => sum + e.amount) / list.length;
        
        String freq = '';
        Duration addDuration = const Duration(days: 30);
        if (avgDaysDiff >= 5 && avgDaysDiff <= 9) {
          freq = 'Weekly';
          addDuration = const Duration(days: 7);
        } else if (avgDaysDiff >= 25 && avgDaysDiff <= 35) {
          freq = 'Monthly';
          addDuration = const Duration(days: 30);
        } else if (avgDaysDiff >= 12 && avgDaysDiff <= 17) {
          freq = 'Bi-Weekly';
          addDuration = const Duration(days: 14);
        }
        
        if (freq.isNotEmpty) {
          final lastDate = list.last.expenseDate;
          final nextExpected = lastDate.add(addDuration);
          recurringExpenses.add(RecurringExpenseInfo(
            title: list.first.description,
            category: list.first.category,
            amount: avgAmount,
            frequency: freq,
            nextExpectedDate: nextExpected,
          ));
        }
      }
    });

    // 15. Financial Health Score
    int score = 100;
    
    if (totalSpent > budgetLimit) {
      final overBy = totalSpent - budgetLimit;
      final overRatio = overBy / budgetLimit;
      score -= (overRatio * 50).toInt();
    } else {
      final dayOfMonth = now.day;
      final daysInM = DateUtils.getDaysInMonth(now.year, now.month);
      final elapsedRatio = dayOfMonth / daysInM;
      final spentRatio = totalSpent / budgetLimit;
      if (spentRatio > elapsedRatio + 0.15) {
        score -= 15;
      }
    }

    if (weekendOverspendPercent > 40) {
      score -= 10;
    }

    for (var cat in categoryShares) {
      if ((cat.category.toLowerCase() == 'shopping' || cat.category.toLowerCase() == 'entertainment') && cat.percentage > 45.0) {
        score -= 12;
      }
    }

    if (filteredExpenses.length >= 6 && categoryShares.length <= 2) {
      score -= 10;
    }

    score = max(0, min(100, score));

    String scoreLabel = 'Excellent';
    if (score < 50) {
      scoreLabel = 'Needs Improvement';
    } else if (score < 75) {
      scoreLabel = 'Average';
    } else if (score < 90) {
      scoreLabel = 'Good';
    }

    // Insights & recommendations
    final List<String> aiInsights = [];
    final List<String> aiRecommendations = [];

    if (filteredExpenses.isNotEmpty) {
      aiInsights.add('You completed $totalTransactions expense entries this period.');
      
      final maxDaySpot = trendSpots.isNotEmpty 
          ? trendSpots.reduce((a, b) => a.amount > b.amount ? a : b) 
          : null;
      if (maxDaySpot != null && maxDaySpot.amount > 0) {
        final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        final dayName = weekdays[maxDaySpot.date.weekday - 1];
        aiInsights.add('Highest spending day was $dayName (₹${maxDaySpot.amount.toStringAsFixed(0)}).');
      }

      for (var cat in categoryShares) {
        if (cat.prevAmount > 0) {
          final changeStr = cat.isIncrease ? 'increased' : 'decreased';
          aiInsights.add('${cat.category} spending $changeStr by ${cat.diffPercent.toStringAsFixed(0)}% compared to last period.');
        }
      }

      final sortedTimes = timeOfDayAmounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      if (sortedTimes.first.value > 0) {
        final timeName = sortedTimes.first.key;
        String desc = '';
        if (timeName == 'Morning') desc = 'between 6 AM and 12 PM';
        if (timeName == 'Afternoon') desc = 'between 12 PM and 5 PM';
        if (timeName == 'Evening') desc = 'between 5 PM and 9 PM';
        if (timeName == 'Night') desc = 'late at night (9 PM to 6 AM)';
        aiInsights.add('Most purchases happen $desc, totaling ₹${sortedTimes.first.value.toStringAsFixed(0)}.');
      }

      if (weekendOverspendPercent > 0) {
        aiInsights.add('You spent ${weekendOverspendPercent.toStringAsFixed(0)}% more on weekends compared to weekdays.');
      }
    } else {
      aiInsights.add('No spending data logged yet for this filter range.');
    }

    if (totalSpent > budgetLimit) {
      aiRecommendations.add('Current trend has exceeded your monthly budget. We suggest immediately locking down non-essential categories.');
    } else if (totalSpent > budgetLimit * 0.8) {
      aiRecommendations.add('You have used ${((totalSpent/budgetLimit)*100).toStringAsFixed(0)}% of your budget. Keep non-essential purchases low.');
    } else {
      aiRecommendations.add('You are on track to stay within your budget. Keep it up!');
    }

    for (var cat in categoryShares) {
      if (cat.category.toLowerCase() == 'shopping' && cat.percentage > 25.0) {
        final targetSavings = cat.amount * 0.1;
        aiRecommendations.add('Reduce shopping by 10% to save approximately ₹${targetSavings.toStringAsFixed(0)} next month.');
      }
      if ((cat.category.toLowerCase() == 'food' || cat.category.toLowerCase() == 'dining') && cat.percentage > 30.0) {
        final targetSavings = cat.amount * 0.15;
        aiRecommendations.add('Reduce restaurant spending and ordering out by 15% to save ₹${targetSavings.toStringAsFixed(0)}.');
      }
    }

    if (weekendOverspendPercent > 30) {
      aiRecommendations.add('Plan weekend meals or activities in advance to spend less on weekends.');
    }

    final cashShare = paymentMethodShares.firstWhere((p) => p.method.toLowerCase() == 'cash', orElse: () => PaymentMethodShare(method: 'Cash', amount: 0, percentage: 0, count: 0));
    if (cashShare.percentage > 35) {
      aiRecommendations.add('Try to use UPI or cards instead of cash for easier expense tracking and automated sorting.');
    }

    if (recurringExpenses.isNotEmpty) {
      aiRecommendations.add('Switch recurring subscriptions (e.g., Netflix, internet) to annual plans where possible to save 15-20%.');
    }

    final List<String> savingsOpportunities = [];
    for (var cat in categoryShares) {
      if (cat.category.toLowerCase() == 'food' && cat.amount > 3000) {
        final sav = (cat.amount * 0.20).toStringAsFixed(0);
        savingsOpportunities.add('Cook meals at home more often. Estimated savings: ₹$sav/month.');
      }
      if (cat.category.toLowerCase() == 'shopping' && cat.amount > 2000) {
        final sav = (cat.amount * 0.15).toStringAsFixed(0);
        savingsOpportunities.add('Implement a 48-hour wait rule on non-essential purchases. Estimated savings: ₹$sav/month.');
      }
      if (cat.category.toLowerCase() == 'travel' && cat.amount > 4000) {
        final sav = (cat.amount * 0.10).toStringAsFixed(0);
        savingsOpportunities.add('Consider carpooling or using public transit where available. Estimated savings: ₹$sav/month.');
      }
    }
    if (savingsOpportunities.isEmpty) {
      savingsOpportunities.add('No immediate overspending detected. Keep checking as you log more items!');
    }

    state = AnalyticsState(
      filterType: filterType,
      dateRange: currentRange,
      previousDateRange: prevRange,
      filteredExpenses: filteredExpenses,
      previousExpenses: previousExpenses,
      isLoading: false,
      totalSpent: totalSpent,
      prevTotalSpent: prevTotalSpent,
      totalSpentDiffPercent: totalSpentDiffPercent,
      dailyAverage: dailyAverage,
      prevDailyAverage: prevDailyAverage,
      dailyAverageDiffPercent: dailyAverageDiffPercent,
      totalTransactions: totalTransactions,
      prevTotalTransactions: prevTotalTransactions,
      activeMembersCount: activeMembersCount,
      budgetRemaining: budgetRemaining,
      budgetProgressPercent: budgetProgressPercent,
      budgetLimit: budgetLimit,
      categoryShares: categoryShares,
      memberShares: memberShares,
      paymentMethodShares: paymentMethodShares,
      topExpenses: topExpenses,
      heatmapData: heatmapData,
      calendarData: calendarData,
      trendSpots: trendSpots,
      prevTrendSpots: prevTrendSpots,
      weekendAvg: weekendAvg,
      weekdayAvg: weekdayAvg,
      weekendOverspendPercent: weekendOverspendPercent,
      recurringExpenses: recurringExpenses,
      savingsOpportunities: savingsOpportunities,
      financialHealthScore: score,
      healthScoreLabel: scoreLabel,
      aiInsights: aiInsights,
      aiRecommendations: aiRecommendations,
      timeOfDayCounts: timeOfDayCounts,
      timeOfDayAmounts: timeOfDayAmounts,
    );
  }
}
