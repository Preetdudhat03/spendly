import re
import os

def process():
    # 1. Update category_donut_chart.dart
    p = r'p:\pro\spendly\lib\features\analytics\presentation\widgets\category_donut_chart.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Change state.categoryShares to state.diagnostic!.categoryInsights
    content = content.replace("state.categoryShares.isEmpty", "state.diagnostic == null || state.diagnostic!.categoryInsights.isEmpty")
    content = content.replace("final shares = state.categoryShares;", "final shares = state.diagnostic!.categoryInsights;")
    
    # Change share.percentage to share.percentageOfTotal
    content = content.replace("share.percentage", "share.percentageOfTotal")
    
    # Change share.categoryName is already correct
    # Change share.amount to share.currentSpend
    content = content.replace("share.amount", "share.currentSpend")
    
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

    # 2. Update category_comparison_chart.dart
    p = r'p:\pro\spendly\lib\features\analytics\presentation\widgets\category_comparison_chart.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
        
    content = content.replace("state.categoryShares.isEmpty", "state.diagnostic == null || state.diagnostic!.categoryInsights.isEmpty")
    content = content.replace("final topCategories = state.categoryShares", "final topCategories = state.diagnostic!.categoryInsights")
    content = content.replace("final diff = category.amount - category.previousAmount;", "final diff = category.trend.absoluteChange;")
    content = content.replace("final diffPct = category.previousAmount > 0", "final diffPct = category.trend.percentageChange;")
    content = content.replace("? (diff / category.previousAmount) * 100", "")
    content = content.replace(": 100.0;", "")
    content = content.replace("category.amount", "category.currentSpend")
    content = content.replace("category.previousAmount", "category.previousSpend")
    
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)
        
    # 3. Update member_leaderboard.dart
    p = r'p:\pro\spendly\lib\features\analytics\presentation\widgets\member_leaderboard.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
        
    content = content.replace("state.memberShares.isEmpty", "state.diagnostic == null || state.diagnostic!.memberInsights.isEmpty")
    content = content.replace("final members = state.memberShares;", "final members = state.diagnostic!.memberInsights;")
    content = content.replace("member.percentage", "member.percentageOfTotal")
    content = content.replace("member.amount", "member.currentSpend")
    
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)
        
    # 4. Update member_comparison_chart.dart
    p = r'p:\pro\spendly\lib\features\analytics\presentation\widgets\member_comparison_chart.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
        
    content = content.replace("state.memberShares.isEmpty", "state.diagnostic == null || state.diagnostic!.memberInsights.isEmpty")
    content = content.replace("final members = state.memberShares;", "final members = state.diagnostic!.memberInsights;")
    content = content.replace("member.amount", "member.currentSpend")
    content = content.replace("member.previousAmount", "member.previousSpend")
    
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)
        
    # 5. Update budget_analysis_card.dart
    p = r'p:\pro\spendly\lib\features\analytics\presentation\widgets\budget_analysis_card.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
        
    content = content.replace("state.projectedMonthEnd", "state.budgetForecast?.projectedTotal ?? 0")
    content = content.replace("state.expectedOverspend", "state.budgetForecast?.expectedOverrun ?? 0")
    
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)
        
    # 6. Update summary_card.dart
    p = r'p:\pro\spendly\lib\features\analytics\presentation\widgets\summary_card.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
        
    content = content.replace("state.totalSpentDiffPercent >= 0", "(state.summary?.totalSpend.percentageChange ?? 0) >= 0")
    content = content.replace("state.totalSpentDiffPercent < 0", "(state.summary?.totalSpend.percentageChange ?? 0) < 0")
    content = content.replace("state.totalSpentDiffPercent.abs()", "(state.summary?.totalSpend.percentageChange.abs() ?? 0)")
    content = content.replace("state.dailyAverageDiffPercent >= 0", "(state.summary?.dailyAverage.percentageChange ?? 0) >= 0")
    
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
