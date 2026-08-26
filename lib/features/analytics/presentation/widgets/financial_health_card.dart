import 'dart:math';
import 'package:flutter/material.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';

class FinancialHealthCard extends StatelessWidget {
  final AnalyticsState state;

  const FinancialHealthCard({super.key, required this.state});

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.blue;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final health = state.healthScore;
    if (health == null) return const SizedBox.shrink();

    final score = health.totalScore;
    final color = _getScoreColor(score);
    final label = health.label;

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Health Score',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Calculated from comprehensive analytics',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.health_and_safety_outlined, size: 20, color: color),
              ],
            ),
            const SizedBox(height: 24),

            // Gauge + Score Display
            Center(
              child: SizedBox(
                width: 200,
                height: 110,
                child: CustomPaint(
                  painter: _GaugePainter(
                    score: score,
                    color: color,
                    trackColor: colorScheme.surfaceContainerHigh.withOpacity(
                      0.5,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: color,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: color,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: colorScheme.outline),
            const SizedBox(height: 12),

            // Factors Breakdown list
            Text(
              'Detailed Metrics',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            _buildScoreBar(
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
              'Anomaly Control (10%)',
              health.anomalyExposure,
              _getScoreColor(health.anomalyExposure),
            ),
            _buildScoreBar(
              context,
              'Category Balance (10%)',
              health.concentration,
              _getScoreColor(health.concentration),
            ),
            _buildScoreBar(
              context,
              'Data Sufficiency (5%)',
              health.dataConfidenceScore,
              _getScoreColor(health.dataConfidenceScore),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBar(
    BuildContext context,
    String name,
    int score,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: color.withOpacity(0.12),
              color: color,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final int score;
  final Color color;
  final Color trackColor;

  _GaugePainter({
    required this.score,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = min(size.width / 2, size.height) - 10;

    // Draw background track arc (180 degrees to 360 degrees)
    final bgPaint = Paint()
      ..color = trackColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi, // Start from left (180 deg)
      pi, // Sweep full semi-circle
      false,
      bgPaint,
    );

    // Draw foreground score arc
    final fgPaint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;

    final double sweepAngle = pi * (score / 100);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
