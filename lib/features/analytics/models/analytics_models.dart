import 'package:flutter/material.dart';

import 'dart:math';

enum ConsistencyLevel { stable, moderatelyVariable, highlyVariable, unavailable }

class SpendingConsistency {
  final double meanDailySpend;
  final double standardDeviation;
  final double coefficientOfVariation;
  final ConsistencyLevel level;

  const SpendingConsistency({
    required this.meanDailySpend,
    required this.standardDeviation,
    required this.coefficientOfVariation,
    required this.level,
  });

  factory SpendingConsistency.calculate(List<double> dailyTotals) {
    if (dailyTotals.isEmpty) {
      return const SpendingConsistency(meanDailySpend: 0, standardDeviation: 0, coefficientOfVariation: 0, level: ConsistencyLevel.unavailable);
    }
    
    final mean = dailyTotals.reduce((a, b) => a + b) / dailyTotals.length;
    if (mean == 0) {
      return const SpendingConsistency(meanDailySpend: 0, standardDeviation: 0, coefficientOfVariation: 0, level: ConsistencyLevel.stable);
    }
    
    double sumOfSquaredDiffs = 0.0;
    for (var total in dailyTotals) {
      sumOfSquaredDiffs += pow(total - mean, 2);
    }
    final variance = sumOfSquaredDiffs / dailyTotals.length;
    final stdDev = sqrt(variance);
    final cv = stdDev / mean;
    
    ConsistencyLevel level = ConsistencyLevel.moderatelyVariable;
    if (cv < 0.5) level = ConsistencyLevel.stable;
    else if (cv > 1.0) level = ConsistencyLevel.highlyVariable;
    
    return SpendingConsistency(
      meanDailySpend: mean,
      standardDeviation: stdDev,
      coefficientOfVariation: cv,
      level: level,
    );
  }
}

class AnomalyInsight {
  final ExpenseAnalyticsInput transaction;
  final String reason;
  final double deviationPercentage;

  const AnomalyInsight({
    required this.transaction,
    required this.reason,
    required this.deviationPercentage,
  });
}

class HighSpendingDayInsight {
  final DateTime date;
  final double amount;
  final String topCategoryContributor;

  const HighSpendingDayInsight({
    required this.date,
    required this.amount,
    required this.topCategoryContributor,
  });
}

class PatternIntelligence {
  final SpendingConsistency consistency;
  final List<AnomalyInsight> anomalies;
  final List<HighSpendingDayInsight> highSpendingDays;
  final String? acceleratingCategory;
  
  const PatternIntelligence({
    required this.consistency,
    required this.anomalies,
    required this.highSpendingDays,
    this.acceleratingCategory,
  });
}


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


class CategoryInsight {
  final String categoryName;
  final double currentSpend;
  final double previousSpend;
  final PeriodComparison trend;
  final double percentageOfTotal;
  final int transactionCount;
  final double averageTransaction;
  final double largestTransaction;

  const CategoryInsight({
    required this.categoryName,
    required this.currentSpend,
    required this.previousSpend,
    required this.trend,
    required this.percentageOfTotal,
    required this.transactionCount,
    required this.averageTransaction,
    required this.largestTransaction,
  });
}

class MemberInsight {
  final String memberId;
  final String memberName;
  final double currentSpend;
  final PeriodComparison trend;
  final double percentageOfTotal;
  final int transactionCount;
  final double averageTransaction;
  final String topCategory;

  const MemberInsight({
    required this.memberId,
    required this.memberName,
    required this.currentSpend,
    required this.trend,
    required this.percentageOfTotal,
    required this.transactionCount,
    required this.averageTransaction,
    required this.topCategory,
  });
}

class DiagnosticIntelligence {
  final List<CategoryInsight> categoryInsights;
  final List<MemberInsight> memberInsights;
  
  final double topCategoryShare;
  final double top3CategoryShare;
  
  final double top3TransactionsTotal;
  final double top3TransactionsShare;
  
  final int smallPurchasesCount;
  final double smallPurchasesTotal;
  
  final String primaryIncreaseContributor; 
  final String primaryDecreaseContributor;

  const DiagnosticIntelligence({
    required this.categoryInsights,
    required this.memberInsights,
    required this.topCategoryShare,
    required this.top3CategoryShare,
    required this.top3TransactionsTotal,
    required this.top3TransactionsShare,
    required this.smallPurchasesCount,
    required this.smallPurchasesTotal,
    required this.primaryIncreaseContributor,
    required this.primaryDecreaseContributor,
  });
}

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
    required PatternIntelligence patterns,
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

    // 3. Trend Stability
    int trendStability = 85;
    if (patterns.consistency.level == ConsistencyLevel.stable) trendStability = 100;
    else if (patterns.consistency.level == ConsistencyLevel.highlyVariable) trendStability = 40;
    else trendStability = 75;

    // 4. Anomaly Exposure
    int anomalyExposure = 100;
    if (patterns.anomalies.length >= 3) anomalyExposure = 40;
    else if (patterns.anomalies.length == 2) anomalyExposure = 70;
    else if (patterns.anomalies.length == 1) anomalyExposure = 85;

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


enum FactImportance { low, medium, high, critical }

class InsightFact {
  final String category;
  final String metricName;
  final String rawValue;
  final String formattedValue;
  final FactImportance importance;
  final String context;

  const InsightFact({
    required this.category,
    required this.metricName,
    required this.rawValue,
    required this.formattedValue,
    required this.importance,
    required this.context,
  });
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
  final DiagnosticIntelligence diagnostic;
  final PatternIntelligence patterns;
  final List<InsightFact> insightFacts;
  final SpendingHealth healthScore;

  const AnalyticsResult({
    required this.input,
    required this.confidence,
    required this.aggregations,
    required this.summary,
    required this.velocity,
    required this.budgetForecast,
    required this.diagnostic,
    required this.patterns,
    required this.insightFacts,
    required this.healthScore,
  });
}
