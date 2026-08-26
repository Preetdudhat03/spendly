import re

def process():
    p = r'p:\pro\spendly\lib\features\analytics\models\analytics_models.dart'
    with open(p, 'r', encoding='utf-8') as f:
        c = f.read()

    old_logic = """    int concentrationScore = 100;
    if (topCategoryPercentage > 60) {
      concentrationScore = 80;
    } else if (topCategoryPercentage > 80) {
      concentrationScore = 60;
    }"""
    
    new_logic = """    int concentrationScore = 100;
    if (topCategoryPercentage >= 90) {
      concentrationScore = 20;
    } else if (topCategoryPercentage >= 75) {
      concentrationScore = 50;
    } else if (topCategoryPercentage > 60) {
      concentrationScore = 80;
    }"""
    
    c = c.replace(old_logic, new_logic)
    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)

    p2 = r'p:\pro\spendly\lib\features\analytics\presentation\widgets\financial_health_card.dart'
    with open(p2, 'r', encoding='utf-8') as f2:
        c2 = f2.read()
        
    c2 = c2.replace("'Anomaly Exposure (10%)',", "'Anomaly Control (10%)',")
    c2 = c2.replace("'Concentration (10%)',", "'Category Balance (10%)',")
    c2 = c2.replace("'Data Confidence (5%)',", "'Data Sufficiency (5%)',")
    
    with open(p2, 'w', encoding='utf-8') as f2:
        f2.write(c2)

if __name__ == '__main__':
    process()
