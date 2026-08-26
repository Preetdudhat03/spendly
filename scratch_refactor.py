import re

def process():
    p = r'p:\pro\spendly\lib\features\analytics\presentation\widgets\category_donut_chart.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()

    # Import InsightDrillDownSheet & AnalyticsModels
    import_models = "import 'package:spendly/features/analytics/models/analytics_models.dart';"
    if import_models not in content:
        content = content.replace("import 'package:spendly/features/analytics/providers/analytics_providers.dart';", "import 'package:spendly/features/analytics/providers/analytics_providers.dart';\n" + import_models)
        
    import_drill = "import 'package:spendly/features/analytics/presentation/widgets/insight_drill_down_sheet.dart';"
    if import_drill not in content:
        content = content.replace("import 'drill_down_sheet.dart';", "import 'drill_down_sheet.dart';\n" + import_drill)
    
    # 1. Change _showCategoryDetails signature and body
    old_show_details = """  void _showCategoryDetails(BuildContext context, CategoryShare share) {
    final meta = getCategoryMetadata(context, share.category);

    // Filter transactions for this category in current range
    final categoryExpenses =
        widget.state.filteredExpenses
            .where(
              (e) => e.category.toLowerCase() == share.category.toLowerCase(),
            )
            .toList()
          ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

    DrillDownSheet.show(
      context,
      title: meta.name,
      subtitle: '${share.percentage.toStringAsFixed(0)}% of total spending',
      icon: Icons
          .category, // You could use a specific icon or just use the emoji text in a custom way. We'll use a generic icon for now.
      color: meta.color,
      totalAmount: share.amount,
      expenses: categoryExpenses,
      aiSummary:
          'This category makes up ${share.percentage.toStringAsFixed(0)}% of your expenses. Consider looking for bulk discounts if applicable.',
    );
  }"""
  
    new_show_details = """  void _showCategoryDetails(BuildContext context, CategoryInsight insight) {
    final meta = getCategoryMetadata(context, insight.categoryName);
    
    InsightDrillDownSheet.showForCategory(
      context,
      insight: insight,
      icon: Icons.category,
      color: meta.color,
    );
  }"""
    content = content.replace(old_show_details, new_show_details)
    
    # 2. Replace widget.state.categoryShares.isEmpty -> (widget.state.diagnostic?.categoryInsights.isEmpty ?? true)
    content = content.replace("if (widget.state.categoryShares.isEmpty) {", "if (widget.state.diagnostic?.categoryInsights.isEmpty ?? true) {")
    
    # 3. Replace widget.state.categoryShares.length -> widget.state.diagnostic!.categoryInsights.length
    content = content.replace("widget.state.categoryShares.length", "widget.state.diagnostic!.categoryInsights.length")
    
    # 4. Replace widget.state.categoryShares[i] -> widget.state.diagnostic!.categoryInsights[i]
    content = content.replace("widget.state.categoryShares[i]", "widget.state.diagnostic!.categoryInsights[i]")
    
    # 5. Replace widget.state.categoryShares[idx] -> widget.state.diagnostic!.categoryInsights[idx]
    content = content.replace("widget.state.categoryShares[idx]", "widget.state.diagnostic!.categoryInsights[idx]")
    
    # 6. Replace widget.state.categoryShares[touchedIndex] -> widget.state.diagnostic!.categoryInsights[touchedIndex]
    content = content.replace("widget.state.categoryShares[touchedIndex]", "widget.state.diagnostic!.categoryInsights[touchedIndex]")
    
    # 7. Replace share.category -> share.categoryName
    content = content.replace("share.category", "share.categoryName")
    
    # 8. Replace share.amount -> share.currentSpend
    content = content.replace("share.amount", "share.currentSpend")
    
    # 9. Replace share.percentage -> share.percentageOfTotal
    content = content.replace("share.percentage", "share.percentageOfTotal")
    
    # 10. Replace widget.state.totalSpent -> widget.state.summary?.totalSpend.currentValue ?? widget.state.totalSpent
    content = content.replace("widget.state.totalSpent", "(widget.state.summary?.totalSpend.currentValue ?? widget.state.totalSpent)")

    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
