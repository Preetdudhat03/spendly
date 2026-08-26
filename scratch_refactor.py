import re

def process():
    p = r'p:\pro\spendly\lib\features\analytics\presentation\widgets\summary_card.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Total Spent Card
    content = content.replace("state.totalSpent)", "state.summary?.totalSpend.currentValue ?? state.totalSpent)")
    content = content.replace("state.totalSpentDiffPercent >= 0", "(state.summary?.totalSpend.percentageChange ?? state.totalSpentDiffPercent) >= 0")
    content = content.replace("state.totalSpentDiffPercent.abs()", "(state.summary?.totalSpend.percentageChange ?? state.totalSpentDiffPercent).abs()")
    
    # 2. Daily Average Card
    content = content.replace("state.dailyAverage)", "state.summary?.dailyAverage.currentValue ?? state.dailyAverage)")
    content = content.replace("state.dailyAverageDiffPercent >= 0", "(state.summary?.dailyAverage.percentageChange ?? state.dailyAverageDiffPercent) >= 0")
    
    # 4. Total Transactions Card
    content = content.replace("state.totalTransactions}", "state.summary?.totalTransactions.currentValue.toInt() ?? state.totalTransactions}")
    content = content.replace("state.prevTotalTransactions}", "state.summary?.totalTransactions.previousValue.toInt() ?? state.prevTotalTransactions}")
    
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
