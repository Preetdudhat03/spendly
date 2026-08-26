import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';
import 'drill_down_sheet.dart';

class FamilyMemberLeaderboard extends StatelessWidget {
  final AnalyticsState state;

  const FamilyMemberLeaderboard({super.key, required this.state});

  Color _getMemberColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFF636AE8); // Violet
      case 1:
        return const Color(0xFFEC4899); // Pink
      case 2:
        return const Color(0xFF10B981); // Emerald
      case 3:
        return const Color(0xFFF59E0B); // Amber
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  @override
  Widget build(BuildContext context) {
    if (state.memberShares.isEmpty) {
      return const SizedBox.shrink();
    }

    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    // Sum of all member spending to compute percentages
    final membersTotal = state.memberShares.fold<double>(
      0,
      (sum, m) => sum + m.totalSpent,
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
                      'Family Leaderboard',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ranked by contribution this period',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.emoji_events_outlined,
                  size: 20,
                  color: Colors.amber[700],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Members list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.memberShares.length,
              itemBuilder: (context, idx) {
                final member = state.memberShares[idx];
                final progress = membersTotal > 0
                    ? (member.totalSpent / membersTotal)
                    : 0.0;
                final color = _getMemberColor(idx);
                final initial = member.name.isNotEmpty
                    ? member.name.substring(0, 1).toUpperCase()
                    : 'M';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      final memberExpenses =
                          state.filteredExpenses
                              .where((e) => e.createdByName == member.name)
                              .toList()
                            ..sort(
                              (a, b) => b.expenseDate.compareTo(a.expenseDate),
                            );

                      DrillDownSheet.show(
                        context,
                        title: member.name,
                        subtitle: 'Member spending details',
                        icon: Icons.person,
                        color: color,
                        totalAmount: member.totalSpent,
                        expenses: memberExpenses,
                        aiSummary:
                            '${member.name} has logged ${member.count} expenses with an average of ${currencyFmt.format(member.average)}. Their top category is ${member.favoriteCategory}.',
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar with index badge
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: color.withOpacity(0.15),
                                child: Text(
                                  initial,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: CircleAvatar(
                                  radius: 8,
                                  backgroundColor: colorScheme.surface,
                                  child: CircleAvatar(
                                    radius: 7,
                                    backgroundColor: idx == 0
                                        ? Colors.amber
                                        : colorScheme.surfaceContainerHigh,
                                    child: Text(
                                      '${idx + 1}',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: idx == 0
                                            ? Colors.black
                                            : colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),

                          // Member Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      member.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      currencyFmt.format(member.totalSpent),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${member.count} Expenses • Avg ${currencyFmt.format(member.average)} • Max ${currencyFmt.format(member.largest)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Top Category: ${member.favoriteCategory} • Prefers ${member.preferredPaymentMethod}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Progress bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 4,
                                    color: color,
                                    backgroundColor:
                                        colorScheme.surfaceContainerHigh,
                                  ),
                                ),
                              ],
                            ),
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
