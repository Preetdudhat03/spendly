import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';
import 'package:spendly/models/expense.dart';
import 'drill_down_sheet.dart';

class CategoryMetadata {
  final String name;
  final String emoji;
  final Color color;

  CategoryMetadata(this.name, this.emoji, this.color);
}

CategoryMetadata getCategoryMetadata(String category) {
  switch (category.toLowerCase()) {
    case 'food':
      return CategoryMetadata('Food', '🍔', const Color(0xFFF59E0B));
    case 'groceries':
      return CategoryMetadata('Groceries', '🛒', const Color(0xFF10B981));
    case 'petrol':
    case 'fuel':
      return CategoryMetadata('Petrol/Fuel', '⛽', const Color(0xFF3B82F6));
    case 'recharges':
      return CategoryMetadata('Recharges', '📱', const Color(0xFF06B6D4));
    case 'travel':
      return CategoryMetadata('Travel', '✈️', const Color(0xFF14B8A6));
    case 'gas':
      return CategoryMetadata('Gas', '⛽', const Color(0xFFF97316));
    case 'electricity':
    case 'utility':
      return CategoryMetadata('Utilities', '⚡', const Color(0xFF8B5CF6));
    case 'medical':
      return CategoryMetadata('Medical', '🏥', const Color(0xFFEF4444));
    case 'insurances':
      return CategoryMetadata('Insurances', '🛡️', const Color(0xFF4F46E5));
    case 'shopping':
      return CategoryMetadata('Shopping', '🛍️', const Color(0xFFEC4899));
    case 'rent':
      return CategoryMetadata('Rent', '🏠', const Color(0xFF78350F));
    case 'entertainment':
      return CategoryMetadata('Entertainment', '🎬', const Color(0xFFF43F5E));
    case 'education':
      return CategoryMetadata('Education', '📚', const Color(0xFF636AE8));
    case 'college':
    case 'collage':
      return CategoryMetadata('College', '🎓', const Color(0xFF312E81));
    default:
      return CategoryMetadata(category, '📦', const Color(0xFF64748B));
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
    final meta = getCategoryMetadata(share.category);

    // Filter transactions for this category in current range
    final categoryExpenses = widget.state.filteredExpenses
        .where((e) => e.category.toLowerCase() == share.category.toLowerCase())
        .toList()
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

    DrillDownSheet.show(
      context,
      title: meta.name,
      subtitle: '${share.percentage.toStringAsFixed(0)}% of total spending',
      icon: Icons.category, // You could use a specific icon or just use the emoji text in a custom way. We'll use a generic icon for now.
      color: meta.color,
      totalAmount: share.amount,
      expenses: categoryExpenses,
      aiSummary: 'This category makes up ${share.percentage.toStringAsFixed(0)}% of your expenses. Consider looking for bulk discounts if applicable.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    if (widget.state.categoryShares.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalText = currencyFmt.format(widget.state.totalSpent);

    // Build fl chart sections
    final sections = List<PieChartSectionData>.generate(
      widget.state.categoryShares.length,
      (i) {
        final share = widget.state.categoryShares[i];
        final meta = getCategoryMetadata(share.category);
        final isTouched = i == touchedIndex;
        final radius = isTouched ? 48.0 : 40.0;
        final strokeWidth = isTouched ? 6.0 : 0.0;

        return PieChartSectionData(
          color: meta.color,
          value: share.amount,
          title: '', // Empty because we show labels in the legend below
          radius: radius,
          borderSide: strokeWidth > 0 ? BorderSide(color: meta.color.withOpacity(0.4), width: strokeWidth) : BorderSide.none,
        );
      },
    );

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
                      'Category Breakdown',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Share of monthly budget expenditures',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                Icon(Icons.donut_large, size: 20, color: Theme.of(context).primaryColor),
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
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                touchedIndex = -1;
                                return;
                              }
                              touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              
                              // Trigger click drill down on single tap up
                              if (event is FlTapUpEvent && touchedIndex >= 0 && touchedIndex < widget.state.categoryShares.length) {
                                _showCategoryDetails(context, widget.state.categoryShares[touchedIndex]);
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
                              color: Colors.grey[500],
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            totalText,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
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
              itemCount: widget.state.categoryShares.length,
              itemBuilder: (context, idx) {
                final share = widget.state.categoryShares[idx];
                final meta = getCategoryMetadata(share.category);
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showCategoryDetails(context, share),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: meta.color.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Text(meta.emoji, style: const TextStyle(fontSize: 16)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              meta.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currencyFmt.format(share.amount),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${share.percentage.toStringAsFixed(0)}%',
                                style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
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
