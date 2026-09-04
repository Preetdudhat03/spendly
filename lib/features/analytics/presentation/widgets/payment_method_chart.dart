import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';
import 'drill_down_sheet.dart';

class PaymentMethodMetadata {
  final String name;
  final IconData icon;
  final Color color;

  PaymentMethodMetadata(this.name, this.icon, this.color);
}

PaymentMethodMetadata getPaymentMethodMetadata(String method) {
  switch (method.toLowerCase()) {
    case 'upi':
      return PaymentMethodMetadata(
        'UPI',
        Icons.qr_code_2,
        const Color(0xFF636AE8),
      );
    case 'cash':
      return PaymentMethodMetadata(
        'Cash',
        Icons.payments_outlined,
        const Color(0xFF10B981),
      );
    case 'credit card':
    case 'creditcard':
      return PaymentMethodMetadata(
        'Credit Card',
        Icons.credit_card_outlined,
        const Color(0xFFEC4899),
      );
    case 'debit card':
    case 'debitcard':
      return PaymentMethodMetadata(
        'Debit Card',
        Icons.credit_card_sharp,
        const Color(0xFF3B82F6),
      );
    case 'bank transfer':
    case 'banktransfer':
    case 'bank':
      return PaymentMethodMetadata(
        'Bank Transfer',
        Icons.account_balance_outlined,
        const Color(0xFF8B5CF6),
      );
    case 'wallet':
      return PaymentMethodMetadata(
        'Wallet',
        Icons.account_balance_wallet_outlined,
        const Color(0xFFF59E0B),
      );
    default:
      return PaymentMethodMetadata(
        method,
        Icons.payment_outlined,
        const Color(0xFF64748B),
      );
  }
}

class PaymentMethodChart extends StatefulWidget {
  final AnalyticsState state;

  const PaymentMethodChart({super.key, required this.state});

  @override
  State<PaymentMethodChart> createState() => _PaymentMethodChartState();
}

class _PaymentMethodChartState extends State<PaymentMethodChart> {
  int touchedIndex = -1;

  void _showPaymentDetails(BuildContext context, PaymentMethodShare share) {
    final meta = getPaymentMethodMetadata(share.method);

    // Filter transactions for this method
    final methodExpenses =
        widget.state.filteredExpenses
            .where(
              (e) =>
                  e.paymentMethod.toLowerCase() == share.method.toLowerCase(),
            )
            .toList()
          ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

    DrillDownSheet.show(
      context,
      title: meta.name,
      subtitle: '${share.percentage.toStringAsFixed(0)}% of total volume',
      icon: meta.icon,
      color: meta.color,
      totalAmount: share.amount,
      expenses: methodExpenses,
      aiSummary:
          'You use ${meta.name} for ${share.percentage.toStringAsFixed(0)}% of your transactions. It was used ${share.count} times this period.',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.paymentMethodShares.isEmpty) {
      return const SizedBox.shrink();
    }

    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    // Build chart sections
    final sections = List<PieChartSectionData>.generate(
      widget.state.paymentMethodShares.length,
      (i) {
        final share = widget.state.paymentMethodShares[i];
        final meta = getPaymentMethodMetadata(share.method);
        final isTouched = i == touchedIndex;
        final radius = isTouched ? 48.0 : 40.0;
        final strokeWidth = isTouched ? 6.0 : 0.0;

        return PieChartSectionData(
          color: meta.color,
          value: share.amount,
          title: '', // Show label in legend
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
                      'Payment Methods',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Distribution across transactional channels',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.payment, size: 20, color: colorScheme.primary),
              ],
            ),
            const SizedBox(height: 24),

            // Donut Chart
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

                                  if (event is FlTapUpEvent &&
                                      touchedIndex >= 0 &&
                                      touchedIndex <
                                          widget
                                              .state
                                              .paymentMethodShares
                                              .length) {
                                    _showPaymentDetails(
                                      context,
                                      widget
                                          .state
                                          .paymentMethodShares[touchedIndex],
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
                            'METHODS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurfaceVariant,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.state.paymentMethodShares.length} Used',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
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

            // Legend
            ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.state.paymentMethodShares.length,
              itemBuilder: (context, idx) {
                final share = widget.state.paymentMethodShares[idx];
                final meta = getPaymentMethodMetadata(share.method);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showPaymentDetails(context, share),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 4.0,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: meta.color.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(meta.icon, size: 16, color: meta.color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meta.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${share.count} transaction${share.count == 1 ? '' : 's'}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currencyFmt.format(share.amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
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
