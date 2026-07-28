import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';
import 'package:spendly/features/analytics/presentation/widgets/category_donut_chart.dart';

class RecurringExpensesCard extends StatelessWidget {
  final AnalyticsState state;

  const RecurringExpensesCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFmt = DateFormat('MMM d, yyyy');

    final items = state.recurringExpenses;

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
                      'Recurring Expenses',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Auto-detected subscriptions and bills',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                Icon(Icons.repeat_on_outlined, size: 20, color: colorScheme.primary),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, size: 28, color: colorScheme.onSurfaceVariant),
                      const SizedBox(height: 8),
                      Text(
                        'No recurring expenses detected yet.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Logging identical descriptions across multiple weeks or months will trigger automatic classification.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10.5, color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, idx) {
                  final item = items[idx];
                  final meta = getCategoryMetadata(context, item.category);
                  
                  // Emoji selection based on title/desc
                  String emoji = meta.emoji;
                  final titleLower = item.title.toLowerCase();
                  if (titleLower.contains('milk')) emoji = '🥛';
                  if (titleLower.contains('netflix')) emoji = '🎬';
                  if (titleLower.contains('spotify')) emoji = '🎵';
                  if (titleLower.contains('electricity')) emoji = '⚡';
                  if (titleLower.contains('gas')) emoji = '⛽';
                  if (titleLower.contains('wifi') || titleLower.contains('internet')) emoji = '🌐';
                  if (titleLower.contains('rent')) emoji = '🏠';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        // Leading circular icon
                        Container(
                          width: 38,
                          height: 38,
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: meta.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SvgPicture.asset(
                            meta.iconPath,
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(meta.color, BlendMode.srcIn),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title & Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.frequency} • Expected: ${dateFmt.format(item.nextExpectedDate)}',
                                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),

                        // Value
                        Text(
                          currencyFmt.format(item.amount),
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: colorScheme.onSurface),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
