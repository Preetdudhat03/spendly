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
  
  final Map<String, double> currentCatTotals;
  final Map<String, double> prevCatTotals;
  
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
    required this.currentCatTotals,
    required this.prevCatTotals,
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

class AnalyticsResult {
  final AnalyticsInput input;
  final DataConfidence confidence;
  final AggregationResult aggregations;

  const AnalyticsResult({
    required this.input,
    required this.confidence,
    required this.aggregations,
  });
}
