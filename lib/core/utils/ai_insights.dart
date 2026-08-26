import 'package:spendly/features/analytics/models/analytics_models.dart';

class AiInsights {
  // New Phase 7: Deterministic Insight Generation from Mathematical Facts
  static List<String> generateFromFacts(List<InsightFact> facts) {
    if (facts.isEmpty) {
      return ['✨ Keep logging expenses to see detailed insights!'];
    }

    final insights = <String>[];

    // Priority sorting: critical first, then high, then medium.
    final sortedFacts = List<InsightFact>.from(facts)
      ..sort(
        (a, b) => _importanceValue(
          b.importance,
        ).compareTo(_importanceValue(a.importance)),
      );

    for (var fact in sortedFacts) {
      if (fact.category == 'Budget') {
        if (fact.importance == FactImportance.critical) {
          insights.add('⚠️ ${fact.formattedValue}. ${fact.context}.');
        } else {
          insights.add('💡 ${fact.formattedValue}.');
        }
      } else if (fact.category == 'Anomaly') {
        insights.add(
          '🔍 Anomaly Detected: ${fact.formattedValue}. ${fact.context}',
        );
      } else if (fact.category == 'Diagnostic') {
        insights.add(
          '📈 ${fact.formattedValue} was your primary category causing a spending increase. (${fact.context})',
        );
      } else if (fact.category == 'Pattern') {
        insights.add(
          '📅 Spike Detected: High spending day on ${fact.formattedValue} (Total: ${fact.rawValue}). ${fact.context}',
        );
      }
    }

    // We only show top 3-4 insights so we don't overwhelm the user
    if (insights.length > 4) {
      return insights.sublist(0, 4);
    }
    return insights;
  }

  static int _importanceValue(FactImportance importance) {
    switch (importance) {
      case FactImportance.critical:
        return 3;
      case FactImportance.high:
        return 2;
      case FactImportance.medium:
        return 1;
      case FactImportance.low:
        return 0;
    }
  }
}
