import 'package:flutter/material.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';

class SpendingPatternsCard extends StatelessWidget {
  final AnalyticsState state;

  const SpendingPatternsCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final hasData = state.filteredExpenses.isNotEmpty;

    // 1. Weekend vs Weekday text
    String weekendText = 'Weekend spending is stable and matches weekdays.';
    IconData weekendIcon = Icons.wb_sunny_outlined;
    Color weekendColor = Colors.teal;
    if (state.weekendOverspendPercent > 0) {
      weekendText = 'You spend ${state.weekendOverspendPercent.toStringAsFixed(0)}% more on weekends than weekdays.';
      weekendIcon = Icons.trending_up_rounded;
      weekendColor = Colors.orange;
      if (state.weekendOverspendPercent > 40) {
        weekendColor = Colors.red;
      }
    }

    // 2. Peak activity time
    String peakTimeText = 'No specific peak hours detected yet.';
    IconData peakIcon = Icons.access_time;
    Color peakColor = Colors.blue;

    if (hasData) {
      final amounts = state.timeOfDayCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topTime = amounts.first.key;
      
      if (amounts.first.value > 0) {
        peakColor = Colors.purple;
        peakIcon = Icons.nights_stay_outlined;
        String range = '';
        if (topTime == 'Morning') {
          range = 'Morning (6 AM - 12 PM)';
          peakIcon = Icons.light_mode_outlined;
          peakColor = Colors.amber;
        } else if (topTime == 'Afternoon') {
          range = 'Afternoon (12 PM - 5 PM)';
          peakIcon = Icons.wb_cloudy_outlined;
          peakColor = Colors.orange;
        } else if (topTime == 'Evening') {
          range = 'Evening (5 PM - 9 PM)';
          peakIcon = Icons.wb_twilight_outlined;
          peakColor = Colors.indigo;
        } else if (topTime == 'Night') {
          range = 'Night (9 PM - 6 AM)';
          peakIcon = Icons.nights_stay_outlined;
          peakColor = Colors.purple;
        }
        peakTimeText = 'Most purchases happen during the $range.';
      }
    }

    // 3. Category concentration
    String concentrationText = 'Your spending is well-diversified across categories.';
    IconData concIcon = Icons.category_outlined;
    Color concColor = Colors.green;

    if (state.categoryShares.isNotEmpty) {
      final topCat = state.categoryShares.first;
      if (topCat.percentage > 40) {
        concentrationText = 'High concentration: ${topCat.category} represents ${topCat.percentage.toStringAsFixed(0)}% of total spent.';
        concIcon = Icons.warning_amber_rounded;
        concColor = Colors.orange;
      }
    }

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
                      'Smart Patterns',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Automated behavioral expense analysis',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                Icon(Icons.psychology_outlined, size: 22, color: colorScheme.primary),
              ],
            ),
            const SizedBox(height: 20),

            // Pattern Cards Grid/List
            _buildPatternRow(
              context,
              icon: weekendIcon,
              iconColor: weekendColor,
              title: 'Weekend Habits',
              value: weekendText,
            ),
            const SizedBox(height: 12),
            _buildPatternRow(
              context,
              icon: peakIcon,
              iconColor: peakColor,
              title: 'Peak Spending Time',
              value: peakTimeText,
            ),
            const SizedBox(height: 12),
            _buildPatternRow(
              context,
              icon: concIcon,
              iconColor: concColor,
              title: 'Category Concentration',
              value: concentrationText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconColor.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
