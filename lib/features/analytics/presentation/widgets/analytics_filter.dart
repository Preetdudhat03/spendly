import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';
import 'package:spendly/core/providers/state_providers.dart';

class AnalyticsFilterHeader extends ConsumerWidget {
  const AnalyticsFilterHeader({super.key});

  String _getFilterLabel(AnalyticsFilterType type, DateTimeRange range) {
    final fmt = DateFormat('MMM d, yyyy');
    switch (type) {
      case AnalyticsFilterType.today:
        return 'Today';
      case AnalyticsFilterType.last7Days:
        return 'Last 7 Days';
      case AnalyticsFilterType.thisMonth:
        return 'This Month';
      case AnalyticsFilterType.lastMonth:
        return 'Last Month';
      case AnalyticsFilterType.last3Months:
        return 'Last 3 Months';
      case AnalyticsFilterType.last6Months:
        return 'Last 6 Months';
      case AnalyticsFilterType.thisYear:
        return 'This Year';
      case AnalyticsFilterType.customDate:
        return '${fmt.format(range.start)} - ${fmt.format(range.end)}';
    }
  }

  void _showFilterSelector(BuildContext context, WidgetRef ref, AnalyticsFilterType currentType) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Time Range',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              Expanded(
                child: ListView(
                  children: AnalyticsFilterType.values.map((type) {
                    final isSelected = type == currentType;
                    return ListTile(
                      title: Text(
                        _getFilterName(type),
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Theme.of(context).primaryColor : null,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
                          : null,
                      onTap: () async {
                        Navigator.pop(context);
                        if (type == AnalyticsFilterType.customDate) {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: Theme.of(context).primaryColor,
                                    onPrimary: Colors.white,
                                    onSurface: Colors.black,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            ref.read(analyticsCustomDateRangeProvider.notifier).state = picked;
                            ref.read(analyticsFilterTypeProvider.notifier).state = AnalyticsFilterType.customDate;
                          }
                        } else {
                          ref.read(analyticsFilterTypeProvider.notifier).state = type;
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getFilterName(AnalyticsFilterType type) {
    switch (type) {
      case AnalyticsFilterType.today:
        return 'Today';
      case AnalyticsFilterType.last7Days:
        return 'Last 7 Days';
      case AnalyticsFilterType.thisMonth:
        return 'This Month';
      case AnalyticsFilterType.lastMonth:
        return 'Last Month';
      case AnalyticsFilterType.last3Months:
        return 'Last 3 Months';
      case AnalyticsFilterType.last6Months:
        return 'Last 6 Months';
      case AnalyticsFilterType.thisYear:
        return 'This Year';
      case AnalyticsFilterType.customDate:
        return 'Custom Date...';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsProvider);
    final familyState = ref.watch(familyProvider);
    final selectedMemberId = ref.watch(analyticsMemberFilterProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Header & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analytics',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Understand where your family's money is going.",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right: Filter Button
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => _showFilterSelector(context, ref, state.filterType),
                icon: Icon(Icons.calendar_today, size: 16, color: Theme.of(context).primaryColor),
                label: Text(
                  _getFilterLabel(state.filterType, state.dateRange),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Member Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All Members'),
                  selected: selectedMemberId == null,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(analyticsMemberFilterProvider.notifier).state = null;
                    }
                  },
                ),
                const SizedBox(width: 8),
                ...familyState.members.map((member) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(member.displayName),
                      selected: selectedMemberId == member.userId,
                      onSelected: (selected) {
                        ref.read(analyticsMemberFilterProvider.notifier).state = selected ? member.userId : null;
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
