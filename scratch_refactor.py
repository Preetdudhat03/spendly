import re

def process():
    p = r'p:\pro\spendly\lib\features\analytics\presentation\widgets\category_comparison_chart.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
    
    content = content.replace("state.categoryShares.isEmpty", "(state.diagnostic?.categoryInsights.isEmpty ?? true)")
    content = content.replace("List<CategoryShare>.from(state.categoryShares)", "List<CategoryInsight>.from(state.diagnostic!.categoryInsights)")
    content = content.replace("b.amount.compareTo(a.amount)", "b.currentSpend.compareTo(a.currentSpend)")
    content = content.replace("sortedShares.first.amount", "sortedShares.first.currentSpend")
    content = content.replace("share.category", "share.categoryName")
    content = content.replace("share.amount", "share.currentSpend")
    content = content.replace("share.isIncrease", "share.trend.direction == TrendDirection.increase")
    content = content.replace("share.prevAmount", "share.previousSpend")
    content = content.replace("share.diffPercent", "share.trend.percentageChange")
    content = content.replace("share.percentage", "share.percentageOfTotal")
    
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
