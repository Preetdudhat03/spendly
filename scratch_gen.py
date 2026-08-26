import re

def process():
    p = r'p:\pro\spendly\lib\features\analytics\models\analytics_models.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()

    # It's better to just append the serialization to a new file or use a robust AST tool.
    # Since we can't easily parse Dart with Python regex, I'll just write a script that does it semi-manually for the specific classes.

    # 1. TrendDirection
    # No need, it's an enum. We can use .name and .values.byName()

    # 2. PeriodComparison
    content = content.replace("class PeriodComparison {", """class PeriodComparison {
  Map<String, dynamic> toJson() => {
    'currentValue': currentValue,
    'previousValue': previousValue,
    'absoluteChange': absoluteChange,
    'percentageChange': percentageChange,
    'direction': direction.name,
  };
  factory PeriodComparison.fromJson(Map<String, dynamic> json) => PeriodComparison(
    currentValue: json['currentValue'] as double,
    previousValue: json['previousValue'] as double,
    absoluteChange: json['absoluteChange'] as double,
    percentageChange: json['percentageChange'] as double,
    direction: TrendDirection.values.byName(json['direction'] as String),
  );
""")

    # 3. ExecutiveSummary
    content = content.replace("class ExecutiveSummary {", """class ExecutiveSummary {
  Map<String, dynamic> toJson() => {
    'totalSpend': totalSpend.toJson(),
    'dailyAverage': dailyAverage.toJson(),
    'transactionCount': transactionCount.toJson(),
  };
  factory ExecutiveSummary.fromJson(Map<String, dynamic> json) => ExecutiveSummary(
    totalSpend: PeriodComparison.fromJson(json['totalSpend']),
    dailyAverage: PeriodComparison.fromJson(json['dailyAverage']),
    transactionCount: PeriodComparison.fromJson(json['transactionCount']),
  );
""")

    # 4. VelocityStatus
    # Enum, use .name

    # 5. CategoryInsight
    content = content.replace("class CategoryInsight {", """class CategoryInsight {
  Map<String, dynamic> toJson() => {
    'categoryName': categoryName,
    'currentSpend': currentSpend,
    'previousSpend': previousSpend,
    'trend': trend.toJson(),
    'percentageOfTotal': percentageOfTotal,
    'transactionCount': transactionCount,
    'averageTransaction': averageTransaction,
    'largestTransaction': largestTransaction,
  };
  factory CategoryInsight.fromJson(Map<String, dynamic> json) => CategoryInsight(
    categoryName: json['categoryName'] as String,
    currentSpend: json['currentSpend'] as double,
    previousSpend: json['previousSpend'] as double,
    trend: PeriodComparison.fromJson(json['trend']),
    percentageOfTotal: json['percentageOfTotal'] as double,
    transactionCount: json['transactionCount'] as int,
    averageTransaction: json['averageTransaction'] as double,
    largestTransaction: json['largestTransaction'] as double,
  );
""")

    # 6. MemberInsight
    content = content.replace("class MemberInsight {", """class MemberInsight {
  Map<String, dynamic> toJson() => {
    'memberId': memberId,
    'memberName': memberName,
    'currentSpend': currentSpend,
    'trend': trend.toJson(),
    'percentageOfTotal': percentageOfTotal,
    'transactionCount': transactionCount,
    'averageTransaction': averageTransaction,
    'topCategory': topCategory,
  };
  factory MemberInsight.fromJson(Map<String, dynamic> json) => MemberInsight(
    memberId: json['memberId'] as String,
    memberName: json['memberName'] as String,
    currentSpend: json['currentSpend'] as double,
    trend: PeriodComparison.fromJson(json['trend']),
    percentageOfTotal: json['percentageOfTotal'] as double,
    transactionCount: json['transactionCount'] as int,
    averageTransaction: json['averageTransaction'] as double,
    topCategory: json['topCategory'] as String,
  );
""")

    # 7. DiagnosticIntelligence
    content = content.replace("class DiagnosticIntelligence {", """class DiagnosticIntelligence {
  Map<String, dynamic> toJson() => {
    'categoryInsights': categoryInsights.map((e) => e.toJson()).toList(),
    'memberInsights': memberInsights.map((e) => e.toJson()).toList(),
    'topCategoryShare': topCategoryShare,
    'top3CategoryShare': top3CategoryShare,
    'primaryIncreaseContributor': primaryIncreaseContributor,
    'primaryDecreaseContributor': primaryDecreaseContributor,
    'purchasesUnder200': purchasesUnder200,
  };
  factory DiagnosticIntelligence.fromJson(Map<String, dynamic> json) => DiagnosticIntelligence(
    categoryInsights: (json['categoryInsights'] as List).map((e) => CategoryInsight.fromJson(e)).toList(),
    memberInsights: (json['memberInsights'] as List).map((e) => MemberInsight.fromJson(e)).toList(),
    topCategoryShare: json['topCategoryShare'] as double,
    top3CategoryShare: json['top3CategoryShare'] as double,
    primaryIncreaseContributor: json['primaryIncreaseContributor'] as String?,
    primaryDecreaseContributor: json['primaryDecreaseContributor'] as String?,
    purchasesUnder200: json['purchasesUnder200'] as int,
  );
""")

    # 8. SpendingConsistency
    content = content.replace("class SpendingConsistency {", """class SpendingConsistency {
  Map<String, dynamic> toJson() => {
    'standardDeviation': standardDeviation,
    'coefficientOfVariation': coefficientOfVariation,
    'isHighlyVolatile': isHighlyVolatile,
  };
  factory SpendingConsistency.fromJson(Map<String, dynamic> json) => SpendingConsistency(
    standardDeviation: json['standardDeviation'] as double,
    coefficientOfVariation: json['coefficientOfVariation'] as double,
    isHighlyVolatile: json['isHighlyVolatile'] as bool,
  );
""")

    # 9. AnomalyInsight
    content = content.replace("class AnomalyInsight {", """class AnomalyInsight {
  Map<String, dynamic> toJson() => {
    'categoryName': categoryName,
    'amount': amount,
    'historicalAverage': historicalAverage,
    'deviationPercentage': deviationPercentage,
  };
  factory AnomalyInsight.fromJson(Map<String, dynamic> json) => AnomalyInsight(
    categoryName: json['categoryName'] as String,
    amount: json['amount'] as double,
    historicalAverage: json['historicalAverage'] as double,
    deviationPercentage: json['deviationPercentage'] as double,
  );
""")

    # 10. HighSpendingDayInsight
    content = content.replace("class HighSpendingDayInsight {", """class HighSpendingDayInsight {
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'amount': amount,
    'reason': reason,
  };
  factory HighSpendingDayInsight.fromJson(Map<String, dynamic> json) => HighSpendingDayInsight(
    date: DateTime.parse(json['date']),
    amount: json['amount'] as double,
    reason: json['reason'] as String,
  );
""")

    # 11. PatternIntelligence
    content = content.replace("class PatternIntelligence {", """class PatternIntelligence {
  Map<String, dynamic> toJson() => {
    'consistency': consistency.toJson(),
    'anomalies': anomalies.map((e) => e.toJson()).toList(),
    'highSpendingDays': highSpendingDays.map((e) => e.toJson()).toList(),
    'recurringLoad': recurringLoad,
    'recurringCount': recurringCount,
    'weekendVsWeekdayRatio': weekendVsWeekdayRatio,
  };
  factory PatternIntelligence.fromJson(Map<String, dynamic> json) => PatternIntelligence(
    consistency: SpendingConsistency.fromJson(json['consistency']),
    anomalies: (json['anomalies'] as List).map((e) => AnomalyInsight.fromJson(e)).toList(),
    highSpendingDays: (json['highSpendingDays'] as List).map((e) => HighSpendingDayInsight.fromJson(e)).toList(),
    recurringLoad: json['recurringLoad'] as double,
    recurringCount: json['recurringCount'] as int,
    weekendVsWeekdayRatio: json['weekendVsWeekdayRatio'] as double,
  );
""")

    # 12. BudgetForecast
    content = content.replace("class BudgetForecast {", """class BudgetForecast {
  Map<String, dynamic> toJson() => {
    'projectedTotal': projectedTotal,
    'expectedOverrun': expectedOverrun,
    'currentPace': currentPace,
    'velocityStatus': velocityStatus.name,
    'recommendedDailyLimit': recommendedDailyLimit,
  };
  factory BudgetForecast.fromJson(Map<String, dynamic> json) => BudgetForecast(
    projectedTotal: json['projectedTotal'] as double,
    expectedOverrun: json['expectedOverrun'] as double,
    currentPace: json['currentPace'] as double,
    velocityStatus: VelocityStatus.values.byName(json['velocityStatus'] as String),
    recommendedDailyLimit: json['recommendedDailyLimit'] as double,
  );
""")

    # 13. SpendingHealth
    content = content.replace("class SpendingHealth {", """class SpendingHealth {
  Map<String, dynamic> toJson() => {
    'score': score,
    'adherenceScore': adherenceScore,
    'velocityScore': velocityScore,
    'stabilityScore': stabilityScore,
    'anomalyScore': anomalyScore,
    'concentrationScore': concentrationScore,
    'confidenceScore': confidenceScore,
  };
  factory SpendingHealth.fromJson(Map<String, dynamic> json) => SpendingHealth(
    score: json['score'] as int,
    adherenceScore: json['adherenceScore'] as int,
    velocityScore: json['velocityScore'] as int,
    stabilityScore: json['stabilityScore'] as int,
    anomalyScore: json['anomalyScore'] as int,
    concentrationScore: json['concentrationScore'] as int,
    confidenceScore: json['confidenceScore'] as int,
  );
""")

    # 14. FactImportance (enum)

    # 15. InsightFact
    content = content.replace("class InsightFact {", """class InsightFact {
  Map<String, dynamic> toJson() => {
    'factId': factId,
    'importance': importance.name,
    'factData': factData,
  };
  factory InsightFact.fromJson(Map<String, dynamic> json) => InsightFact(
    factId: json['factId'] as String,
    importance: FactImportance.values.byName(json['importance'] as String),
    factData: Map<String, dynamic>.from(json['factData']),
  );
""")

    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
