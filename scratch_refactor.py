import re

def process():
    path = r'p:\pro\spendly\lib\features\analytics\providers\analytics_providers.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    calc_from = """    final healthScore = SpendingHealth.calculate("""
    
    calc_to = """    // Phase 7: Extract InsightFacts
    final insightFacts = <InsightFact>[];
    
    // Budget Velocity Fact
    insightFacts.add(InsightFact(
      category: 'Budget',
      metricName: 'Velocity Status',
      rawValue: velocity.velocityRatio.toString(),
      formattedValue: velocity.interpretation,
      importance: velocity.status == VelocityStatus.veryFast ? FactImportance.critical : FactImportance.medium,
      context: 'Current spent: ${currentTotalSpent}, Budget Limit: ${params.budgetLimit}',
    ));
    
    // Anomaly Facts
    for (var anomaly in anomalies) {
      insightFacts.add(InsightFact(
        category: 'Anomaly',
        metricName: 'Large Expense',
        rawValue: anomaly.transaction.amount.toString(),
        formattedValue: '${anomaly.transaction.category} expense of ${anomaly.transaction.amount}',
        importance: FactImportance.high,
        context: anomaly.reason,
      ));
    }
    
    // Contribution Fact
    if (primaryIncrease != 'None') {
      insightFacts.add(InsightFact(
        category: 'Diagnostic',
        metricName: 'Primary Increase Contributor',
        rawValue: maxInc.toString(),
        formattedValue: primaryIncrease,
        importance: FactImportance.medium,
        context: 'Increased by ${maxInc} compared to equivalent previous period.',
      ));
    }
    
    // High Spend Day
    for (var day in highSpendingDays) {
      insightFacts.add(InsightFact(
        category: 'Pattern',
        metricName: 'High Spending Day',
        rawValue: day.amount.toString(),
        formattedValue: DateUtils.dateOnly(day.date).toString(),
        importance: FactImportance.high,
        context: 'Top contributor was ${day.topCategoryContributor}.',
      ));
    }

    final healthScore = SpendingHealth.calculate("""
    
    content = content.replace(calc_from, calc_to)
    
    res_from = """      patterns: patterns,
      healthScore: healthScore,
    );"""
    res_to = """      patterns: patterns,
      insightFacts: insightFacts,
      healthScore: healthScore,
    );"""
    content = content.replace(res_from, res_to)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
