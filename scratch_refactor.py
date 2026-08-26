import re

def process():
    p = r'p:\pro\spendly\lib\features\analytics\presentation\widgets\summary_card.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
    
    content = content.replace("state.summary?.totalTransactions", "state.summary?.transactionCount")
    
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
