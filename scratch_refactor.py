import re

def process():
    path = r'p:\pro\spendly\lib\features\analytics\providers\analytics_providers.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    calc_from = """    final healthScore = SpendingHealth.calculate("""
    
    calc_to = """    // Phase 4: Diagnostic Intelligence
    final categoryInsights = <CategoryInsight>[];
    for (var entry in currentCatTotals.entries) {
      final category = entry.key;
      final current = entry.value;
      final previous = equivalentPrevCatTotals[category] ?? 0.0;
      
      double largest = 0.0;
      int count = 0;
      for (var e in filteredExpenses) {
        if (e.category == category) {
          count++;
          if (e.amount > largest) largest = e.amount;
        }
      }
      
      final trend = PeriodComparison.calculate(current, previous);
      final percentage = currentTotalSpent > 0 ? (current / currentTotalSpent) * 100 : 0.0;
      final avg = count > 0 ? current / count : 0.0;
      
      categoryInsights.add(CategoryInsight(
        categoryName: category,
        currentSpend: current,
        previousSpend: previous,
        trend: trend,
        percentageOfTotal: percentage,
        transactionCount: count,
        averageTransaction: avg,
        largestTransaction: largest,
      ));
    }
    
    categoryInsights.sort((a, b) => b.currentSpend.compareTo(a.currentSpend));
    
    final memberInsights = <MemberInsight>[];
    for (var entry in currentMemberExpenses.entries) {
      final memberId = entry.key;
      final list = entry.value;
      final memberName = params.memberIdToName[memberId] ?? list.first.createdByName;
      
      final current = list.fold<double>(0, (sum, e) => sum + e.amount);
      
      double previous = 0.0;
      final prevList = prevMemberExpenses[memberId] ?? [];
      for(var e in prevList) {
         if (e.expenseDate.isBefore(equivalentPrevEnd.add(const Duration(seconds: 1)))) {
            previous += e.amount;
         }
      }
      
      final trend = PeriodComparison.calculate(current, previous);
      final percentage = currentTotalSpent > 0 ? (current / currentTotalSpent) * 100 : 0.0;
      final avg = list.isNotEmpty ? current / list.length : 0.0;
      
      final mCatTotals = <String, double>{};
      for (var e in list) mCatTotals[e.category] = (mCatTotals[e.category] ?? 0) + e.amount;
      final topCat = mCatTotals.isEmpty ? 'None' : mCatTotals.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      
      memberInsights.add(MemberInsight(
        memberId: memberId,
        memberName: memberName,
        currentSpend: current,
        trend: trend,
        percentageOfTotal: percentage,
        transactionCount: list.length,
        averageTransaction: avg,
        topCategory: topCat,
      ));
    }
    
    memberInsights.sort((a, b) => b.currentSpend.compareTo(a.currentSpend));
    
    double topCatShare = 0.0;
    double top3CatShare = 0.0;
    if (categoryInsights.isNotEmpty) topCatShare = categoryInsights[0].percentageOfTotal;
    for (int i = 0; i < categoryInsights.length && i < 3; i++) {
      top3CatShare += categoryInsights[i].percentageOfTotal;
    }
    
    final sortedExpenses = List<ExpenseAnalyticsInput>.from(filteredExpenses)..sort((a, b) => b.amount.compareTo(a.amount));
    double top3TransactionsTotal = 0.0;
    for (int i = 0; i < sortedExpenses.length && i < 3; i++) {
      top3TransactionsTotal += sortedExpenses[i].amount;
    }
    final top3TransactionsShare = currentTotalSpent > 0 ? (top3TransactionsTotal / currentTotalSpent) * 100 : 0.0;
    
    int smallCount = 0;
    double smallTotal = 0.0;
    for (var e in filteredExpenses) {
      if (e.amount <= 200) {
        smallCount++;
        smallTotal += e.amount;
      }
    }
    
    String primaryIncrease = 'None';
    String primaryDecrease = 'None';
    double maxInc = 0;
    double maxDec = 0;
    for (var cat in categoryInsights) {
      if (cat.trend.direction == TrendDirection.increase && cat.trend.absoluteChange > maxInc) {
        maxInc = cat.trend.absoluteChange;
        primaryIncrease = cat.categoryName;
      } else if (cat.trend.direction == TrendDirection.decrease && cat.trend.absoluteChange.abs() > maxDec) {
        maxDec = cat.trend.absoluteChange.abs();
        primaryDecrease = cat.categoryName;
      }
    }
    
    final diagnostic = DiagnosticIntelligence(
      categoryInsights: categoryInsights,
      memberInsights: memberInsights,
      topCategoryShare: topCatShare,
      top3CategoryShare: top3CatShare,
      top3TransactionsTotal: top3TransactionsTotal,
      top3TransactionsShare: top3TransactionsShare,
      smallPurchasesCount: smallCount,
      smallPurchasesTotal: smallTotal,
      primaryIncreaseContributor: primaryIncrease,
      primaryDecreaseContributor: primaryDecrease,
    );

    final healthScore = SpendingHealth.calculate("""
    
    content = content.replace(calc_from, calc_to)
    
    res_from = """      budgetForecast: budgetForecast,
      healthScore: healthScore,
    );"""
    res_to = """      budgetForecast: budgetForecast,
      diagnostic: diagnostic,
      healthScore: healthScore,
    );"""
    content = content.replace(res_from, res_to)
    
    # 2. Add DiagnosticIntelligence? diagnostic to AnalyticsState
    if "final DiagnosticIntelligence? diagnostic;" not in content:
        content = content.replace("final BudgetForecast? budgetForecast;", "final BudgetForecast? budgetForecast;\n  final DiagnosticIntelligence? diagnostic;")
        content = content.replace("this.budgetForecast,", "this.budgetForecast,\n    this.diagnostic,")
        
    # 3. Add to fromResult
    content = content.replace("budgetForecast: result.budgetForecast,", "budgetForecast: result.budgetForecast,\n      diagnostic: result.diagnostic,")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
