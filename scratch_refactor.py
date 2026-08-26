import re

def process():
    path = r'p:\pro\spendly\lib\features\analytics\providers\analytics_providers.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    calc_from = """    final healthScore = SpendingHealth.calculate("""
    
    calc_to = """    // Phase 5: Pattern & Anomaly Detection
    final dailyTotalsList = currentDailySum.values.toList();
    final consistency = SpendingConsistency.calculate(dailyTotalsList);
    
    final anomalies = <AnomalyInsight>[];
    for (var e in filteredExpenses) {
      final catInsight = categoryInsights.firstWhere((c) => c.categoryName == e.category, orElse: () => CategoryInsight(categoryName: '', currentSpend: 0, previousSpend: 0, trend: PeriodComparison.calculate(0, 0), percentageOfTotal: 0, transactionCount: 1, averageTransaction: e.amount, largestTransaction: e.amount));
      
      // Anomaly heuristics: 
      // 1. More than 3x the average for that category
      // 2. Value > 5% of overall budget limit
      if (catInsight.averageTransaction > 0 && e.amount > catInsight.averageTransaction * 3 && e.amount > params.budgetLimit * 0.05) {
         final diffPct = ((e.amount - catInsight.averageTransaction) / catInsight.averageTransaction) * 100;
         anomalies.add(AnomalyInsight(
           transaction: e,
           reason: 'Unusually large expense for ${e.category}.',
           deviationPercentage: diffPct,
         ));
      }
    }
    
    final highSpendingDays = <HighSpendingDayInsight>[];
    if (consistency.meanDailySpend > 0) {
      for (var entry in currentDailySum.entries) {
        if (entry.value > consistency.meanDailySpend * 2 && entry.value > params.budgetLimit * 0.05) {
          // find top category for this day
          final dayExpenses = filteredExpenses.where((e) => DateUtils.dateOnly(e.expenseDate) == entry.key);
          final dCatTotals = <String, double>{};
          for(var e in dayExpenses) dCatTotals[e.category] = (dCatTotals[e.category] ?? 0) + e.amount;
          String topCat = dCatTotals.isEmpty ? 'Unknown' : dCatTotals.entries.reduce((a, b) => a.value > b.value ? a : b).key;
          
          highSpendingDays.add(HighSpendingDayInsight(
            date: entry.key,
            amount: entry.value,
            topCategoryContributor: topCat,
          ));
        }
      }
    }
    
    String? acceleratingCategory;
    for (var cat in categoryInsights) {
      if (cat.trend.direction == TrendDirection.increase && cat.trend.percentageChange > 50.0 && cat.percentageOfTotal > 10.0) {
        acceleratingCategory = cat.categoryName;
        break;
      }
    }
    
    final patterns = PatternIntelligence(
      consistency: consistency,
      anomalies: anomalies,
      highSpendingDays: highSpendingDays,
      acceleratingCategory: acceleratingCategory,
    );

    final healthScore = SpendingHealth.calculate("""
    
    content = content.replace(calc_from, calc_to)
    
    res_from = """      healthScore: healthScore,
    );"""
    res_to = """      patterns: patterns,
      healthScore: healthScore,
    );"""
    content = content.replace(res_from, res_to)
    
    health_arg_from = """      velocity: velocity,
    );"""
    health_arg_to = """      velocity: velocity,
      patterns: patterns,
    );"""
    content = content.replace(health_arg_from, health_arg_to)
    
    # Update AnalyticsState
    if "final PatternIntelligence? patterns;" not in content:
        content = content.replace("final DiagnosticIntelligence? diagnostic;", "final DiagnosticIntelligence? diagnostic;\n  final PatternIntelligence? patterns;")
        content = content.replace("this.diagnostic,", "this.diagnostic,\n    this.patterns,")
        
    content = content.replace("diagnostic: result.diagnostic,", "diagnostic: result.diagnostic,\n      patterns: result.patterns,")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
