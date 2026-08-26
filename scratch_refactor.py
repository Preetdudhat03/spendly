import re
import os

def process():
    p = r'p:\pro\spendly\lib\features\analytics\presentation\widgets\category_donut_chart.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
    
    content = content.replace("state.diagnostic!.categoryInsights.isEmpty", "widget.state.diagnostic!.categoryInsights.isEmpty")
    content = content.replace("widget.state.categoryShares", "widget.state.diagnostic!.categoryInsights")
    
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
