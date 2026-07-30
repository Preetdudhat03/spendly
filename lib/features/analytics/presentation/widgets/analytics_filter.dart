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
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Time Range',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                ...AnalyticsFilterType.values.map((type) {
                  final isSelected = type == currentType;
                  return ListTile(
                    title: Text(
                      _getFilterName(type),
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: colorScheme.primary)
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
                              data: Theme.of(context),
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
                }),
                const SizedBox(height: 16),
              ],
            ),
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
    final colorScheme = Theme.of(context).colorScheme;

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
                            color: colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Understand where your family's money is going.",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
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
                  backgroundColor: colorScheme.primary.withOpacity(0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => _showFilterSelector(context, ref, state.filterType),
                icon: Icon(Icons.calendar_today, size: 16, color: colorScheme.primary),
                label: Text(
                  _getFilterLabel(state.filterType, state.dateRange),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: colorScheme.primary,
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
                  selectedColor: colorScheme.primaryContainer,
                  backgroundColor: colorScheme.surface,
                  labelStyle: TextStyle(
                    color: selectedMemberId == null ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                    fontWeight: selectedMemberId == null ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: selectedMemberId == null ? colorScheme.primary : colorScheme.outline,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(analyticsMemberFilterProvider.notifier).state = null;
                    }
                  },
                ),
                const SizedBox(width: 8),
                ...familyState.members.map((member) {
                  final isSelected = selectedMemberId == member.userId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(member.displayName),
                      selected: isSelected,
                      selectedColor: colorScheme.primaryContainer,
                      backgroundColor: colorScheme.surface,
                      labelStyle: TextStyle(
                        color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? colorScheme.primary : colorScheme.outline,
                      ),
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
