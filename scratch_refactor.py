import re

def process():
    path = r'p:\pro\spendly\lib\features\analytics\models\analytics_models.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    new_models = """
enum VelocityStatus { underPace, onPace, slightlyFast, veryFast, unavailable }

class SpendingVelocity {
  final double budgetConsumedPct;
  final double timeElapsedPct;
  final double velocityRatio; 
  final VelocityStatus status;
  final String interpretation;

  const SpendingVelocity({
    required this.budgetConsumedPct,
    required this.timeElapsedPct,
    required this.velocityRatio,
    required this.status,
    required this.interpretation,
  });

  factory SpendingVelocity.calculate({
    required double totalSpent,
    required double budgetLimit,
    required int elapsedDays,
    required int totalDays,
  }) {
    if (budgetLimit <= 0 || totalDays <= 0 || elapsedDays <= 0) {
      return const SpendingVelocity(
        budgetConsumedPct: 0, timeElapsedPct: 0, velocityRatio: 0, 
        status: VelocityStatus.unavailable, interpretation: 'Unavailable'
      );
    }
    final budgetPct = (totalSpent / budgetLimit) * 100;
    final timePct = (elapsedDays / totalDays) * 100;
    final ratio = timePct > 0 ? budgetPct / timePct : 0.0;
    
    VelocityStatus status = VelocityStatus.onPace;
    String interp = 'Spending is on pace with the budget.';
    
    if (ratio < 0.85) {
      status = VelocityStatus.underPace;
      interp = 'Spending is slower than expected.';
    } else if (ratio > 1.3) {
      status = VelocityStatus.veryFast;
      interp = 'Spending is dangerously fast.';
    } else if (ratio > 1.05) {
      status = VelocityStatus.slightlyFast;
      interp = 'Spending is slightly ahead of pace.';
    }

    return SpendingVelocity(
      budgetConsumedPct: budgetPct,
      timeElapsedPct: timePct,
      velocityRatio: ratio,
      status: status,
      interpretation: interp,
    );
  }
}

class BudgetForecast {
  final double projectedTotal;
  final double expectedRemaining;
  final double expectedOverrun;
  final bool isOverrun;
  
  const BudgetForecast({
    required this.projectedTotal,
    required this.expectedRemaining,
    required this.expectedOverrun,
    required this.isOverrun,
  });

  factory BudgetForecast.calculate({
    required double currentTotalSpent,
    required double currentDailyAvg,
    required double budgetLimit,
    required int remainingDays,
  }) {
    if (budgetLimit <= 0) {
      return const BudgetForecast(projectedTotal: 0, expectedRemaining: 0, expectedOverrun: 0, isOverrun: false);
    }
    final projected = currentTotalSpent + (currentDailyAvg * remainingDays);
    final diff = budgetLimit - projected;
    final isOver = diff < 0;
    
    return BudgetForecast(
      projectedTotal: projected,
      expectedRemaining: isOver ? 0 : diff,
      expectedOverrun: isOver ? diff.abs() : 0,
      isOverrun: isOver,
    );
  }
}
"""

    if "class SpendingVelocity" not in content:
        # insert before SpendingHealth
        content = content.replace("class SpendingHealth {", new_models + "\nclass SpendingHealth {")
    
    # Update SpendingHealth.calculate signature
    if "required SpendingVelocity velocity," not in content:
        content = content.replace("required DataConfidence confidence,\n    required double topCategoryPercentage,", "required DataConfidence confidence,\n    required double topCategoryPercentage,\n    required SpendingVelocity velocity,")
        
        # replace spendingVelocity calculation
        replace_from = """    // 2. Spending Velocity (0 to 100)
    // Budget used % vs Time elapsed %
    int spendingVelocity = 100;
    final budgetUsedPct = (totalSpent / budgetLimit) * 100;
    final timeElapsedPct = (elapsedDays / daysInMonth) * 100;
    if (budgetUsedPct > timeElapsedPct) {
      final velocityOverage = budgetUsedPct - timeElapsedPct;
      spendingVelocity = (100 - (velocityOverage * 2)).toInt().clamp(0, 100);
    }"""
        replace_to = """    // 2. Spending Velocity (0 to 100)
    int spendingVelocity = 100;
    if (velocity.velocityRatio > 1.0) {
      final velocityOverage = velocity.budgetConsumedPct - velocity.timeElapsedPct;
      spendingVelocity = (100 - (velocityOverage * 2)).toInt().clamp(0, 100);
    }"""
        content = content.replace(replace_from, replace_to)
        
    # Update AnalyticsResult fields
    if "final SpendingVelocity velocity;" not in content:
        content = content.replace("final SpendingHealth healthScore;", "final SpendingVelocity velocity;\n  final BudgetForecast budgetForecast;\n  final SpendingHealth healthScore;")
        content = content.replace("required this.healthScore,", "required this.velocity,\n    required this.budgetForecast,\n    required this.healthScore,")
        
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
