import re

def process():
    p = r'p:\pro\spendly\lib\features\analytics\presentation\widgets\category_comparison_chart.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
    
    import_str = "import 'package:spendly/features/analytics/models/analytics_models.dart';"
    if import_str not in content:
        content = content.replace("import 'package:spendly/features/analytics/providers/analytics_providers.dart';", "import 'package:spendly/features/analytics/providers/analytics_providers.dart';\n" + import_str)
    
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
