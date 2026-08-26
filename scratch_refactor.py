import re

def process():
    path = r'p:\pro\spendly\lib\features\analytics\providers\analytics_providers.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Update AnalyticsState
    if "final List<InsightFact> insightFacts;" not in content:
        content = content.replace("final PatternIntelligence? patterns;", "final PatternIntelligence? patterns;\n  final List<InsightFact> insightFacts;")
        content = content.replace("this.patterns,", "this.patterns,\n    this.insightFacts = const [],")
        
    content = content.replace("patterns: result.patterns,", "patterns: result.patterns,\n      insightFacts: result.insightFacts,")
    
    # 2. Update fetchAiInsights
    fetch_from = """  void fetchAiInsights(List<Expense> expenses, double budgetLimit) {
    // Basic synchronous rule-based insight generation
    final insights = AiInsights.generate(expenses, budgetLimit);
    state = state.copyWith(
      aiInsights: insights,
      aiRecommendations: [
        'Consider setting a weekly budget constraint on Food to maximize savings.',
        'Evaluate recurring subscriptions at the start of next month.',
      ],
    );
  }"""
    fetch_to = """  void fetchAiInsights() {
    // Generate AI interpretations STRICTLY from verified mathematical facts.
    final insights = AiInsights.generateFromFacts(state.insightFacts);
    state = state.copyWith(
      aiInsights: insights,
      aiRecommendations: [
        'Review your high spending days to identify discretionary vs essential purchases.',
      ],
    );
  }"""
    content = content.replace(fetch_from, fetch_to)
    
    # Need to update call sites of fetchAiInsights. It was probably called inside AnalyticsNotifier.
    # Where was fetchAiInsights called?
    content = content.replace("fetchAiInsights(params.expenses, params.budgetLimit);", "fetchAiInsights();")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
