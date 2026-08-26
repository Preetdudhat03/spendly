import re

def process():
    path = r'p:\pro\spendly\lib\features\analytics\models\analytics_models.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    new_models = """
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
"""

    if "class SpendingConsistency" not in content:
        # replace import 'package:flutter/material.dart'; with the new models which include dart:math
        content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + new_models.replace("import 'dart:math';\n", "import 'dart:math';\n"))
    
    # Update SpendingHealth.calculate signature to replace mocked values
    replace_from = """    // 3. Trend Stability (Mocked for now until Phase 5)
    int trendStability = 85; 

    // 4. Anomaly Exposure (Mocked for now until Phase 5)
    int anomalyExposure = 90;"""
    
    replace_to = """    // 3. Trend Stability 
    int trendStability = 85; 

    // 4. Anomaly Exposure 
    int anomalyExposure = 90;"""
    content = content.replace(replace_from, replace_to)
    
    # Let's add pattern to SpendingHealth args so we can calculate it
    health_sig_from = """    required double topCategoryPercentage,
    required SpendingVelocity velocity,"""
    health_sig_to = """    required double topCategoryPercentage,
    required SpendingVelocity velocity,
    required PatternIntelligence patterns,"""
    content = content.replace(health_sig_from, health_sig_to)
    
    health_calc_from = """    // 3. Trend Stability 
    int trendStability = 85; 

    // 4. Anomaly Exposure 
    int anomalyExposure = 90;"""
    health_calc_to = """    // 3. Trend Stability
    int trendStability = 85;
    if (patterns.consistency.level == ConsistencyLevel.stable) trendStability = 100;
    else if (patterns.consistency.level == ConsistencyLevel.highlyVariable) trendStability = 40;
    else trendStability = 75;

    // 4. Anomaly Exposure
    int anomalyExposure = 100;
    if (patterns.anomalies.length >= 3) anomalyExposure = 40;
    else if (patterns.anomalies.length == 2) anomalyExposure = 70;
    else if (patterns.anomalies.length == 1) anomalyExposure = 85;"""
    content = content.replace(health_calc_from, health_calc_to)
    
    # Add patterns to AnalyticsResult
    if "final PatternIntelligence patterns;" not in content:
        content = content.replace("final DiagnosticIntelligence diagnostic;", "final DiagnosticIntelligence diagnostic;\n  final PatternIntelligence patterns;")
        content = content.replace("required this.diagnostic,", "required this.diagnostic,\n    required this.patterns,")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
