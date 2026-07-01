import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendly/models/expense.dart';

class DrillDownSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double totalAmount;
  final List<Expense> expenses;
  final String? aiSummary;

  const DrillDownSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.totalAmount,
    required this.expenses,
    this.aiSummary,
  });

  static void show(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double totalAmount,
    required List<Expense> expenses,
    String? aiSummary,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DrillDownSheet(
        title: title,
        subtitle: subtitle,
        icon: icon,
        color: color,
        totalAmount: totalAmount,
        expenses: expenses,
        aiSummary: aiSummary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFmt = DateFormat('MMM d, hh:mm a');

    // Aggregate by Member
    final Map<String, double> memberTotals = {};
    for (var e in expenses) {
      memberTotals[e.createdByName] = (memberTotals[e.createdByName] ?? 0) + e.amount;
    }
    final sortedMembers = memberTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // Aggregate by Payment Method
    final Map<String, double> paymentTotals = {};
    for (var e in expenses) {
      paymentTotals[e.paymentMethod] = (paymentTotals[e.paymentMethod] ?? 0) + e.amount;
    }
    final sortedPayments = paymentTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currencyFmt.format(totalAmount),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24.0),
                  children: [
                    // AI Summary
                    if (aiSummary != null && aiSummary!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.withOpacity(0.1)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.auto_awesome, color: Colors.blue, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                aiSummary!,
                                style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Stats Row
                    Row(
                      children: [
                        _buildStatBox(context, 'Transactions', '${expenses.length}', Icons.receipt_long, Colors.purple),
                        const SizedBox(width: 12),
                        _buildStatBox(context, 'Average', currencyFmt.format(totalAmount / max(1, expenses.length)), Icons.calculate, Colors.teal),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Top Members
                    if (sortedMembers.length > 1) ...[
                      const Text('Spending by Member', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...sortedMembers.map((e) => _buildSimpleRow(e.key, currencyFmt.format(e.value), e.value / max(1.0, totalAmount))),
                      const SizedBox(height: 24),
                    ],

                    // Top Payment Methods
                    if (sortedPayments.length > 1) ...[
                      const Text('Payment Methods', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...sortedPayments.map((e) => _buildSimpleRow(e.key, currencyFmt.format(e.value), e.value / max(1.0, totalAmount))),
                      const SizedBox(height: 24),
                    ],

                    // Recent Transactions
                    const Text('Recent Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (expenses.isEmpty)
                      const Text('No transactions found.')
                    else
                      ...expenses.take(15).map((exp) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.grey[100],
                                radius: 20,
                                child: Text(
                                  exp.createdByName.isNotEmpty ? exp.createdByName.substring(0, 1).toUpperCase() : 'M',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exp.description.isEmpty ? exp.category : exp.description,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${exp.createdByName} • ${dateFmt.format(exp.expenseDate)}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                currencyFmt.format(exp.amount),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatBox(BuildContext context, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleRow(String title, String value, double progress) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                color: Colors.blueGrey,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
