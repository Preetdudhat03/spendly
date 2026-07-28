import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';
import 'package:spendly/features/analytics/presentation/widgets/category_donut_chart.dart';

class TopExpensesList extends StatefulWidget {
  final AnalyticsState state;

  const TopExpensesList({super.key, required this.state});

  @override
  State<TopExpensesList> createState() => _TopExpensesListState();
}

class _TopExpensesListState extends State<TopExpensesList> {
  int expandedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.state.topExpenses.isEmpty) {
      return const SizedBox.shrink();
    }

    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFmt = DateFormat('MMM d, yyyy • h:mm a');
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
                      'Top 10 Expenses',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Highest value transactions this period',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                Icon(Icons.trending_up, size: 20, color: colorScheme.primary),
              ],
            ),
            const SizedBox(height: 16),

            // Expandable List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.state.topExpenses.length,
              itemBuilder: (context, idx) {
                final exp = widget.state.topExpenses[idx];
                final meta = getCategoryMetadata(context, exp.category);
                final isExpanded = idx == expandedIndex;

                final title = exp.description.trim().isEmpty ? meta.name : exp.description;

                return Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() {
                          expandedIndex = isExpanded ? -1 : idx;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                        child: Row(
                          children: [
                            // Category Icon Circle
                            Container(
                              width: 40,
                              height: 40,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: meta.color.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: SvgPicture.asset(
                                meta.iconPath,
                                width: 22,
                                height: 22,
                                colorFilter: ColorFilter.mode(meta.color, BlendMode.srcIn),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Title & Member
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'By ${exp.createdByName} • ${DateFormat('MMM d').format(exp.expenseDate)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Amount
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFmt.format(exp.amount),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Icon(
                                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Expanded details section
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow('Category', meta.name, Icons.folder_open_outlined),
                            const SizedBox(height: 8),
                            _buildDetailRow('Payment Mode', exp.paymentMethod, Icons.payments_outlined),
                            const SizedBox(height: 8),
                            _buildDetailRow('Date/Time', dateFmt.format(exp.expenseDate), Icons.calendar_month_outlined),
                            const SizedBox(height: 8),
                            _buildDetailRow('Transaction ID', exp.id, Icons.tag),
                          ],
                        ),
                      ),
                      crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 250),
                    ),
                    if (idx < widget.state.topExpenses.length - 1)
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
