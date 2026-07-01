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
    final score = state.financialHealthScore;
    final color = _getScoreColor(score);
    final label = state.healthScoreLabel;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: Color(0xFFF1F5F9)),
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
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Calculated using budget discipline metrics',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
                  painter: _GaugePainter(score: score, color: color),
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
            const Divider(),
            const SizedBox(height: 12),

            // Factors Breakdown list
            Text(
              'Detailed Metrics',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            _buildScoreBar('Budget Control', state.healthMetrics.budgetControl, _getScoreColor(state.healthMetrics.budgetControl)),
            _buildScoreBar('Saving Potential', state.healthMetrics.savingPotential, _getScoreColor(state.healthMetrics.savingPotential)),
            _buildScoreBar('Category Diversity', state.healthMetrics.categoryDiversity, _getScoreColor(state.healthMetrics.categoryDiversity)),
            _buildScoreBar('Weekend Discipline', state.healthMetrics.weekendDiscipline, _getScoreColor(state.healthMetrics.weekendDiscipline)),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBar(String name, int score, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600)),
              Text('$score', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: color.withOpacity(0.1),
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

  _GaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = min(size.width / 2, size.height) - 10;

    // Draw background track arc (180 degrees to 360 degrees)
    final bgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
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
