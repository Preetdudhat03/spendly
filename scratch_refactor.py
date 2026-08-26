import re

def process():
    path = r'p:\pro\spendly\lib\features\analytics\presentation\widgets\financial_health_card.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # We will replace the build method's health metrics reading
    replace_from = """    final score = state.healthMetrics.totalScore;
    final color = _getScoreColor(score);
    final label = state.healthScoreLabel;"""
    
    replace_to = """    final health = state.healthScore;
    if (health == null) return const SizedBox.shrink();

    final score = health.totalScore;
    final color = _getScoreColor(score);
    final label = health.label;"""
    
    content = content.replace(replace_from, replace_to)
    
    # We will replace the detailed metrics
    metrics_from = """            _buildScoreBar(
              context,
              'Budget Control',
              state.healthMetrics.budgetControl,
              _getScoreColor(state.healthMetrics.budgetControl),
            ),
            _buildScoreBar(
              context,
              'Saving Potential',
              state.healthMetrics.savingPotential,
              _getScoreColor(state.healthMetrics.savingPotential),
            ),
            _buildScoreBar(
              context,
              'Category Diversity',
              state.healthMetrics.categoryDiversity,
              _getScoreColor(state.healthMetrics.categoryDiversity),
            ),
            _buildScoreBar(
              context,
              'Weekend Discipline',
              state.healthMetrics.weekendDiscipline,
              _getScoreColor(state.healthMetrics.weekendDiscipline),
            ),"""
            
    metrics_to = """            _buildScoreBar(
              context,
              'Budget Adherence (35%)',
              health.budgetAdherence,
              _getScoreColor(health.budgetAdherence),
            ),
            _buildScoreBar(
              context,
              'Spending Velocity (25%)',
              health.spendingVelocity,
              _getScoreColor(health.spendingVelocity),
            ),
            _buildScoreBar(
              context,
              'Trend Stability (15%)',
              health.trendStability,
              _getScoreColor(health.trendStability),
            ),
            _buildScoreBar(
              context,
              'Anomaly Exposure (10%)',
              health.anomalyExposure,
              _getScoreColor(health.anomalyExposure),
            ),
            _buildScoreBar(
              context,
              'Concentration (10%)',
              health.concentration,
              _getScoreColor(health.concentration),
            ),
            _buildScoreBar(
              context,
              'Data Confidence (5%)',
              health.dataConfidenceScore,
              _getScoreColor(health.dataConfidenceScore),
            ),"""
    
    content = content.replace(metrics_from, metrics_to)
    
    # also change "Calculated using budget discipline metrics" to "Calculated from comprehensive analytics"
    content = content.replace("'Calculated using budget discipline metrics'", "'Calculated from comprehensive analytics'")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
