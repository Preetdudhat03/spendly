import re

def process():
    path = r'p:\pro\spendly\lib\features\analytics\providers\analytics_providers.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Add import for analytics_models.dart
    if "import '../models/analytics_models.dart';" not in content:
        content = content.replace("import 'package:spendly/models/expense.dart';", 
                                  "import 'package:spendly/models/expense.dart';\nimport '../models/analytics_models.dart';")

    # 2. Add AnalyticsState.fromResult
    # Before the end of AnalyticsState
    from_result_str = """
  factory AnalyticsState.fromResult(AnalyticsResult result, Map<String, Expense> originalExpenses) {
    final agg = result.aggregations;
    
    // Convert ExpenseAnalyticsInput to Expense
    Expense? mapExpense(ExpenseAnalyticsInput e) => originalExpenses[e.id];
    List<Expense> mapExpenses(List<ExpenseAnalyticsInput> list) => list.map(mapExpense).whereType<Expense>().toList();
    
    final filteredExps = mapExpenses(agg.filteredExpenses);
    final previousExps = mapExpenses(agg.previousExpenses);
    
    // We need to recreate CategoryShare, MemberShare etc from the single pass aggregates
    // Category Shares
    final categoryShares = agg.currentCatTotals.entries.map((entry) {
      final category = entry.key;
      final amount = entry.value;
      final percentage = agg.currentTotalSpent > 0 ? (amount / agg.currentTotalSpent) * 100 : 0.0;
      final prevAmount = agg.prevCatTotals[category] ?? 0.0;
      double diffPercent = 0.0;
      if (prevAmount > 0) diffPercent = ((amount - prevAmount) / prevAmount) * 100;
      else if (amount > 0) diffPercent = 100.0;
      
      return CategoryShare(
        category: category,
        amount: amount,
        percentage: percentage,
        prevAmount: prevAmount,
        diffPercent: diffPercent.abs(),
        isIncrease: amount >= prevAmount,
      );
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

    // Member Shares
    final memberShares = agg.currentMemberExpenses.entries.map((entry) {
      final memberId = entry.key;
      final list = entry.value;
      final name = result.input.memberIdToName[memberId] ?? list.first.createdByName;
      final mTotal = list.fold<double>(0, (sum, e) => sum + e.amount);
      final mCount = list.length;
      final mAverage = mTotal / mCount;
      final mLargest = list.fold<double>(0, (maxVal, e) => e.amount > maxVal ? e.amount : maxVal);
      
      final mCatTotals = <String, double>{};
      for (var e in list) mCatTotals[e.category] = (mCatTotals[e.category] ?? 0) + e.amount;
      final favCat = mCatTotals.isEmpty ? 'None' : mCatTotals.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      final mPayTotals = <String, int>{};
      for (var e in list) mPayTotals[e.paymentMethod] = (mPayTotals[e.paymentMethod] ?? 0) + 1;
      final prefPay = mPayTotals.isEmpty ? 'None' : mPayTotals.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      final mPrevList = agg.prevMemberExpenses[memberId] ?? [];
      final mPrevTotal = mPrevList.fold<double>(0, (sum, e) => sum + e.amount);
      double mTrend = 0.0;
      if (mPrevTotal > 0) mTrend = ((mTotal - mPrevTotal) / mPrevTotal) * 100;
      else if (mTotal > 0) mTrend = 100.0;

      return MemberShare(
        memberId: memberId, name: name, totalSpent: mTotal, count: mCount, average: mAverage, 
        largest: mLargest, favoriteCategory: favCat, preferredPaymentMethod: prefPay, monthlyTrend: mTrend,
      );
    }).toList()..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

    // Payment Shares
    final paymentMethodShares = agg.paymentExpenses.entries.map((entry) {
      final method = entry.key;
      final list = entry.value;
      final amt = list.fold<double>(0, (sum, e) => sum + e.amount);
      final percentage = agg.currentTotalSpent > 0 ? (amt / agg.currentTotalSpent) * 100 : 0.0;
      return PaymentMethodShare(method: method, amount: amt, percentage: percentage, count: list.length);
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));
    
    // Top Expenses
    final topExpenses = List<Expense>.from(filteredExps)..sort((a, b) => b.amount.compareTo(a.amount));
    if (topExpenses.length > 10) topExpenses.removeRange(10, topExpenses.length);

    // Trend Spots
    final trendSpots = <TrendPoint>[];
    double currentCum = 0.0;
    final currentDates = agg.currentDailySum.keys.toList()..sort();
    for (var d in currentDates) {
      final amt = agg.currentDailySum[d] ?? 0.0;
      currentCum += amt;
      trendSpots.add(TrendPoint(date: d, amount: amt, cumulativeAmount: currentCum));
    }

    final prevTrendSpots = <TrendPoint>[];
    double prevCum = 0.0;
    final prevDates = agg.prevDailySum.keys.toList()..sort();
    for (var d in prevDates) {
      final amt = agg.prevDailySum[d] ?? 0.0;
      prevCum += amt;
      prevTrendSpots.add(TrendPoint(date: d, amount: amt, cumulativeAmount: prevCum));
    }
    
    // Weekend/Weekday
    double weekendSum = 0; int weekendDays = 0;
    double weekdaySum = 0; int weekdayDays = 0;
    for (var d in currentDates) {
      final amt = agg.dailyBreakdown[d] ?? 0.0;
      if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) { weekendSum += amt; weekendDays++; }
      else { weekdaySum += amt; weekdayDays++; }
    }
    final weekendAvg = weekendDays > 0 ? weekendSum / weekendDays : 0.0;
    final weekdayAvg = weekdayDays > 0 ? weekdaySum / weekdayDays : 0.0;
    double weekendOverspendPercent = 0.0;
    if (weekdayAvg > 0 && weekendAvg > weekdayAvg) weekendOverspendPercent = ((weekendAvg - weekdayAvg) / weekdayAvg) * 100;

    // Recurring
    final recurringExpenses = <RecurringExpenseInfo>[];
    agg.recurGroups.forEach((key, list) {
      if (list.length >= 2) {
        list.sort((a, b) => a.expenseDate.compareTo(b.expenseDate));
        int totalDaysDiff = 0;
        for (int i = 1; i < list.length; i++) totalDaysDiff += list[i].expenseDate.difference(list[i - 1].expenseDate).inDays;
        final double avgDaysDiff = totalDaysDiff / (list.length - 1);
        final avgAmount = list.fold<double>(0, (sum, e) => sum + e.amount) / list.length;
        
        String freq = ''; Duration addDuration = const Duration(days: 30);
        if (avgDaysDiff >= 5 && avgDaysDiff <= 9) { freq = 'Weekly'; addDuration = const Duration(days: 7); }
        else if (avgDaysDiff >= 25 && avgDaysDiff <= 35) { freq = 'Monthly'; addDuration = const Duration(days: 30); }
        else if (avgDaysDiff >= 12 && avgDaysDiff <= 17) { freq = 'Bi-Weekly'; addDuration = const Duration(days: 14); }
        
        if (freq.isNotEmpty) {
          final lastDate = list.last.expenseDate;
          final nextExpected = lastDate.add(addDuration);
          recurringExpenses.add(RecurringExpenseInfo(title: list.first.description, category: list.first.category, amount: avgAmount, frequency: freq, nextExpectedDate: nextExpected));
        }
      }
    });

    double totalSpentDiffPercent = 0.0;
    if (agg.prevTotalSpent > 0) totalSpentDiffPercent = ((agg.currentTotalSpent - agg.prevTotalSpent) / agg.prevTotalSpent) * 100;
    else if (agg.currentTotalSpent > 0) totalSpentDiffPercent = 100.0;

    final currentDays = currentDates.length > 0 ? currentDates.length : 1;
    final prevDays = prevDates.length > 0 ? prevDates.length : 1;
    double dailyAverage = agg.currentTotalSpent / currentDays;
    
    // Forecast & Budget
    double projectedMonthEnd = 0.0;
    double expectedOverspend = 0.0;
    final ranges = _calculateDateRanges(AnalyticsFilterType.values[result.input.filterTypeIndex], result.input.customRange, result.input.now);
    final currentRange = ranges[0];
    final prevRange = ranges[1];
    
    if (AnalyticsFilterType.values[result.input.filterTypeIndex] == AnalyticsFilterType.thisMonth && currentRange.start.month == result.input.now.month && currentRange.start.year == result.input.now.year) {
      final daysInMonth = DateUtils.getDaysInMonth(result.input.now.year, result.input.now.month);
      final elapsedDays = result.input.now.day > 0 ? result.input.now.day : 1;
      dailyAverage = agg.currentTotalSpent / elapsedDays;
      final remainingDays = daysInMonth - elapsedDays;
      projectedMonthEnd = agg.currentTotalSpent + (dailyAverage * remainingDays);
      expectedOverspend = (projectedMonthEnd - result.input.budgetLimit) > 0 ? (projectedMonthEnd - result.input.budgetLimit) : 0.0;
    }

    double prevDailyAverage = agg.prevTotalSpent / prevDays;
    double dailyAverageDiffPercent = 0.0;
    if (prevDailyAverage > 0) dailyAverageDiffPercent = ((dailyAverage - prevDailyAverage) / prevDailyAverage) * 100;
    else if (dailyAverage > 0) dailyAverageDiffPercent = 100.0;

    final budgetRemaining = (result.input.budgetLimit - agg.currentTotalSpent) > 0 ? (result.input.budgetLimit - agg.currentTotalSpent) : 0.0;
    double budgetProgressPercent = result.input.budgetLimit > 0 ? (agg.currentTotalSpent / result.input.budgetLimit) : 0.0;
    if (budgetProgressPercent > 1.0) budgetProgressPercent = 1.0;

    // Health Score (Compatibility)
    int budgetControlScore = 100;
    if (agg.currentTotalSpent > result.input.budgetLimit) budgetControlScore -= ((agg.currentTotalSpent - result.input.budgetLimit) / result.input.budgetLimit * 100).toInt().clamp(0, 100);
    int weekendDisciplineScore = 100;
    if (weekendOverspendPercent > 40) weekendDisciplineScore -= 40;
    else if (weekendOverspendPercent > 20) weekendDisciplineScore -= 20;
    int diversityScore = 100;
    if (filteredExps.length >= 6 && categoryShares.length <= 2) diversityScore -= 40;
    int savingPotentialScore = 100;
    for (var cat in categoryShares) if ((cat.category.toLowerCase() == 'shopping' || cat.category.toLowerCase() == 'entertainment') && cat.percentage > 45.0) savingPotentialScore -= 50;
    
    budgetControlScore = budgetControlScore.clamp(0, 100);
    weekendDisciplineScore = weekendDisciplineScore.clamp(0, 100);
    diversityScore = diversityScore.clamp(0, 100);
    savingPotentialScore = savingPotentialScore.clamp(0, 100);
    final totalScore = ((budgetControlScore + weekendDisciplineScore + diversityScore + savingPotentialScore) / 4).toInt();
    
    String scoreLabel = 'Excellent';
    if (totalScore < 50) scoreLabel = 'Needs Improvement';
    else if (totalScore < 75) scoreLabel = 'Average';
    else if (totalScore < 90) scoreLabel = 'Good';

    final healthMetrics = FinancialHealthMetrics(budgetControl: budgetControlScore, savingPotential: savingPotentialScore, categoryDiversity: diversityScore, weekendDiscipline: weekendDisciplineScore, totalScore: totalScore);

    return AnalyticsState(
      filterType: AnalyticsFilterType.values[result.input.filterTypeIndex],
      dateRange: currentRange,
      previousDateRange: prevRange,
      filteredExpenses: filteredExps,
      previousExpenses: previousExps,
      isLoading: false,
      totalSpent: agg.currentTotalSpent,
      prevTotalSpent: agg.prevTotalSpent,
      totalSpentDiffPercent: totalSpentDiffPercent,
      dailyAverage: dailyAverage,
      prevDailyAverage: prevDailyAverage,
      dailyAverageDiffPercent: dailyAverageDiffPercent,
      totalTransactions: filteredExps.length,
      prevTotalTransactions: previousExps.length,
      activeMembersCount: result.input.activeMembersCount,
      budgetRemaining: budgetRemaining,
      budgetProgressPercent: budgetProgressPercent,
      budgetLimit: result.input.budgetLimit,
      projectedMonthEnd: projectedMonthEnd,
      expectedOverspend: expectedOverspend,
      categoryShares: categoryShares,
      memberShares: memberShares,
      paymentMethodShares: paymentMethodShares,
      topExpenses: topExpenses,
      heatmapData: agg.heatmapData,
      calendarData: agg.calendarData,
      trendSpots: trendSpots,
      prevTrendSpots: prevTrendSpots,
      weekendAvg: weekendAvg,
      weekdayAvg: weekdayAvg,
      weekendOverspendPercent: weekendOverspendPercent,
      recurringExpenses: recurringExpenses,
      savingsOpportunities: [], // Skipped heavy generation for UI compat, or keep old?
      healthMetrics: healthMetrics,
      healthScoreLabel: scoreLabel,
      aiInsights: [],
      aiRecommendations: [],
      timeOfDayCounts: agg.timeOfDayCounts,
      timeOfDayAmounts: agg.timeOfDayAmounts,
    );
  }
"""
    if "factory AnalyticsState.fromResult(" not in content:
        content = content.replace('} // Active Filter Type State Provider', from_result_str + '\n}\n\n// Active Filter Type State Provider')

    # Wait, the closing brace of AnalyticsState is just before `// Active Filter Type State Provider`
    
    # 3. Modify AnalyticsComputeParams -> removed and handled by Python? No, let's just do it directly.
    # We will replace `class AnalyticsComputeParams` up to the end of the file with our new implementation.
    
    # Actually, we can just rewrite the whole _triggerCalculation and _runCalculations.
    # It's cleaner to rewrite the whole file using regex or split.

    parts = content.split('class AnalyticsComputeParams {')
    if len(parts) > 1:
        top = parts[0]
        
        # We need to insert `fromResult` inside `AnalyticsState`
        if 'factory AnalyticsState.fromResult' not in top:
            # find end of AnalyticsState
            match = re.search(r'  }\n}\n\n// Active Filter Type', top)
            if match:
                top = top.replace('  }\n}\n\n// Active Filter Type', '  }\n' + from_result_str + '}\n\n// Active Filter Type')
        
        new_bottom = """
// Primary Analytics Calculations Provider
final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  final expenseState = ref.watch(expenseProvider);
  final budgetState = ref.watch(budgetProvider);
  final familyState = ref.watch(familyProvider);
  final filterType = ref.watch(analyticsFilterTypeProvider);
  final customRange = ref.watch(analyticsCustomDateRangeProvider);
  final selectedMemberId = ref.watch(analyticsMemberFilterProvider);

  return AnalyticsNotifier(
    expenseState: expenseState,
    budgetState: budgetState,
    familyState: familyState,
    filterType: filterType,
    customRange: customRange,
    selectedMemberId: selectedMemberId,
  );
});

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  AnalyticsNotifier({
    required ExpenseState expenseState,
    required BudgetState budgetState,
    required FamilyState familyState,
    required AnalyticsFilterType filterType,
    required DateTimeRange? customRange,
    required String? selectedMemberId,
  }) : super(AnalyticsNotifier._createInitialState(filterType, customRange)) {
    _triggerCalculation(expenseState, budgetState, familyState, filterType, customRange, selectedMemberId);
  }

  static AnalyticsState _createInitialState(AnalyticsFilterType filterType, DateTimeRange? customRange) {
    final ranges = _calculateDateRanges(filterType, customRange, DateTime.now());
    return AnalyticsState.initial(ranges[0], ranges[1]);
  }

  static List<DateTimeRange> _calculateDateRanges(AnalyticsFilterType filterType, DateTimeRange? customRange, DateTime now) {
    DateTime start;
    DateTime end;
    DateTime prevStart;
    DateTime prevEnd;

    switch (filterType) {
      case AnalyticsFilterType.today:
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        prevStart = start.subtract(const Duration(days: 1));
        prevEnd = end.subtract(const Duration(days: 1));
        break;
      case AnalyticsFilterType.last7Days:
        start = DateUtils.dateOnly(now.subtract(const Duration(days: 6)));
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        prevStart = start.subtract(const Duration(days: 7));
        prevEnd = start.subtract(const Duration(seconds: 1));
        break;
      case AnalyticsFilterType.thisMonth:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month, DateUtils.getDaysInMonth(now.year, now.month), 23, 59, 59);
        final lastMonthDate = DateTime(now.year, now.month - 1, 1);
        prevStart = DateTime(lastMonthDate.year, lastMonthDate.month, 1);
        prevEnd = DateTime(lastMonthDate.year, lastMonthDate.month, DateUtils.getDaysInMonth(lastMonthDate.year, lastMonthDate.month), 23, 59, 59);
        break;
      case AnalyticsFilterType.lastMonth:
        final lastMonthDate = DateTime(now.year, now.month - 1, 1);
        start = DateTime(lastMonthDate.year, lastMonthDate.month, 1);
        end = DateTime(lastMonthDate.year, lastMonthDate.month, DateUtils.getDaysInMonth(lastMonthDate.year, lastMonthDate.month), 23, 59, 59);
        
        final twoMonthsAgoDate = DateTime(now.year, now.month - 2, 1);
        prevStart = DateTime(twoMonthsAgoDate.year, twoMonthsAgoDate.month, 1);
        prevEnd = DateTime(twoMonthsAgoDate.year, twoMonthsAgoDate.month, DateUtils.getDaysInMonth(twoMonthsAgoDate.year, twoMonthsAgoDate.month), 23, 59, 59);
        break;
      case AnalyticsFilterType.last3Months:
        start = DateUtils.dateOnly(now.subtract(const Duration(days: 89)));
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        prevStart = start.subtract(const Duration(days: 90));
        prevEnd = start.subtract(const Duration(seconds: 1));
        break;
      case AnalyticsFilterType.last6Months:
        start = DateUtils.dateOnly(now.subtract(const Duration(days: 179)));
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        prevStart = start.subtract(const Duration(days: 180));
        prevEnd = start.subtract(const Duration(seconds: 1));
        break;
      case AnalyticsFilterType.thisYear:
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
        prevStart = DateTime(now.year - 1, 1, 1);
        prevEnd = DateTime(now.year - 1, 12, 31, 23, 59, 59);
        break;
      case AnalyticsFilterType.customDate:
        if (customRange != null) {
          start = DateUtils.dateOnly(customRange.start);
          end = DateTime(customRange.end.year, customRange.end.month, customRange.end.day, 23, 59, 59);
          final diff = end.difference(start);
          prevStart = start.subtract(diff);
          prevEnd = start.subtract(const Duration(seconds: 1));
        } else {
          start = DateTime(now.year, now.month, 1);
          end = DateTime(now.year, now.month, DateUtils.getDaysInMonth(now.year, now.month), 23, 59, 59);
          final lastMonthDate = DateTime(now.year, now.month - 1, 1);
          prevStart = DateTime(lastMonthDate.year, lastMonthDate.month, 1);
          prevEnd = DateTime(lastMonthDate.year, lastMonthDate.month, DateUtils.getDaysInMonth(lastMonthDate.year, lastMonthDate.month), 23, 59, 59);
        }
        break;
    }

    return [
      DateTimeRange(start: start, end: end),
      DateTimeRange(start: prevStart, end: prevEnd)
    ];
  }

  Future<void> _triggerCalculation(
    ExpenseState expenseState,
    BudgetState budgetState,
    FamilyState familyState,
    AnalyticsFilterType filterType,
    DateTimeRange? customRange,
    String? selectedMemberId,
  ) async {
    if (expenseState.isLoading) {
      state = state.copyWith(isLoading: true);
      return;
    }

    final input = AnalyticsInput(
      expenses: expenseState.expenses.map((e) => ExpenseAnalyticsInput(
        id: e.id,
        amount: e.amount,
        category: e.category,
        description: e.description,
        paymentMethod: e.paymentMethod,
        expenseDate: e.expenseDate,
        createdBy: e.createdBy,
        createdByName: e.createdByName,
      )).toList(),
      budgetLimit: budgetState.currentBudget?.monthlyBudget ?? 20000.0,
      activeMembersCount: familyState.members.isEmpty ? 1 : familyState.members.length,
      filterTypeIndex: filterType.index,
      customRange: customRange,
      memberIdToName: { for (var m in familyState.members) m.userId: m.displayName },
      selectedMemberId: selectedMemberId,
      now: DateTime.now(),
      calculationVersion: 1,
    );

    // Compute in background isolate to prevent UI freezing
    final result = await compute(_runCalculations, input);
    if (mounted) {
      final originalExpensesMap = { for (var e in expenseState.expenses) e.id: e };
      state = AnalyticsState.fromResult(result, originalExpensesMap);
    }
  }

  // Top-level static function for Isolate processing
  static AnalyticsResult _runCalculations(AnalyticsInput params) {
    final filterType = AnalyticsFilterType.values[params.filterTypeIndex];
    final ranges = _calculateDateRanges(filterType, params.customRange, params.now);
    final currentRange = ranges[0];
    final prevRange = ranges[1];

    // ONE O(N) Aggregation Pass
    final filteredExpenses = <ExpenseAnalyticsInput>[];
    final previousExpenses = <ExpenseAnalyticsInput>[];
    
    double currentTotalSpent = 0.0;
    double prevTotalSpent = 0.0;
    
    final currentCatTotals = <String, double>{};
    final prevCatTotals = <String, double>{};
    
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
      }
    }

    final agg = AggregationResult(
      filteredExpenses: filteredExpenses,
      previousExpenses: previousExpenses,
      currentTotalSpent: currentTotalSpent,
      prevTotalSpent: prevTotalSpent,
      currentCatTotals: currentCatTotals,
      prevCatTotals: prevCatTotals,
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

    return AnalyticsResult(
      input: params,
      confidence: confidence,
      aggregations: agg,
    );
  }
}
"""
        content = top + new_bottom

        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)

if __name__ == '__main__':
    process()
