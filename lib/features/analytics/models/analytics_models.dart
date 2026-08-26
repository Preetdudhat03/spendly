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


enum VelocityStatus { underPace, onPace, slightlyFast, veryFast, unavailable }

class SpendingVelocity {
  final double budgetConsumedPct;
  final double timeElapsedPct;
  final double velocityRatio; 
  final VelocityStatus status;
  final String interpretation;

  const SpendingVelocity({
    required this.budgetConsumedPct,
    required this.timeElapsedPct,
    required this.velocityRatio,
    required this.status,
    required this.interpretation,
  });

  factory SpendingVelocity.calculate({
    required double totalSpent,
    required double budgetLimit,
    required int elapsedDays,
    required int totalDays,
  }) {
    if (budgetLimit <= 0 || totalDays <= 0 || elapsedDays <= 0) {
      return const SpendingVelocity(
        budgetConsumedPct: 0, timeElapsedPct: 0, velocityRatio: 0, 
        status: VelocityStatus.unavailable, interpretation: 'Unavailable'
      );
    }
    final budgetPct = (totalSpent / budgetLimit) * 100;
    final timePct = (elapsedDays / totalDays) * 100;
    final ratio = timePct > 0 ? budgetPct / timePct : 0.0;
    
    VelocityStatus status = VelocityStatus.onPace;
    String interp = 'Spending is on pace with the budget.';
    
    if (ratio < 0.85) {
      status = VelocityStatus.underPace;
      interp = 'Spending is slower than expected.';
    } else if (ratio > 1.3) {
      status = VelocityStatus.veryFast;
      interp = 'Spending is dangerously fast.';
    } else if (ratio > 1.05) {
      status = VelocityStatus.slightlyFast;
      interp = 'Spending is slightly ahead of pace.';
    }

    return SpendingVelocity(
      budgetConsumedPct: budgetPct,
      timeElapsedPct: timePct,
      velocityRatio: ratio,
      status: status,
      interpretation: interp,
    );
  }
}

class BudgetForecast {
  final double projectedTotal;
  final double expectedRemaining;
  final double expectedOverrun;
  final bool isOverrun;
  
  const BudgetForecast({
    required this.projectedTotal,
    required this.expectedRemaining,
    required this.expectedOverrun,
    required this.isOverrun,
  });

  factory BudgetForecast.calculate({
    required double currentTotalSpent,
    required double currentDailyAvg,
    required double budgetLimit,
    required int remainingDays,
  }) {
    if (budgetLimit <= 0) {
      return const BudgetForecast(projectedTotal: 0, expectedRemaining: 0, expectedOverrun: 0, isOverrun: false);
    }
    final projected = currentTotalSpent + (currentDailyAvg * remainingDays);
    final diff = budgetLimit - projected;
    final isOver = diff < 0;
    
    return BudgetForecast(
      projectedTotal: projected,
      expectedRemaining: isOver ? 0 : diff,
      expectedOverrun: isOver ? diff.abs() : 0,
      isOverrun: isOver,
    );
  }
}

class SpendingHealth {
  final int budgetAdherence; // 35%
  final int spendingVelocity; // 25%
  final int trendStability; // 15%
  final int anomalyExposure; // 10%
  final int concentration; // 10%
  final int dataConfidenceScore; // 5%
  final int totalScore;
  final String label;

  const SpendingHealth({
    required this.budgetAdherence,
    required this.spendingVelocity,
    required this.trendStability,
    required this.anomalyExposure,
    required this.concentration,
    required this.dataConfidenceScore,
    required this.totalScore,
    required this.label,
  });

  factory SpendingHealth.calculate({
    required double totalSpent,
    required double budgetLimit,
    required int elapsedDays,
    required int daysInMonth,
    required DataConfidence confidence,
    required double topCategoryPercentage,
    required SpendingVelocity velocity,
  }) {
    if (budgetLimit <= 0 || confidence == DataConfidence.unavailable) {
      return const SpendingHealth(
        budgetAdherence: 0, spendingVelocity: 0, trendStability: 0,
        anomalyExposure: 0, concentration: 0, dataConfidenceScore: 0,
        totalScore: 0, label: 'Unavailable'
      );
    }

    // 1. Budget Adherence (0 to 100)
    int budgetAdherence = 100;
    if (totalSpent > budgetLimit) {
      budgetAdherence = (100 - ((totalSpent - budgetLimit) / budgetLimit * 100)).toInt().clamp(0, 100);
    } else {
      budgetAdherence = 100;
    }

    // 2. Spending Velocity (0 to 100)
    int spendingVelocity = 100;
    if (velocity.velocityRatio > 1.0) {
      final velocityOverage = velocity.budgetConsumedPct - velocity.timeElapsedPct;
      spendingVelocity = (100 - (velocityOverage * 2)).toInt().clamp(0, 100);
    }

    // 3. Trend Stability (Mocked for now until Phase 5)
    int trendStability = 85; 

    // 4. Anomaly Exposure (Mocked for now until Phase 5)
    int anomalyExposure = 90;

    // 5. Concentration
    // High concentration isn't always bad. If top category > 50%, we might dock slightly for lack of diversification, but not severely.
    int concentrationScore = 100;
    if (topCategoryPercentage > 60) {
      concentrationScore = 80;
    } else if (topCategoryPercentage > 80) {
      concentrationScore = 60;
    }

    // 6. Data Confidence
    int confScore = 100;
    if (confidence == DataConfidence.low) confScore = 30;
    else if (confidence == DataConfidence.medium) confScore = 70;

    final rawScore = (budgetAdherence * 0.35) +
        (spendingVelocity * 0.25) +
        (trendStability * 0.15) +
        (anomalyExposure * 0.10) +
        (concentrationScore * 0.10) +
        (confScore * 0.05);
        
    final total = rawScore.toInt().clamp(0, 100);
    
    String label = 'Excellent';
    if (total < 50) label = 'Action Needed';
    else if (total < 75) label = 'Average';
    else if (total < 90) label = 'Good';

    return SpendingHealth(
      budgetAdherence: budgetAdherence,
      spendingVelocity: spendingVelocity,
      trendStability: trendStability,
      anomalyExposure: anomalyExposure,
      concentration: concentrationScore,
      dataConfidenceScore: confScore,
      totalScore: total,
      label: label,
    );
  }
}

class AnalyticsResult {
  final AnalyticsInput input;
  final DataConfidence confidence;
  final AggregationResult aggregations;
  
  // Phase 2 models
  final ExecutiveSummary summary;
  
  // Phase 6 model
  final SpendingVelocity velocity;
  final BudgetForecast budgetForecast;
  final SpendingHealth healthScore;
  
  // Later phases will fill these in:
  // final PeriodComparison periodComparison;
  // final BudgetForecast budgetForecast;
  // final List<CategoryInsight> categoryInsights;
  // final List<MemberInsight> memberInsights;
  // final List<InsightFact> insightFacts;

  const AnalyticsResult({
    required this.input,
    required this.confidence,
    required this.aggregations,
    required this.summary,
    required this.velocity,
    required this.budgetForecast,
    required this.healthScore,
  });
}
