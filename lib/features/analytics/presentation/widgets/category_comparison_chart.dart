import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';
import 'package:spendly/features/analytics/presentation/widgets/category_donut_chart.dart';

class CategoryComparisonChart extends StatelessWidget {
  final AnalyticsState state;

  const CategoryComparisonChart({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.categoryShares.isEmpty) {
      return const SizedBox.shrink();
    }

    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    // We sort shares descending (they are already sorted in the provider, but let's be sure)
    final sortedShares = List<CategoryShare>.from(state.categoryShares)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    // The maximum category amount represents 100% width of the bars
    final maxAmount = sortedShares.isNotEmpty ? sortedShares.first.amount : 1.0;

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
                      'Category Comparison',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Compare spending limits and trends',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.align_horizontal_left,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Horizontal Bars ListView
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedShares.length,
              itemBuilder: (context, idx) {
                final share = sortedShares[idx];
                final meta = getCategoryMetadata(context, share.category);
                final widthRatio = share.amount / maxAmount;
                final isIncrease = share.isIncrease;

                // Spend comparison details
                String compText = '';
                if (share.prevAmount > 0) {
                  compText =
                      '${isIncrease ? '↑' : '↓'} ${share.diffPercent.toStringAsFixed(0)}% from last period';
                } else {
                  compText = 'New category spend';
                }

                final compColor = isIncrease ? Colors.red : Colors.green;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SvgPicture.asset(
                                meta.iconPath,
                                width: 18,
                                height: 18,
                                colorFilter: ColorFilter.mode(
                                  meta.color,
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                meta.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                currencyFmt.format(share.amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${share.percentage.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Animated Bar
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final barMaxWidth = constraints.maxWidth;
                          return Stack(
                            children: [
                              // Background Bar
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              // Foreground Growing Bar
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: widthRatio),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOutCubic,
                                builder: (context, animValue, child) {
                                  return Container(
                                    height: 8,
                                    width: barMaxWidth * animValue,
                                    decoration: BoxDecoration(
                                      color: meta.color,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 4),

                      // Compare Text Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            compText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: compColor,
                            ),
                          ),
                          if (share.prevAmount > 0)
                            Text(
                              'Prev: ${currencyFmt.format(share.prevAmount)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
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
