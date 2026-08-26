import 'dart:math';
import 'package:flutter/foundation.dart'; // for compute
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/models/expense.dart';
import '../models/analytics_models.dart';

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
  final String favoriteCategory;
  final String preferredPaymentMethod;
  final double monthlyTrend;

  MemberShare({
    required this.memberId,
    required this.name,
    required this.totalSpent,
    required this.count,
    required this.average,
    required this.largest,
    required this.favoriteCategory,
    required this.preferredPaymentMethod,
    required this.monthlyTrend,
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

class FinancialHealthMetrics {
  final int budgetControl;
  final int savingPotential;
  final int categoryDiversity;
  final int weekendDiscipline;
  final int totalScore;

  FinancialHealthMetrics({
    required this.budgetControl,
    required this.savingPotential,
    required this.categoryDiversity,
    required this.weekendDiscipline,
    required this.totalScore,
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

  // Forecasting
  final double projectedMonthEnd;
  final double expectedOverspend;

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

  final FinancialHealthMetrics healthMetrics;
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
    required this.projectedMonthEnd,
    required this.expectedOverspend,
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
    required this.healthMetrics,
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
      projectedMonthEnd: 0,
      expectedOverspend: 0,
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
      healthMetrics: FinancialHealthMetrics(
        budgetControl: 100,
        savingPotential: 100,
        categoryDiversity: 100,
        weekendDiscipline: 100,
        totalScore: 100,
      ),
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
    double? projectedMonthEnd,
    double? expectedOverspend,
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
    FinancialHealthMetrics? healthMetrics,
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
      totalSpentDiffPercent:
          totalSpentDiffPercent ?? this.totalSpentDiffPercent,
      dailyAverage: dailyAverage ?? this.dailyAverage,
      prevDailyAverage: prevDailyAverage ?? this.prevDailyAverage,
      dailyAverageDiffPercent:
          dailyAverageDiffPercent ?? this.dailyAverageDiffPercent,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      prevTotalTransactions:
          prevTotalTransactions ?? this.prevTotalTransactions,
      activeMembersCount: activeMembersCount ?? this.activeMembersCount,
      budgetRemaining: budgetRemaining ?? this.budgetRemaining,
      budgetProgressPercent:
          budgetProgressPercent ?? this.budgetProgressPercent,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      projectedMonthEnd: projectedMonthEnd ?? this.projectedMonthEnd,
      expectedOverspend: expectedOverspend ?? this.expectedOverspend,
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
      weekendOverspendPercent:
          weekendOverspendPercent ?? this.weekendOverspendPercent,
      recurringExpenses: recurringExpenses ?? this.recurringExpenses,
      savingsOpportunities: savingsOpportunities ?? this.savingsOpportunities,
      healthMetrics: healthMetrics ?? this.healthMetrics,
      healthScoreLabel: healthScoreLabel ?? this.healthScoreLabel,
      aiInsights: aiInsights ?? this.aiInsights,
      aiRecommendations: aiRecommendations ?? this.aiRecommendations,
      timeOfDayCounts: timeOfDayCounts ?? this.timeOfDayCounts,
      timeOfDayAmounts: timeOfDayAmounts ?? this.timeOfDayAmounts,
    );
  }

  factory AnalyticsState.fromResult(
    AnalyticsResult result,
    Map<String, Expense> originalExpenses,
  ) {
    final agg = result.aggregations;

    // Convert ExpenseAnalyticsInput to Expense
    Expense? mapExpense(ExpenseAnalyticsInput e) => originalExpenses[e.id];
    List<Expense> mapExpenses(List<ExpenseAnalyticsInput> list) =>
        list.map(mapExpense).whereType<Expense>().toList();

    final filteredExps = mapExpenses(agg.filteredExpenses);
    final previousExps = mapExpenses(agg.previousExpenses);

    // We need to recreate CategoryShare, MemberShare etc from the single pass aggregates
    // Category Shares
    final categoryShares = agg.currentCatTotals.entries.map((entry) {
      final category = entry.key;
      final amount = entry.value;
      final percentage = agg.currentTotalSpent > 0
          ? (amount / agg.currentTotalSpent) * 100
          : 0.0;
      final prevAmount = agg.prevCatTotals[category] ?? 0.0;
      double diffPercent = 0.0;
      if (prevAmount > 0)
        diffPercent = ((amount - prevAmount) / prevAmount) * 100;
      else if (amount > 0)
        diffPercent = 100.0;

      return CategoryShare(
        category: category,
        amount: amount,
        percentage: percentage,
        prevAmount: prevAmount,
        diffPercent: diffPercent.abs(),
        isIncrease: amount >= prevAmount,
      );
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

    // Member Shares
    final memberShares = agg.currentMemberExpenses.entries.map((entry) {
      final memberId = entry.key;
      final list = entry.value;
      final name =
          result.input.memberIdToName[memberId] ?? list.first.createdByName;
      final mTotal = list.fold<double>(0, (sum, e) => sum + e.amount);
      final mCount = list.length;
      final mAverage = mTotal / mCount;
      final mLargest = list.fold<double>(
        0,
        (maxVal, e) => e.amount > maxVal ? e.amount : maxVal,
      );

      final mCatTotals = <String, double>{};
      for (var e in list)
        mCatTotals[e.category] = (mCatTotals[e.category] ?? 0) + e.amount;
      final favCat = mCatTotals.isEmpty
          ? 'None'
          : mCatTotals.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      final mPayTotals = <String, int>{};
      for (var e in list)
        mPayTotals[e.paymentMethod] = (mPayTotals[e.paymentMethod] ?? 0) + 1;
      final prefPay = mPayTotals.isEmpty
          ? 'None'
          : mPayTotals.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      final mPrevList = agg.prevMemberExpenses[memberId] ?? [];
      final mPrevTotal = mPrevList.fold<double>(0, (sum, e) => sum + e.amount);
      double mTrend = 0.0;
      if (mPrevTotal > 0)
        mTrend = ((mTotal - mPrevTotal) / mPrevTotal) * 100;
      else if (mTotal > 0)
        mTrend = 100.0;

      return MemberShare(
        memberId: memberId,
        name: name,
        totalSpent: mTotal,
        count: mCount,
        average: mAverage,
        largest: mLargest,
        favoriteCategory: favCat,
        preferredPaymentMethod: prefPay,
        monthlyTrend: mTrend,
      );
    }).toList()..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

    // Payment Shares
    final paymentMethodShares = agg.paymentExpenses.entries.map((entry) {
      final method = entry.key;
      final list = entry.value;
      final amt = list.fold<double>(0, (sum, e) => sum + e.amount);
      final percentage = agg.currentTotalSpent > 0
          ? (amt / agg.currentTotalSpent) * 100
          : 0.0;
      return PaymentMethodShare(
        method: method,
        amount: amt,
        percentage: percentage,
        count: list.length,
      );
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

    // Top Expenses
    final topExpenses = List<Expense>.from(filteredExps)
      ..sort((a, b) => b.amount.compareTo(a.amount));
    if (topExpenses.length > 10)
      topExpenses.removeRange(10, topExpenses.length);

    // Trend Spots
    final trendSpots = <TrendPoint>[];
    double currentCum = 0.0;
    final currentDates = agg.currentDailySum.keys.toList()..sort();
    for (var d in currentDates) {
      final amt = agg.currentDailySum[d] ?? 0.0;
      currentCum += amt;
      trendSpots.add(
        TrendPoint(date: d, amount: amt, cumulativeAmount: currentCum),
      );
    }

    final prevTrendSpots = <TrendPoint>[];
    double prevCum = 0.0;
    final prevDates = agg.prevDailySum.keys.toList()..sort();
    for (var d in prevDates) {
      final amt = agg.prevDailySum[d] ?? 0.0;
      prevCum += amt;
      prevTrendSpots.add(
        TrendPoint(date: d, amount: amt, cumulativeAmount: prevCum),
      );
    }

    // Weekend/Weekday
    double weekendSum = 0;
    int weekendDays = 0;
    double weekdaySum = 0;
    int weekdayDays = 0;
    for (var d in currentDates) {
      final amt = agg.dailyBreakdown[d] ?? 0.0;
      if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) {
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
    if (weekdayAvg > 0 && weekendAvg > weekdayAvg)
      weekendOverspendPercent = ((weekendAvg - weekdayAvg) / weekdayAvg) * 100;

    // Recurring
    final recurringExpenses = <RecurringExpenseInfo>[];
    agg.recurGroups.forEach((key, list) {
      if (list.length >= 2) {
        list.sort((a, b) => a.expenseDate.compareTo(b.expenseDate));
        int totalDaysDiff = 0;
        for (int i = 1; i < list.length; i++)
          totalDaysDiff += list[i].expenseDate
              .difference(list[i - 1].expenseDate)
              .inDays;
        final double avgDaysDiff = totalDaysDiff / (list.length - 1);
        final avgAmount =
            list.fold<double>(0, (sum, e) => sum + e.amount) / list.length;

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
          recurringExpenses.add(
            RecurringExpenseInfo(
              title: list.first.description,
              category: list.first.category,
              amount: avgAmount,
              frequency: freq,
              nextExpectedDate: nextExpected,
            ),
          );
        }
      }
    });

    double totalSpentDiffPercent = 0.0;
    if (agg.prevTotalSpent > 0)
      totalSpentDiffPercent =
          ((agg.currentTotalSpent - agg.prevTotalSpent) / agg.prevTotalSpent) *
          100;
    else if (agg.currentTotalSpent > 0)
      totalSpentDiffPercent = 100.0;

    final currentDays = currentDates.length > 0 ? currentDates.length : 1;
    final prevDays = prevDates.length > 0 ? prevDates.length : 1;
    double dailyAverage = agg.currentTotalSpent / currentDays;

    // Forecast & Budget
    double projectedMonthEnd = 0.0;
    double expectedOverspend = 0.0;
    final ranges = AnalyticsNotifier._calculateDateRanges(
      AnalyticsFilterType.values[result.input.filterTypeIndex],
      result.input.customRange,
      result.input.now,
    );
    final currentRange = ranges[0];
    final prevRange = ranges[1];

    if (AnalyticsFilterType.values[result.input.filterTypeIndex] ==
            AnalyticsFilterType.thisMonth &&
        currentRange.start.month == result.input.now.month &&
        currentRange.start.year == result.input.now.year) {
      final daysInMonth = DateUtils.getDaysInMonth(
        result.input.now.year,
        result.input.now.month,
      );
      final elapsedDays = result.input.now.day > 0 ? result.input.now.day : 1;
      dailyAverage = agg.currentTotalSpent / elapsedDays;
      final remainingDays = daysInMonth - elapsedDays;
      projectedMonthEnd =
          agg.currentTotalSpent + (dailyAverage * remainingDays);
      expectedOverspend = (projectedMonthEnd - result.input.budgetLimit) > 0
          ? (projectedMonthEnd - result.input.budgetLimit)
          : 0.0;
    }

    double prevDailyAverage = agg.prevTotalSpent / prevDays;
    double dailyAverageDiffPercent = 0.0;
    if (prevDailyAverage > 0)
      dailyAverageDiffPercent =
          ((dailyAverage - prevDailyAverage) / prevDailyAverage) * 100;
    else if (dailyAverage > 0)
      dailyAverageDiffPercent = 100.0;

    final budgetRemaining =
        (result.input.budgetLimit - agg.currentTotalSpent) > 0
        ? (result.input.budgetLimit - agg.currentTotalSpent)
        : 0.0;
    double budgetProgressPercent = result.input.budgetLimit > 0
        ? (agg.currentTotalSpent / result.input.budgetLimit)
        : 0.0;
    if (budgetProgressPercent > 1.0) budgetProgressPercent = 1.0;

    // Health Score (Compatibility)
    int budgetControlScore = 100;
    if (agg.currentTotalSpent > result.input.budgetLimit)
      budgetControlScore -=
          ((agg.currentTotalSpent - result.input.budgetLimit) /
                  result.input.budgetLimit *
                  100)
              .toInt()
              .clamp(0, 100);
    int weekendDisciplineScore = 100;
    if (weekendOverspendPercent > 40)
      weekendDisciplineScore -= 40;
    else if (weekendOverspendPercent > 20)
      weekendDisciplineScore -= 20;
    int diversityScore = 100;
    if (filteredExps.length >= 6 && categoryShares.length <= 2)
      diversityScore -= 40;
    int savingPotentialScore = 100;
    for (var cat in categoryShares)
      if ((cat.category.toLowerCase() == 'shopping' ||
              cat.category.toLowerCase() == 'entertainment') &&
          cat.percentage > 45.0)
        savingPotentialScore -= 50;

    budgetControlScore = budgetControlScore.clamp(0, 100);
    weekendDisciplineScore = weekendDisciplineScore.clamp(0, 100);
    diversityScore = diversityScore.clamp(0, 100);
    savingPotentialScore = savingPotentialScore.clamp(0, 100);
    final totalScore =
        ((budgetControlScore +
                    weekendDisciplineScore +
                    diversityScore +
                    savingPotentialScore) /
                4)
            .toInt();

    String scoreLabel = 'Excellent';
    if (totalScore < 50)
      scoreLabel = 'Needs Improvement';
    else if (totalScore < 75)
      scoreLabel = 'Average';
    else if (totalScore < 90)
      scoreLabel = 'Good';

    final healthMetrics = FinancialHealthMetrics(
      budgetControl: budgetControlScore,
      savingPotential: savingPotentialScore,
      categoryDiversity: diversityScore,
      weekendDiscipline: weekendDisciplineScore,
      totalScore: totalScore,
    );

    return AnalyticsState(
      filterType: AnalyticsFilterType.values[result.input.filterTypeIndex],
      dateRange: currentRange,
      previousDateRange: prevRange,
      filteredExpenses: filteredExps,
      previousExpenses: previousExps,
      isLoading: false,
      totalSpent: agg.currentTotalSpent,
      prevTotalSpent: agg.prevTotalSpent,
      totalSpentDiffPercent: totalSpentDiffPercent,
      dailyAverage: dailyAverage,
      prevDailyAverage: prevDailyAverage,
      dailyAverageDiffPercent: dailyAverageDiffPercent,
      totalTransactions: filteredExps.length,
      prevTotalTransactions: previousExps.length,
      activeMembersCount: result.input.activeMembersCount,
      budgetRemaining: budgetRemaining,
      budgetProgressPercent: budgetProgressPercent,
      budgetLimit: result.input.budgetLimit,
      projectedMonthEnd: projectedMonthEnd,
      expectedOverspend: expectedOverspend,
      categoryShares: categoryShares,
      memberShares: memberShares,
      paymentMethodShares: paymentMethodShares,
      topExpenses: topExpenses,
      heatmapData: agg.heatmapData,
      calendarData: agg.calendarData,
      trendSpots: trendSpots,
      prevTrendSpots: prevTrendSpots,
      weekendAvg: weekendAvg,
      weekdayAvg: weekdayAvg,
      weekendOverspendPercent: weekendOverspendPercent,
      recurringExpenses: recurringExpenses,
      savingsOpportunities:
          [], // Skipped heavy generation for UI compat, or keep old?
      healthMetrics: healthMetrics,
      healthScoreLabel: scoreLabel,
      aiInsights: [],
      aiRecommendations: [],
      timeOfDayCounts: agg.timeOfDayCounts,
      timeOfDayAmounts: agg.timeOfDayAmounts,
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

// Active Member Filter State Provider
final analyticsMemberFilterProvider = StateProvider<String?>((ref) {
  return null; // null means 'All Members'
});

// Params for the isolate computation

// Primary Analytics Calculations Provider
final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
      final expenseState = ref.watch(expenseProvider);
      final budgetState = ref.watch(budgetProvider);
      final familyState = ref.watch(familyProvider);
      final filterType = ref.watch(analyticsFilterTypeProvider);
      final customRange = ref.watch(analyticsCustomDateRangeProvider);
      final selectedMemberId = ref.watch(analyticsMemberFilterProvider);

      return AnalyticsNotifier(
        expenseState: expenseState,
        budgetState: budgetState,
        familyState: familyState,
        filterType: filterType,
        customRange: customRange,
        selectedMemberId: selectedMemberId,
      );
    });

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  AnalyticsNotifier({
    required ExpenseState expenseState,
    required BudgetState budgetState,
    required FamilyState familyState,
    required AnalyticsFilterType filterType,
    required DateTimeRange? customRange,
    required String? selectedMemberId,
  }) : super(AnalyticsNotifier._createInitialState(filterType, customRange)) {
    _triggerCalculation(
      expenseState,
      budgetState,
      familyState,
      filterType,
      customRange,
      selectedMemberId,
    );
  }

  static AnalyticsState _createInitialState(
    AnalyticsFilterType filterType,
    DateTimeRange? customRange,
  ) {
    final ranges = _calculateDateRanges(
      filterType,
      customRange,
      DateTime.now(),
    );
    return AnalyticsState.initial(ranges[0], ranges[1]);
  }

  static List<DateTimeRange> _calculateDateRanges(
    AnalyticsFilterType filterType,
    DateTimeRange? customRange,
    DateTime now,
  ) {
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
        end = DateTime(
          now.year,
          now.month,
          DateUtils.getDaysInMonth(now.year, now.month),
          23,
          59,
          59,
        );
        final lastMonthDate = DateTime(now.year, now.month - 1, 1);
        prevStart = DateTime(lastMonthDate.year, lastMonthDate.month, 1);
        prevEnd = DateTime(
          lastMonthDate.year,
          lastMonthDate.month,
          DateUtils.getDaysInMonth(lastMonthDate.year, lastMonthDate.month),
          23,
          59,
          59,
        );
        break;
      case AnalyticsFilterType.lastMonth:
        final lastMonthDate = DateTime(now.year, now.month - 1, 1);
        start = DateTime(lastMonthDate.year, lastMonthDate.month, 1);
        end = DateTime(
          lastMonthDate.year,
          lastMonthDate.month,
          DateUtils.getDaysInMonth(lastMonthDate.year, lastMonthDate.month),
          23,
          59,
          59,
        );

        final twoMonthsAgoDate = DateTime(now.year, now.month - 2, 1);
        prevStart = DateTime(twoMonthsAgoDate.year, twoMonthsAgoDate.month, 1);
        prevEnd = DateTime(
          twoMonthsAgoDate.year,
          twoMonthsAgoDate.month,
          DateUtils.getDaysInMonth(
            twoMonthsAgoDate.year,
            twoMonthsAgoDate.month,
          ),
          23,
          59,
          59,
        );
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
          end = DateTime(
            customRange.end.year,
            customRange.end.month,
            customRange.end.day,
            23,
            59,
            59,
          );
          final diff = end.difference(start);
          prevStart = start.subtract(diff);
          prevEnd = start.subtract(const Duration(seconds: 1));
        } else {
          start = DateTime(now.year, now.month, 1);
          end = DateTime(
            now.year,
            now.month,
            DateUtils.getDaysInMonth(now.year, now.month),
            23,
            59,
            59,
          );
          final lastMonthDate = DateTime(now.year, now.month - 1, 1);
          prevStart = DateTime(lastMonthDate.year, lastMonthDate.month, 1);
          prevEnd = DateTime(
            lastMonthDate.year,
            lastMonthDate.month,
            DateUtils.getDaysInMonth(lastMonthDate.year, lastMonthDate.month),
            23,
            59,
            59,
          );
        }
        break;
    }

    return [
      DateTimeRange(start: start, end: end),
      DateTimeRange(start: prevStart, end: prevEnd),
    ];
  }

  Future<void> _triggerCalculation(
    ExpenseState expenseState,
    BudgetState budgetState,
    FamilyState familyState,
    AnalyticsFilterType filterType,
    DateTimeRange? customRange,
    String? selectedMemberId,
  ) async {
    if (expenseState.isLoading) {
      state = state.copyWith(isLoading: true);
      return;
    }

    final input = AnalyticsInput(
      expenses: expenseState.expenses
          .map(
            (e) => ExpenseAnalyticsInput(
              id: e.id,
              amount: e.amount,
              category: e.category,
              description: e.description,
              paymentMethod: e.paymentMethod,
              expenseDate: e.expenseDate,
              createdBy: e.createdBy,
              createdByName: e.createdByName,
            ),
          )
          .toList(),
      budgetLimit: budgetState.currentBudget?.monthlyBudget ?? 20000.0,
      activeMembersCount: familyState.members.isEmpty
          ? 1
          : familyState.members.length,
      filterTypeIndex: filterType.index,
      customRange: customRange,
      memberIdToName: {
        for (var m in familyState.members) m.userId: m.displayName,
      },
      selectedMemberId: selectedMemberId,
      now: DateTime.now(),
      calculationVersion: 1,
    );

    // Compute in background isolate to prevent UI freezing
    final result = await compute(_runCalculations, input);
    if (mounted) {
      final originalExpensesMap = {
        for (var e in expenseState.expenses) e.id: e,
      };
      state = AnalyticsState.fromResult(result, originalExpensesMap);
    }
  }

  // Top-level static function for Isolate processing
  static AnalyticsResult runCalculations(AnalyticsInput params) {
    final filterType = AnalyticsFilterType.values[params.filterTypeIndex];
    final ranges = _calculateDateRanges(
      filterType,
      params.customRange,
      params.now,
    );
    final currentRange = ranges[0];
    final prevRange = ranges[1];

    // ONE O(N) Aggregation Pass
    final filteredExpenses = <ExpenseAnalyticsInput>[];
    final previousExpenses = <ExpenseAnalyticsInput>[];

    double currentTotalSpent = 0.0;
    double prevTotalSpent = 0.0;

    final currentCatTotals = <String, double>{};
    final prevCatTotals = <String, double>{};

    final currentMemberExpenses = <String, List<ExpenseAnalyticsInput>>{};
    final prevMemberExpenses = <String, List<ExpenseAnalyticsInput>>{};

    final paymentExpenses = <String, List<ExpenseAnalyticsInput>>{};

    final heatmapData = <DateTime, double>{};
    final calendarData = <DateTime, double>{};

    final currentDailySum = <DateTime, double>{};
    final prevDailySum = <DateTime, double>{};

    final dailyBreakdown = <DateTime, double>{};

    final timeOfDayCounts = <String, int>{
      'Morning': 0,
      'Afternoon': 0,
      'Evening': 0,
      'Night': 0,
    };
    final timeOfDayAmounts = <String, double>{
      'Morning': 0.0,
      'Afternoon': 0.0,
      'Evening': 0.0,
      'Night': 0.0,
    };

    final recurGroups = <String, List<ExpenseAnalyticsInput>>{};

    // Setup heatmap / calendar blanks
    final todayOnly = DateUtils.dateOnly(params.now);
    final mondayOfCurrentWeek = DateTime(
      todayOnly.year,
      todayOnly.month,
      todayOnly.day - (todayOnly.weekday - 1),
    );
    final startOfHeatmap = DateTime(
      mondayOfCurrentWeek.year,
      mondayOfCurrentWeek.month,
      mondayOfCurrentWeek.day - 77,
    );
    for (int i = 0; i < 84; i++)
      heatmapData[DateTime(
            startOfHeatmap.year,
            startOfHeatmap.month,
            startOfHeatmap.day + i,
          )] =
          0.0;
    final calMonthEnd = DateTime(
      params.now.year,
      params.now.month,
      DateUtils.getDaysInMonth(params.now.year, params.now.month),
    );
    for (int d = 1; d <= calMonthEnd.day; d++)
      calendarData[DateTime(params.now.year, params.now.month, d)] = 0.0;

    final currentDays =
        (currentRange.end.difference(currentRange.start).inDays + 1) > 0
        ? (currentRange.end.difference(currentRange.start).inDays + 1)
        : 1;
    for (int i = 0; i < currentDays; i++)
      currentDailySum[DateUtils.dateOnly(
            currentRange.start.add(Duration(days: i)),
          )] =
          0.0;

    final prevDays = (prevRange.end.difference(prevRange.start).inDays + 1) > 0
        ? (prevRange.end.difference(prevRange.start).inDays + 1)
        : 1;
    for (int i = 0; i < prevDays; i++)
      prevDailySum[DateUtils.dateOnly(prevRange.start.add(Duration(days: i)))] =
          0.0;

    for (var e in params.expenses) {
      if (params.selectedMemberId != null &&
          e.createdBy != params.selectedMemberId)
        continue;

      final dateOnly = DateUtils.dateOnly(e.expenseDate);

      // Global Maps
      if (heatmapData.containsKey(dateOnly))
        heatmapData[dateOnly] = heatmapData[dateOnly]! + e.amount;
      if (dateOnly.year == params.now.year &&
          dateOnly.month == params.now.month) {
        calendarData[dateOnly] = (calendarData[dateOnly] ?? 0.0) + e.amount;
      }

      final normalizedTitle = e.description.trim().toLowerCase();
      if (normalizedTitle.length >= 3) {
        recurGroups
            .putIfAbsent(
              '${e.category.toLowerCase()}_$normalizedTitle',
              () => [],
            )
            .add(e);
      }

      // Current Range
      if (e.expenseDate.isAfter(
            currentRange.start.subtract(const Duration(seconds: 1)),
          ) &&
          e.expenseDate.isBefore(
            currentRange.end.add(const Duration(seconds: 1)),
          )) {
        filteredExpenses.add(e);
        currentTotalSpent += e.amount;
        currentCatTotals[e.category] =
            (currentCatTotals[e.category] ?? 0) + e.amount;
        currentMemberExpenses.putIfAbsent(e.createdBy, () => []).add(e);
        paymentExpenses.putIfAbsent(e.paymentMethod, () => []).add(e);

        if (currentDailySum.containsKey(dateOnly))
          currentDailySum[dateOnly] = currentDailySum[dateOnly]! + e.amount;
        dailyBreakdown[dateOnly] = (dailyBreakdown[dateOnly] ?? 0) + e.amount;

        final hour = e.expenseDate.hour;
        String tod = 'Morning';
        if (hour >= 12 && hour < 17)
          tod = 'Afternoon';
        else if (hour >= 17 && hour < 21)
          tod = 'Evening';
        else if (hour >= 21 || hour < 6)
          tod = 'Night';
        timeOfDayCounts[tod] = timeOfDayCounts[tod]! + 1;
        timeOfDayAmounts[tod] = timeOfDayAmounts[tod]! + e.amount;
      }

      // Previous Range
      if (e.expenseDate.isAfter(
            prevRange.start.subtract(const Duration(seconds: 1)),
          ) &&
          e.expenseDate.isBefore(
            prevRange.end.add(const Duration(seconds: 1)),
          )) {
        previousExpenses.add(e);
        prevTotalSpent += e.amount;
        prevCatTotals[e.category] = (prevCatTotals[e.category] ?? 0) + e.amount;
        prevMemberExpenses.putIfAbsent(e.createdBy, () => []).add(e);
        if (prevDailySum.containsKey(dateOnly))
          prevDailySum[dateOnly] = prevDailySum[dateOnly]! + e.amount;
      }
    }

    final agg = AggregationResult(
      filteredExpenses: filteredExpenses,
      previousExpenses: previousExpenses,
      currentTotalSpent: currentTotalSpent,
      prevTotalSpent: prevTotalSpent,
      currentCatTotals: currentCatTotals,
      prevCatTotals: prevCatTotals,
      currentMemberExpenses: currentMemberExpenses,
      prevMemberExpenses: prevMemberExpenses,
      paymentExpenses: paymentExpenses,
      heatmapData: heatmapData,
      calendarData: calendarData,
      currentDailySum: currentDailySum,
      prevDailySum: prevDailySum,
      dailyBreakdown: dailyBreakdown,
      timeOfDayCounts: timeOfDayCounts,
      timeOfDayAmounts: timeOfDayAmounts,
      recurGroups: recurGroups,
    );

    // Evaluate Data Confidence based on filterType and length
    DataConfidence confidence = DataConfidence.medium;
    if (filteredExpenses.length > 50) confidence = DataConfidence.high;
    if (filteredExpenses.length < 5) confidence = DataConfidence.low;

    return AnalyticsResult(
      input: params,
      confidence: confidence,
      aggregations: agg,
    );
  }
}
