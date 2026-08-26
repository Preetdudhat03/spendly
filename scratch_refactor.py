import re

def process():
    path = r'p:\pro\spendly\lib\features\analytics\models\analytics_models.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    new_models = """
enum FactImportance { low, medium, high, critical }

class InsightFact {
  final String category;
  final String metricName;
  final String rawValue;
  final String formattedValue;
  final FactImportance importance;
  final String context;

  const InsightFact({
    required this.category,
    required this.metricName,
    required this.rawValue,
    required this.formattedValue,
    required this.importance,
    required this.context,
  });
}
"""

    if "class InsightFact" not in content:
        content = content.replace("class AnalyticsResult {", new_models + "\nclass AnalyticsResult {")
        
    # Add to AnalyticsResult
    if "final List<InsightFact> insightFacts;" not in content:
        content = content.replace("final PatternIntelligence patterns;", "final PatternIntelligence patterns;\n  final List<InsightFact> insightFacts;")
        content = content.replace("required this.patterns,", "required this.patterns,\n    required this.insightFacts,")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
