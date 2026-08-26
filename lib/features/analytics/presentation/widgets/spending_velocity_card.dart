import 'package:flutter/material.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';
import 'package:spendly/features/analytics/models/analytics_models.dart';

class SpendingVelocityCard extends StatelessWidget {
  final AnalyticsState state;

  const SpendingVelocityCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final velocity = state.velocity;
    if (velocity == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    
    Color statusColor = Colors.green;
    IconData statusIcon = Icons.check_circle_outline;
    
    switch (velocity.status) {
      case VelocityStatus.underPace:
        statusColor = Colors.green;
        statusIcon = Icons.trending_down;
        break;
      case VelocityStatus.onPace:
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle_outline;
        break;
      case VelocityStatus.slightlyFast:
        statusColor = Colors.orange;
        statusIcon = Icons.warning_amber_rounded;
        break;
      case VelocityStatus.veryFast:
        statusColor = Colors.red;
        statusIcon = Icons.dangerous_outlined;
        break;
      case VelocityStatus.unavailable:
        statusColor = Colors.grey;
        statusIcon = Icons.info_outline;
        break;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Spending Velocity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Budget pace analysis',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        velocity.interpretation,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Velocity Ratio: ${velocity.velocityRatio.toStringAsFixed(2)}x',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Progress bars comparison
            _buildProgressBar(
              context, 
              'Time Elapsed', 
              velocity.timeElapsedPct, 
              Colors.grey,
            ),
            const SizedBox(height: 12),
            _buildProgressBar(
              context, 
              'Budget Consumed', 
              velocity.budgetConsumedPct, 
              statusColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, String label, double pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              '${pct.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (pct / 100).clamp(0.0, 1.0),
            minHeight: 8,
            color: color,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
        ),
      ],
    );
  }
}
