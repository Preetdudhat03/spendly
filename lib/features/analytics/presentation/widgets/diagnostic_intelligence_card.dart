import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';
import 'package:spendly/features/analytics/models/analytics_models.dart';

class DiagnosticIntelligenceCard extends StatelessWidget {
  final AnalyticsState state;

  const DiagnosticIntelligenceCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final diagnostic = state.diagnostic;
    if (diagnostic == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

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
                Icon(Icons.query_stats, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Diagnostic Intelligence',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Deep dive into spending drivers',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // Contributors
            _buildRow(
              context,
              'Primary Increase Driver',
              diagnostic.primaryIncreaseContributor,
              Icons.trending_up,
              Colors.red,
            ),
            const SizedBox(height: 12),
            _buildRow(
              context,
              'Primary Decrease Driver',
              diagnostic.primaryDecreaseContributor,
              Icons.trending_down,
              Colors.green,
            ),

            const SizedBox(height: 20),
            Divider(color: colorScheme.outline),
            const SizedBox(height: 16),

            // Concentration
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatMetric(
                  context,
                  'Top Category',
                  '${diagnostic.topCategoryShare.toStringAsFixed(1)}%',
                ),
                _buildStatMetric(
                  context,
                  'Top 3 Share',
                  '${diagnostic.top3CategoryShare.toStringAsFixed(1)}%',
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatMetric(
                  context,
                  'Top 3 Transactions',
                  '${diagnostic.top3TransactionsShare.toStringAsFixed(1)}%',
                ),
                _buildStatMetric(
                  context,
                  '<₹200 Purchases',
                  currencyFmt.format(diagnostic.smallPurchasesTotal),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatMetric(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
