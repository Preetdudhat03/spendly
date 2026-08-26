import re

def process():
    path = r'p:\pro\spendly\lib\features\analytics\models\analytics_models.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    new_models = """
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
"""

    if "class CategoryInsight" not in content:
        content = content.replace("class SpendingVelocity {", new_models + "\nclass SpendingVelocity {")
        
    # Add diagnosticIntelligence to AnalyticsResult
    if "final DiagnosticIntelligence diagnostic;" not in content:
        content = content.replace("final SpendingHealth healthScore;", "final DiagnosticIntelligence diagnostic;\n  final SpendingHealth healthScore;")
        content = content.replace("required this.budgetForecast,", "required this.budgetForecast,\n    required this.diagnostic,")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
