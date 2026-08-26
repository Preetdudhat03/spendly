import re

def process():
    p = r'p:\pro\spendly\lib\features\analytics\presentation\widgets\category_comparison_chart.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()

    # Import InsightDrillDownSheet
    import_str = "import 'package:spendly/features/analytics/presentation/widgets/insight_drill_down_sheet.dart';"
    if import_str not in content:
        content = content.replace("import 'package:spendly/features/analytics/models/analytics_models.dart';", "import 'package:spendly/features/analytics/models/analytics_models.dart';\n" + import_str)
        
    # Replace the return Padding with return InkWell
    old_return = """                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Column("""
    
    new_return = """                return InkWell(
                  onTap: () {
                    InsightDrillDownSheet.showForCategory(
                      context,
                      insight: share,
                      icon: Icons.category, // You could map icon based on meta
                      color: meta.color,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                    child: Column("""
                    
    content = content.replace(old_return, new_return)
    
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
