import re

def process():
    path = r'p:\pro\spendly\lib\features\analytics\providers\analytics_providers.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Update AnalyticsState
    if "final SpendingHealth? healthScore;" not in content:
        content = content.replace("final ExecutiveSummary? summary;", "final ExecutiveSummary? summary;\n  final SpendingHealth? healthScore;")
        content = content.replace("this.summary,", "this.summary,\n    this.healthScore,")
    
    # 2. Update runCalculations to construct SpendingHealth
    # It should happen after summary creation.
    health_calc = """
    // Calculate top category percentage
    double topCategoryPercentage = 0.0;
    if (currentCatTotals.isNotEmpty && currentTotalSpent > 0) {
      double maxCat = 0.0;
      for (var val in currentCatTotals.values) {
        if (val > maxCat) maxCat = val;
      }
      topCategoryPercentage = (maxCat / currentTotalSpent) * 100;
    }

    final healthScore = SpendingHealth.calculate(
      totalSpent: currentTotalSpent,
      budgetLimit: params.budgetLimit,
      elapsedDays: currentElapsedDays,
      daysInMonth: DateUtils.getDaysInMonth(params.now.year, params.now.month),
      confidence: confidence,
      topCategoryPercentage: topCategoryPercentage,
    );

    return AnalyticsResult(
"""
    content = content.replace("    return AnalyticsResult(\n", health_calc)
    content = content.replace("summary: summary,\n    );", "summary: summary,\n      healthScore: healthScore,\n    );")

    # 3. Update fromResult to pass healthScore
    content = content.replace("summary: result.summary,", "summary: result.summary,\n      healthScore: result.healthScore,")
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
