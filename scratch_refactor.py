import re

def process():
    path = r'p:\pro\spendly\lib\features\analytics\providers\analytics_providers.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Step 1: Update runCalculations to compute equivalent variables and summary
    # We will replace everything from `// ONE O(N) Aggregation Pass` down to `return AnalyticsResult(`
    
    parts = content.split('    // ONE O(N) Aggregation Pass')
    top = parts[0]
    bottom_parts = parts[1].split('    return AnalyticsResult(')
    bottom = '    return AnalyticsResult(' + bottom_parts[1]
    
    new_aggregation = """    // ONE O(N) Aggregation Pass
    final filteredExpenses = <ExpenseAnalyticsInput>[];
    final previousExpenses = <ExpenseAnalyticsInput>[];
    
    double currentTotalSpent = 0.0;
    double prevTotalSpent = 0.0;
    double equivalentPrevTotalSpent = 0.0;
    int equivalentPrevTransactionCount = 0;
    
    final currentCatTotals = <String, double>{};
    final prevCatTotals = <String, double>{};
    final equivalentPrevCatTotals = <String, double>{};
    
    final currentMemberExpenses = <String, List<ExpenseAnalyticsInput>>{};
    final prevMemberExpenses = <String, List<ExpenseAnalyticsInput>>{};
    
    final paymentExpenses = <String, List<ExpenseAnalyticsInput>>{};
    
    final heatmapData = <DateTime, double>{};
    final calendarData = <DateTime, double>{};
    
    final currentDailySum = <DateTime, double>{};
    final prevDailySum = <DateTime, double>{};
    
    final dailyBreakdown = <DateTime, double>{};
    
    final timeOfDayCounts = <String, int>{'Morning': 0, 'Afternoon': 0, 'Evening': 0, 'Night': 0};
    final timeOfDayAmounts = <String, double>{'Morning': 0.0, 'Afternoon': 0.0, 'Evening': 0.0, 'Night': 0.0};
    
    final recurGroups = <String, List<ExpenseAnalyticsInput>>{};

    // Calculate strictly equivalent previous period end date
    DateTime equivalentPrevEnd = prevRange.end;
    bool isPartialPeriod = false;
    if (filterType == AnalyticsFilterType.thisMonth || filterType == AnalyticsFilterType.thisYear) {
      if (params.now.isBefore(currentRange.end)) {
        isPartialPeriod = true;
        if (filterType == AnalyticsFilterType.thisMonth) {
          int targetDay = params.now.day;
          int prevDaysInMonth = DateUtils.getDaysInMonth(prevRange.start.year, prevRange.start.month);
          if (targetDay > prevDaysInMonth) targetDay = prevDaysInMonth;
          equivalentPrevEnd = DateTime(prevRange.start.year, prevRange.start.month, targetDay, 23, 59, 59);
        } else {
          final elapsed = params.now.difference(currentRange.start);
          equivalentPrevEnd = prevRange.start.add(elapsed);
        }
      }
    } else if (filterType == AnalyticsFilterType.customDate && params.customRange == null) {
        // default customDate fallback is this month
        if (params.now.isBefore(currentRange.end)) {
            isPartialPeriod = true;
            int targetDay = params.now.day;
            int prevDaysInMonth = DateUtils.getDaysInMonth(prevRange.start.year, prevRange.start.month);
            if (targetDay > prevDaysInMonth) targetDay = prevDaysInMonth;
            equivalentPrevEnd = DateTime(prevRange.start.year, prevRange.start.month, targetDay, 23, 59, 59);
        }
    }

    // Setup heatmap / calendar blanks
    final todayOnly = DateUtils.dateOnly(params.now);
    final mondayOfCurrentWeek = DateTime(todayOnly.year, todayOnly.month, todayOnly.day - (todayOnly.weekday - 1));
    final startOfHeatmap = DateTime(mondayOfCurrentWeek.year, mondayOfCurrentWeek.month, mondayOfCurrentWeek.day - 77);
    for (int i = 0; i < 84; i++) heatmapData[DateTime(startOfHeatmap.year, startOfHeatmap.month, startOfHeatmap.day + i)] = 0.0;
    final calMonthEnd = DateTime(params.now.year, params.now.month, DateUtils.getDaysInMonth(params.now.year, params.now.month));
    for (int d = 1; d <= calMonthEnd.day; d++) calendarData[DateTime(params.now.year, params.now.month, d)] = 0.0;
    
    final currentDays = (currentRange.end.difference(currentRange.start).inDays + 1) > 0 ? (currentRange.end.difference(currentRange.start).inDays + 1) : 1;
    for (int i = 0; i < currentDays; i++) currentDailySum[DateUtils.dateOnly(currentRange.start.add(Duration(days: i)))] = 0.0;
    
    final prevDays = (prevRange.end.difference(prevRange.start).inDays + 1) > 0 ? (prevRange.end.difference(prevRange.start).inDays + 1) : 1;
    for (int i = 0; i < prevDays; i++) prevDailySum[DateUtils.dateOnly(prevRange.start.add(Duration(days: i)))] = 0.0;

    for (var e in params.expenses) {
      if (params.selectedMemberId != null && e.createdBy != params.selectedMemberId) continue;
      
      final dateOnly = DateUtils.dateOnly(e.expenseDate);
      
      // Global Maps
      if (heatmapData.containsKey(dateOnly)) heatmapData[dateOnly] = heatmapData[dateOnly]! + e.amount;
      if (dateOnly.year == params.now.year && dateOnly.month == params.now.month) {
        calendarData[dateOnly] = (calendarData[dateOnly] ?? 0.0) + e.amount;
      }
      
      final normalizedTitle = e.description.trim().toLowerCase();
      if (normalizedTitle.length >= 3) {
        recurGroups.putIfAbsent('${e.category.toLowerCase()}_$normalizedTitle', () => []).add(e);
      }

      // Current Range
      if (e.expenseDate.isAfter(currentRange.start.subtract(const Duration(seconds: 1))) && e.expenseDate.isBefore(currentRange.end.add(const Duration(seconds: 1)))) {
        filteredExpenses.add(e);
        currentTotalSpent += e.amount;
        currentCatTotals[e.category] = (currentCatTotals[e.category] ?? 0) + e.amount;
        currentMemberExpenses.putIfAbsent(e.createdBy, () => []).add(e);
        paymentExpenses.putIfAbsent(e.paymentMethod, () => []).add(e);
        
        if (currentDailySum.containsKey(dateOnly)) currentDailySum[dateOnly] = currentDailySum[dateOnly]! + e.amount;
        dailyBreakdown[dateOnly] = (dailyBreakdown[dateOnly] ?? 0) + e.amount;
        
        final hour = e.expenseDate.hour;
        String tod = 'Morning';
        if (hour >= 12 && hour < 17) tod = 'Afternoon';
        else if (hour >= 17 && hour < 21) tod = 'Evening';
        else if (hour >= 21 || hour < 6) tod = 'Night';
        timeOfDayCounts[tod] = timeOfDayCounts[tod]! + 1;
        timeOfDayAmounts[tod] = timeOfDayAmounts[tod]! + e.amount;
      }
      
      // Previous Range
      if (e.expenseDate.isAfter(prevRange.start.subtract(const Duration(seconds: 1))) && e.expenseDate.isBefore(prevRange.end.add(const Duration(seconds: 1)))) {
        previousExpenses.add(e);
        prevTotalSpent += e.amount;
        prevCatTotals[e.category] = (prevCatTotals[e.category] ?? 0) + e.amount;
        prevMemberExpenses.putIfAbsent(e.createdBy, () => []).add(e);
        if (prevDailySum.containsKey(dateOnly)) prevDailySum[dateOnly] = prevDailySum[dateOnly]! + e.amount;
        
        // Equivalent previous
        if (e.expenseDate.isBefore(equivalentPrevEnd.add(const Duration(seconds: 1)))) {
          equivalentPrevTotalSpent += e.amount;
          equivalentPrevTransactionCount++;
          equivalentPrevCatTotals[e.category] = (equivalentPrevCatTotals[e.category] ?? 0) + e.amount;
        }
      }
    }

    final agg = AggregationResult(
      filteredExpenses: filteredExpenses,
      previousExpenses: previousExpenses,
      currentTotalSpent: currentTotalSpent,
      prevTotalSpent: prevTotalSpent,
      equivalentPrevTotalSpent: equivalentPrevTotalSpent,
      equivalentPrevTransactionCount: equivalentPrevTransactionCount,
      currentCatTotals: currentCatTotals,
      prevCatTotals: prevCatTotals,
      equivalentPrevCatTotals: equivalentPrevCatTotals,
      currentMemberExpenses: currentMemberExpenses,
      prevMemberExpenses: prevMemberExpenses,
      paymentExpenses: paymentExpenses,
      heatmapData: heatmapData,
      calendarData: calendarData,
      currentDailySum: currentDailySum,
      prevDailySum: prevDailySum,
      dailyBreakdown: dailyBreakdown,
      timeOfDayCounts: timeOfDayCounts,
      timeOfDayAmounts: timeOfDayAmounts,
      recurGroups: recurGroups,
    );
    
    // Evaluate Data Confidence based on filterType and length
    DataConfidence confidence = DataConfidence.medium;
    if (filteredExpenses.length > 50) confidence = DataConfidence.high;
    if (filteredExpenses.length < 5) confidence = DataConfidence.low;

    // Phase 2: Executive Summary
    int currentElapsedDays = isPartialPeriod ? (params.now.difference(currentRange.start).inDays + 1) : currentDays;
    if (currentElapsedDays < 1) currentElapsedDays = 1;
    
    int prevElapsedDays = isPartialPeriod ? (equivalentPrevEnd.difference(prevRange.start).inDays + 1) : prevDays;
    if (prevElapsedDays < 1) prevElapsedDays = 1;

    final currentDailyAvg = currentTotalSpent / currentElapsedDays;
    final prevDailyAvg = equivalentPrevTotalSpent / prevElapsedDays;

    final summary = ExecutiveSummary(
      totalSpend: PeriodComparison.calculate(currentTotalSpent, equivalentPrevTotalSpent),
      dailyAverage: PeriodComparison.calculate(currentDailyAvg, prevDailyAvg),
      transactionCount: PeriodComparison.calculate(filteredExpenses.length.toDouble(), equivalentPrevTransactionCount.toDouble()),
    );

"""
    content = top + new_aggregation + bottom
    
    # 2. Modify AnalyticsState.fromResult to use the new equivalent sums
    # Currently:
    # double totalSpentDiffPercent = 0.0;
    # if (agg.prevTotalSpent > 0) totalSpentDiffPercent = ((agg.currentTotalSpent - agg.prevTotalSpent) / agg.prevTotalSpent) * 100;
    #
    # We will change it to use summary.totalSpend.percentageChange
    
    # Also modify AnalyticsResult return to include summary
    content = content.replace("    return AnalyticsResult(\n      input: params,\n      confidence: confidence,\n      aggregations: agg,\n    );", 
                              "    return AnalyticsResult(\n      input: params,\n      confidence: confidence,\n      aggregations: agg,\n      summary: summary,\n    );")

    # In `AnalyticsState.fromResult`:
    # `totalSpentDiffPercent: result.summary.totalSpend.percentageChange` instead of calculating it there.
    
    # Let's just do a string replace for totalSpentDiffPercent calculation
    
    replace_from = """    double totalSpentDiffPercent = 0.0;
    if (agg.prevTotalSpent > 0) totalSpentDiffPercent = ((agg.currentTotalSpent - agg.prevTotalSpent) / agg.prevTotalSpent) * 100;
    else if (agg.currentTotalSpent > 0) totalSpentDiffPercent = 100.0;"""
    replace_to = """    double totalSpentDiffPercent = result.summary.totalSpend.percentageChange;"""
    content = content.replace(replace_from, replace_to)
    
    replace_from2 = """    double dailyAverageDiffPercent = 0.0;
    if (prevDailyAverage > 0) dailyAverageDiffPercent = ((dailyAverage - prevDailyAverage) / prevDailyAverage) * 100;
    else if (dailyAverage > 0) dailyAverageDiffPercent = 100.0;"""
    replace_to2 = """    double dailyAverageDiffPercent = result.summary.dailyAverage.percentageChange;"""
    content = content.replace(replace_from2, replace_to2)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
