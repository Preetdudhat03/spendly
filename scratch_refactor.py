import re

def process():
    path = r'p:\pro\spendly\lib\features\analytics\providers\analytics_providers.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Update AnalyticsState
    if "final SpendingVelocity? velocity;" not in content:
        content = content.replace("final SpendingHealth? healthScore;", "final SpendingVelocity? velocity;\n  final BudgetForecast? budgetForecast;\n  final SpendingHealth? healthScore;")
        content = content.replace("this.healthScore,", "this.velocity,\n    this.budgetForecast,\n    this.healthScore,")
    
    # 2. Update runCalculations
    calc_from = """    final healthScore = SpendingHealth.calculate(
      totalSpent: currentTotalSpent,
      budgetLimit: params.budgetLimit,
      elapsedDays: currentElapsedDays,
      daysInMonth: DateUtils.getDaysInMonth(params.now.year, params.now.month),
      confidence: confidence,
      topCategoryPercentage: topCategoryPercentage,
    );

    return AnalyticsResult("""
    
    calc_to = """    final daysInMonth = DateUtils.getDaysInMonth(params.now.year, params.now.month);
    
    final velocity = SpendingVelocity.calculate(
      totalSpent: currentTotalSpent,
      budgetLimit: params.budgetLimit,
      elapsedDays: currentElapsedDays,
      totalDays: daysInMonth,
    );

    final budgetForecast = BudgetForecast.calculate(
      currentTotalSpent: currentTotalSpent,
      currentDailyAvg: currentDailyAvg,
      budgetLimit: params.budgetLimit,
      remainingDays: daysInMonth - currentElapsedDays,
    );

    final healthScore = SpendingHealth.calculate(
      totalSpent: currentTotalSpent,
      budgetLimit: params.budgetLimit,
      elapsedDays: currentElapsedDays,
      daysInMonth: daysInMonth,
      confidence: confidence,
      topCategoryPercentage: topCategoryPercentage,
      velocity: velocity,
    );

    return AnalyticsResult("""
    
    content = content.replace(calc_from, calc_to)
    
    res_from = """      healthScore: healthScore,
    );"""
    res_to = """      velocity: velocity,
      budgetForecast: budgetForecast,
      healthScore: healthScore,
    );"""
    content = content.replace(res_from, res_to)
    
    # 3. Update fromResult mappings
    map_from = """    // Forecast & Budget
    double projectedMonthEnd = 0.0;
    double expectedOverspend = 0.0;
    final ranges = AnalyticsNotifier._calculateDateRanges(
      AnalyticsFilterType.values[result.input.filterTypeIndex],
      result.input.customRange,
      result.input.now,
    );
    final currentRange = ranges[0];
    final prevRange = ranges[1];
    
    if (AnalyticsFilterType.values[result.input.filterTypeIndex] == AnalyticsFilterType.thisMonth && currentRange.start.month == result.input.now.month && currentRange.start.year == result.input.now.year) {
      final daysInMonth = DateUtils.getDaysInMonth(result.input.now.year, result.input.now.month);
      final elapsedDays = result.input.now.day > 0 ? result.input.now.day : 1;
      dailyAverage = agg.currentTotalSpent / elapsedDays;
      final remainingDays = daysInMonth - elapsedDays;
      projectedMonthEnd = agg.currentTotalSpent + (dailyAverage * remainingDays);
      expectedOverspend = (projectedMonthEnd - result.input.budgetLimit) > 0 ? (projectedMonthEnd - result.input.budgetLimit) : 0.0;
    }"""
    
    map_to = """    // Forecast & Budget
    final ranges = AnalyticsNotifier._calculateDateRanges(
      AnalyticsFilterType.values[result.input.filterTypeIndex],
      result.input.customRange,
      result.input.now,
    );
    final currentRange = ranges[0];
    final prevRange = ranges[1];
    
    double projectedMonthEnd = result.budgetForecast.projectedTotal;
    double expectedOverspend = result.budgetForecast.expectedOverrun;"""
    
    content = content.replace(map_from, map_to)
    
    # Add to AnalyticsState constructor in fromResult
    content = content.replace("summary: result.summary,\n      healthScore: result.healthScore,", "summary: result.summary,\n      velocity: result.velocity,\n      budgetForecast: result.budgetForecast,\n      healthScore: result.healthScore,")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
