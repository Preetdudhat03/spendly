import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';
import 'package:spendly/models/expense.dart';
import 'package:spendly/core/theme/spendly_tokens.dart';
import 'drill_down_sheet.dart';

import 'package:flutter_svg/flutter_svg.dart';

class CategoryMetadata {
  final String name;
  final String emoji;
  final Color color;
  final String iconPath;

  CategoryMetadata(
    this.name,
    this.emoji,
    this.color, [
    this.iconPath = 'assets/category/others.svg',
  ]);
}

CategoryMetadata getCategoryMetadata(BuildContext context, String category) {
  final charts = context.spendly.charts;
  final color = charts.getCategoryColor(category);

  switch (category.toLowerCase()) {
    case 'food':
      return CategoryMetadata('Food', '🍔', color, 'assets/category/food.svg');
    case 'groceries':
      return CategoryMetadata(
        'Groceries',
        '🛒',
        color,
        'assets/category/groceries.svg',
      );
    case 'petrol':
    case 'fuel':
      return CategoryMetadata(
        'Petrol',
        '🚗',
        color,
        'assets/category/fuel.svg',
      );
    case 'recharges':
      return CategoryMetadata(
        'Recharges',
        '📱',
        color,
        'assets/category/recharge.svg',
      );
    case 'travel':
      return CategoryMetadata(
        'Travel',
        '✈️',
        color,
        'assets/category/travel.svg',
      );
    case 'gas':
      return CategoryMetadata('Gas', '⛽', color, 'assets/category/gas.svg');
    case 'electricity':
    case 'utility':
      return CategoryMetadata(
        'Utilities',
        '⚡',
        color,
        'assets/category/electricity.svg',
      );
    case 'medical':
      return CategoryMetadata(
        'Medical',
        '🏥',
        color,
        'assets/category/medical.svg',
      );
    case 'insurances':
      return CategoryMetadata(
        'Insurances',
        '🛡️',
        color,
        'assets/category/insurances.svg',
      );
    case 'shopping':
      return CategoryMetadata(
        'Shopping',
        '🛍️',
        color,
        'assets/category/shopping.svg',
      );
    case 'rent':
      return CategoryMetadata('Rent', '🏠', color, 'assets/category/rent.svg');
    case 'bills':
      return CategoryMetadata(
        'Bills',
        '📄',
        color,
        'assets/category/others.svg',
      );
    case 'entertainment':
      return CategoryMetadata(
        'Entertainment',
        '🎬',
        color,
        'assets/category/entertainment.svg',
      );
    case 'education':
      return CategoryMetadata(
        'Education',
        '📚',
        color,
        'assets/category/education.svg',
      );
    case 'college':
    case 'collage':
      return CategoryMetadata(
        'College',
        '🎓',
        color,
        'assets/category/college.svg',
      );
    default:
      return CategoryMetadata(
        category,
        '📦',
        color,
        'assets/category/others.svg',
      );
  }
}

class CategoryDonutChart extends StatefulWidget {
  final AnalyticsState state;

  const CategoryDonutChart({super.key, required this.state});

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart> {
  int touchedIndex = -1;

  void _showCategoryDetails(BuildContext context, CategoryShare share) {
    final meta = getCategoryMetadata(context, share.categoryName);

    // Filter transactions for this category in current range
    final categoryExpenses =
        widget.state.filteredExpenses
            .where(
              (e) => e.category.toLowerCase() == share.categoryName.toLowerCase(),
            )
            .toList()
          ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

    DrillDownSheet.show(
      context,
      title: meta.name,
      subtitle:
          '${share.percentageOfTotal.toStringAsFixed(0)}% of total spending',
      icon: Icons
          .category, // You could use a specific icon or just use the emoji text in a custom way. We'll use a generic icon for now.
      color: meta.color,
      totalAmount: share.currentSpend,
      expenses: categoryExpenses,
      aiSummary:
          'This category makes up ${share.percentageOfTotal.toStringAsFixed(0)}% of your expenses. Consider looking for bulk discounts if applicable.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    if (widget.state.diagnostic == null ||
        widget.state.diagnostic!.categoryInsights.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalText = currencyFmt.format(widget.state.totalSpent);

    // Build fl chart sections
    final sections = List<PieChartSectionData>.generate(
      widget.state.diagnostic!.categoryInsights.length,
      (i) {
        final share = widget.state.diagnostic!.categoryInsights[i];
        final meta = getCategoryMetadata(context, share.categoryName);
        final isTouched = i == touchedIndex;
        final radius = isTouched ? 48.0 : 40.0;
        final strokeWidth = isTouched ? 6.0 : 0.0;

        return PieChartSectionData(
          color: meta.color,
          value: share.currentSpend,
          title: '', // Empty because we show labels in the legend below
          radius: radius,
          borderSide: strokeWidth > 0
              ? BorderSide(
                  color: meta.color.withOpacity(0.4),
                  width: strokeWidth,
                )
              : BorderSide.none,
        );
      },
    );

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
                      'Category Breakdown',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Share of monthly budget expenditures',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.donut_large, size: 20, color: colorScheme.primary),
              ],
            ),
            const SizedBox(height: 24),

            // Donut chart with centered text
            Center(
              child: SizedBox(
                height: 180,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 66,
                        sectionsSpace: 4,
                        borderData: FlBorderData(show: false),
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    touchedIndex = -1;
                                    return;
                                  }
                                  touchedIndex = pieTouchResponse
                                      .touchedSection!
                                      .touchedSectionIndex;

                                  // Trigger click drill down on single tap up
                                  if (event is FlTapUpEvent &&
                                      touchedIndex >= 0 &&
                                      touchedIndex <
                                          widget.state.diagnostic!.categoryInsights.length) {
                                    _showCategoryDetails(
                                      context,
                                      widget.state.diagnostic!.categoryInsights[touchedIndex],
                                    );
                                  }
                                });
                              },
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'TOTAL SPENT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurfaceVariant,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            totalText,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Category Legend List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.state.diagnostic!.categoryInsights.length,
              itemBuilder: (context, idx) {
                final share = widget.state.diagnostic!.categoryInsights[idx];
                final meta = getCategoryMetadata(context, share.categoryName);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showCategoryDetails(context, share),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: meta.color.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: SvgPicture.asset(
                              meta.iconPath,
                              width: 18,
                              height: 18,
                              colorFilter: ColorFilter.mode(
                                meta.color,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              meta.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currencyFmt.format(share.currentSpend),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${share.percentageOfTotal.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
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
