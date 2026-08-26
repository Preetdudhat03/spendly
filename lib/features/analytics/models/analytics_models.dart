import 'package:flutter/material.dart';

enum DataConfidence { high, medium, low, unavailable }

class ExpenseAnalyticsInput {
  final String id;
  final double amount;
  final String category;
  final String description;
  final String paymentMethod;
  final DateTime expenseDate;
  final String createdBy;
  final String createdByName;

  const ExpenseAnalyticsInput({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.paymentMethod,
    required this.expenseDate,
    required this.createdBy,
    required this.createdByName,
  });
}

class AnalyticsInput {
  final List<ExpenseAnalyticsInput> expenses;
  final double budgetLimit;
  final int activeMembersCount;
  final int filterTypeIndex; 
  final DateTimeRange? customRange;
  final Map<String, String> memberIdToName;
  final String? selectedMemberId;
  final DateTime now;
  final int calculationVersion;

  const AnalyticsInput({
    required this.expenses,
    required this.budgetLimit,
    required this.activeMembersCount,
    required this.filterTypeIndex,
    required this.customRange,
    required this.memberIdToName,
    required this.selectedMemberId,
    required this.now,
    required this.calculationVersion,
  });
}

class AggregationResult {
  final List<ExpenseAnalyticsInput> filteredExpenses;
  final List<ExpenseAnalyticsInput> previousExpenses;
  
  final double currentTotalSpent;
  final double prevTotalSpent;
  final double equivalentPrevTotalSpent; // Strictly equivalent period sum
  final int equivalentPrevTransactionCount;
  
  final Map<String, double> currentCatTotals;
  final Map<String, double> prevCatTotals;
  final Map<String, double> equivalentPrevCatTotals;
  
  final Map<String, List<ExpenseAnalyticsInput>> currentMemberExpenses;
  final Map<String, List<ExpenseAnalyticsInput>> prevMemberExpenses;
  
  final Map<String, List<ExpenseAnalyticsInput>> paymentExpenses;
  
  final Map<DateTime, double> heatmapData;
  final Map<DateTime, double> calendarData;
  
  final Map<DateTime, double> currentDailySum;
  final Map<DateTime, double> prevDailySum;
  
  final Map<DateTime, double> dailyBreakdown;
  
  final Map<String, int> timeOfDayCounts;
  final Map<String, double> timeOfDayAmounts;
  
  final Map<String, List<ExpenseAnalyticsInput>> recurGroups;

  const AggregationResult({
    required this.filteredExpenses,
    required this.previousExpenses,
    required this.currentTotalSpent,
    required this.prevTotalSpent,
    required this.equivalentPrevTotalSpent,
    required this.equivalentPrevTransactionCount,
    required this.currentCatTotals,
    required this.prevCatTotals,
    required this.equivalentPrevCatTotals,
    required this.currentMemberExpenses,
    required this.prevMemberExpenses,
    required this.paymentExpenses,
    required this.heatmapData,
    required this.calendarData,
    required this.currentDailySum,
    required this.prevDailySum,
    required this.dailyBreakdown,
    required this.timeOfDayCounts,
    required this.timeOfDayAmounts,
    required this.recurGroups,
  });
}

enum TrendDirection { increase, decrease, stable, unavailable }

class PeriodComparison {
  final double currentValue;
  final double previousValue;
  final double absoluteChange;
  final double percentageChange;
  final TrendDirection direction;

  const PeriodComparison({
    required this.currentValue,
    required this.previousValue,
    required this.absoluteChange,
    required this.percentageChange,
    required this.direction,
  });

  factory PeriodComparison.calculate(double current, double previous) {
    if (previous == 0 && current == 0) {
      return const PeriodComparison(currentValue: 0, previousValue: 0, absoluteChange: 0, percentageChange: 0, direction: TrendDirection.unavailable);
    }
    if (previous == 0) {
      return PeriodComparison(currentValue: current, previousValue: 0, absoluteChange: current, percentageChange: 100, direction: TrendDirection.increase);
    }
    final change = current - previous;
    final pct = (change / previous) * 100;
    
    TrendDirection dir = TrendDirection.stable;
    if (pct > 2.0) dir = TrendDirection.increase; // > 2% is meaningful
    else if (pct < -2.0) dir = TrendDirection.decrease;

    return PeriodComparison(
      currentValue: current,
      previousValue: previous,
      absoluteChange: change,
      percentageChange: pct,
      direction: dir,
    );
  }
}

class ExecutiveSummary {
  final PeriodComparison totalSpend;
  final PeriodComparison dailyAverage;
  final PeriodComparison transactionCount;

  const ExecutiveSummary({
    required this.totalSpend,
    required this.dailyAverage,
    required this.transactionCount,
  });
}

class AnalyticsResult {
  final AnalyticsInput input;
  final DataConfidence confidence;
  final AggregationResult aggregations;
  
  // Phase 2 models
  final ExecutiveSummary summary;
  
  // Later phases will fill these in:
  // final PeriodComparison periodComparison;
  // final BudgetForecast budgetForecast;
  // final List<CategoryInsight> categoryInsights;
  // final List<MemberInsight> memberInsights;
  // final SpendingHealth healthScore;
  // final List<InsightFact> insightFacts;

  const AnalyticsResult({
    required this.input,
    required this.confidence,
    required this.aggregations,
    required this.summary,
  });
}
