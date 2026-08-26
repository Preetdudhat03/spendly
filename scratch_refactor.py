import re

def process():
    path = r'p:\pro\spendly\lib\features\analytics\presentation\pages\analytics_page.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Import the new widgets
    if "import '../widgets/spending_velocity_card.dart';" not in content:
        content = content.replace("import '../widgets/financial_health_card.dart';", "import '../widgets/financial_health_card.dart';\nimport '../widgets/spending_velocity_card.dart';\nimport '../widgets/diagnostic_intelligence_card.dart';")

    # For wide view (tablet/desktop)
    # Put velocity under budget analysis, and diagnostic under health
    wide_from = """                      animatedItem(BudgetAnalysisCard(state: state), 5),
                      const SizedBox(height: 20),
                      animatedItem(FamilyMemberLeaderboard(state: state), 7),"""
    wide_to = """                      animatedItem(BudgetAnalysisCard(state: state), 5),
                      const SizedBox(height: 20),
                      animatedItem(SpendingVelocityCard(state: state), 5),
                      const SizedBox(height: 20),
                      animatedItem(DiagnosticIntelligenceCard(state: state), 5),
                      const SizedBox(height: 20),
                      animatedItem(FamilyMemberLeaderboard(state: state), 7),"""
    content = content.replace(wide_from, wide_to)

    # For mobile view
    mobile_from = """            animatedItem(BudgetAnalysisCard(state: state), 3),
            const SizedBox(height: 16),
            animatedItem(SpendingTrendChart(state: state), 4),"""
    mobile_to = """            animatedItem(BudgetAnalysisCard(state: state), 3),
            const SizedBox(height: 16),
            animatedItem(SpendingVelocityCard(state: state), 3),
            const SizedBox(height: 16),
            animatedItem(DiagnosticIntelligenceCard(state: state), 3),
            const SizedBox(height: 16),
            animatedItem(SpendingTrendChart(state: state), 4),"""
    content = content.replace(mobile_from, mobile_to)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
