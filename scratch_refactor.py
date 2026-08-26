import re

def process():
    p = r'p:\pro\spendly\lib\features\analytics\presentation\widgets\budget_analysis_card.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
    
    content = content.replace("state.projectedMonthEnd", "state.budgetForecast?.projectedTotal ?? state.projectedMonthEnd")
    content = content.replace("state.expectedOverspend", "state.budgetForecast?.expectedOverrun ?? state.expectedOverspend")
    
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
