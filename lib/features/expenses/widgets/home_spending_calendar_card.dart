import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/utils/currency_formatter.dart';
import 'package:spendly/features/analytics/presentation/widgets/drill_down_sheet.dart';
import 'package:spendly/features/analytics/presentation/widgets/spending_heatmap_explorer.dart';
import 'package:spendly/models/expense.dart';

/// Compact interactive monthly spending calendar card for the Home page.
///
/// Displays all family expenses for the selected month (defaulting to the
/// current month), monthly summary stats (Total Spent, Daily Average, Peak Day),
/// a Sunday-first 7-column heatmap grid, and opens [DrillDownSheet] (or an
/// empty-day sheet) when any day is tapped.
class HomeSpendingCalendarCard extends StatefulWidget {
  final List<Expense> expenses;
  final NumberFormat currencyFormat;

  /// Optional initial month (primarily for deterministic testing).
  /// Defaults to `DateTime.now()`.
  final DateTime? initialMonth;

  /// Optional reference "today" date (primarily for deterministic testing).
  /// Defaults to `DateTime.now()`.
  final DateTime? referenceNow;

  const HomeSpendingCalendarCard({
    super.key,
    required this.expenses,
    required this.currencyFormat,
    this.initialMonth,
    this.referenceNow,
  });

  @override
  State<HomeSpendingCalendarCard> createState() =>
      _HomeSpendingCalendarCardState();
}

class _HomeSpendingCalendarCardState extends State<HomeSpendingCalendarCard> {
  static const List<String> _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  late int _displayYear;
  late int _displayMonth;
  DateTime? _selectedDate;

  // Memoized monthly aggregation to avoid per-cell filtering during build.
  Map<int, List<Expense>> _dayExpensesMap = {};
  Map<int, double> _dayTotalsMap = {};
  double _monthTotal = 0.0;
  double _dailyAvg = 0.0;
  int _peakDay = 1;
  double _peakDayAmount = 0.0;
  int _daysInMonth = 30;

  DateTime get _now => widget.referenceNow ?? DateTime.now();

  bool get _canGoNext {
    final now = _now;
    return _displayYear < now.year ||
        (_displayYear == now.year && _displayMonth < now.month);
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMonth ?? _now;
    _displayYear = initial.year;
    _displayMonth = initial.month;
    _recomputeMonthAggregation();
  }

  @override
  void didUpdateWidget(covariant HomeSpendingCalendarCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.expenses, widget.expenses) ||
        oldWidget.expenses.length != widget.expenses.length) {
      _recomputeMonthAggregation();
    }
  }

  void _recomputeMonthAggregation() {
    final daysInMonth = DateUtils.getDaysInMonth(_displayYear, _displayMonth);
    final Map<int, List<Expense>> grouped = {};
    final Map<int, double> totals = {};
    double totalSpent = 0.0;

    for (final exp in widget.expenses) {
      final d = exp.expenseDate;
      if (d.year == _displayYear && d.month == _displayMonth) {
        grouped.putIfAbsent(d.day, () => []).add(exp);
        totals[d.day] = (totals[d.day] ?? 0.0) + exp.amount;
        totalSpent += exp.amount;
      }
    }

    int peakDay = 1;
    double peakAmount = 0.0;
    for (int day = 1; day <= daysInMonth; day++) {
      final amt = totals[day] ?? 0.0;
      if (amt > peakAmount) {
        peakAmount = amt;
        peakDay = day;
      }
    }

    _daysInMonth = daysInMonth;
    _dayExpensesMap = grouped;
    _dayTotalsMap = totals;
    _monthTotal = totalSpent;
    _dailyAvg = daysInMonth > 0 ? totalSpent / daysInMonth : 0.0;
    _peakDay = peakDay;
    _peakDayAmount = peakAmount;
  }

  void _previousMonth() {
    setState(() {
      if (_displayMonth > 1) {
        _displayMonth--;
      } else {
        _displayYear--;
        _displayMonth = 12;
      }
      _selectedDate = null;
      _recomputeMonthAggregation();
    });
  }

  void _nextMonth() {
    if (!_canGoNext) return;
    setState(() {
      if (_displayMonth < 12) {
        _displayMonth++;
      } else {
        _displayYear++;
        _displayMonth = 1;
      }
      _selectedDate = null;
      _recomputeMonthAggregation();
    });
  }

  /// Intensity fill matching Spendly's Analytics heatmap tiers.
  Color _getIntensityColor(BuildContext context, double amount) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    if (amount <= 0) {
      return colorScheme.surfaceContainerHigh.withValues(alpha: 0.45);
    } else if (amount <= 500) {
      return primary.withValues(alpha: 0.16);
    } else if (amount <= 2000) {
      return primary.withValues(alpha: 0.45);
    } else if (amount <= 5000) {
      return primary.withValues(alpha: 0.72);
    } else {
      return primary;
    }
  }

  String _getSemanticIntensityLabel(double amount) {
    if (amount <= 0) return 'No spending';
    if (amount <= 500) return 'Low spending';
    if (amount <= 2000) return 'Moderate spending';
    if (amount <= 5000) return 'High spending';
    return 'Very high spending';
  }

  /// Compact currency label for narrow calendar cells (e.g., ₹29.6k, ₹1,368).
  String _formatCellAmount(double amount) {
    if (amount >= 100000) {
      final lakhs = amount / 100000;
      return '₹${lakhs.toStringAsFixed(1)}L';
    }
    if (amount >= 10000) {
      final thousands = amount / 1000;
      return '₹${thousands.toStringAsFixed(1)}k';
    }
    if (amount % 1 == 0) {
      return NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 0,
      ).format(amount);
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  void _onDayTapped(int day) {
    final tappedDate = DateTime(_displayYear, _displayMonth, day);
    setState(() {
      _selectedDate = tappedDate;
    });

    final dayExpenses = List<Expense>.from(_dayExpensesMap[day] ?? [])
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final dayTotal = _dayTotalsMap[day] ?? 0.0;

    if (dayExpenses.isEmpty) {
      _showEmptyDaySheet(tappedDate);
      return;
    }

    final highest = dayExpenses.first;
    final highestLabel = highest.description.trim().isNotEmpty
        ? highest.description.trim()
        : highest.category;

    DrillDownSheet.show(
      context,
      title: DateFormat('EEEE, d MMMM yyyy').format(tappedDate),
      subtitle:
          '${dayExpenses.length} transaction${dayExpenses.length == 1 ? '' : 's'}',
      icon: Icons.calendar_today_rounded,
      color: Theme.of(context).colorScheme.primary,
      totalAmount: dayTotal,
      expenses: dayExpenses,
      aiSummary:
          '${dayExpenses.length} transaction${dayExpenses.length == 1 ? '' : 's'} logged • Highest: ${CurrencyFormatter.format(highest.amount)} ($highestLabel)',
    );
  }

  void _showEmptyDaySheet(DateTime date) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(date);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardTheme.color ?? colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh.withValues(
                      alpha: 0.45,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.event_available_rounded,
                    size: 28,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'No expenses on this day',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your family did not log any spending on this date.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      context.push('/add-expense');
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Expense'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final now = _now;

    final displayMonthDate = DateTime(_displayYear, _displayMonth, 1);
    final monthYearLabel = DateFormat('MMMM yyyy').format(displayMonthDate);
    final shortMonthLabel = DateFormat('MMM').format(displayMonthDate);

    // Sunday-first alignment: DateTime.sunday == 7 -> offset 0
    final firstWeekday = displayMonthDate.weekday;
    final startOffset = (firstWeekday == 7) ? 0 : firstWeekday;
    final totalGridCells = ((startOffset + _daysInMonth) / 7.0).ceil() * 7;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? colorScheme.outline.withValues(alpha: 0.4)
              : colorScheme.outline.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. Calendar Header
          _buildHeader(context, monthYearLabel),
          const SizedBox(height: 14),

          // Smooth transition when navigating between months
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: Column(
              key: ValueKey('$_displayYear-$_displayMonth'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // B. Monthly Summary Strip
                _buildSummaryStrip(context, shortMonthLabel),
                const SizedBox(height: 16),

                // C. Weekday Headers (S M T W T F S)
                Row(
                  children: _weekdays.map((day) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),

                // C. 7-Column Calendar Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: totalGridCells,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 0.92,
                  ),
                  itemBuilder: (context, index) {
                    final dayNum = index - startOffset + 1;
                    if (dayNum < 1 || dayNum > _daysInMonth) {
                      return const SizedBox.shrink();
                    }
                    return _buildDayCell(
                      context,
                      dayNum: dayNum,
                      now: now,
                      monthYearLabel: monthYearLabel,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Spending Scale Legend
          _buildLegendFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String monthYearLabel) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Spending',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                monthYearLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Previous Month',
          visualDensity: VisualDensity.compact,
          onPressed: _previousMonth,
          icon: Icon(
            Icons.chevron_left_rounded,
            size: 22,
            color: colorScheme.onSurface,
          ),
        ),
        IconButton(
          tooltip: 'Next Month',
          visualDensity: VisualDensity.compact,
          onPressed: _canGoNext ? _nextMonth : null,
          icon: Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: _canGoNext
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
          ),
        ),
        IconButton(
          tooltip: 'Open Full Calendar Explorer',
          visualDensity: VisualDensity.compact,
          onPressed: () {
            SpendingHeatmapExplorer.show(
              context,
              expenses: widget.expenses,
              initialYear: _displayYear,
              initialMonth: _displayMonth,
            );
          },
          icon: Icon(
            Icons.calendar_month_outlined,
            size: 20,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStrip(BuildContext context, String shortMonthLabel) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasSpending = _monthTotal > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetric(
              label: 'Total Spent',
              value: CurrencyFormatter.format(_monthTotal),
              valueColor: colorScheme.primary,
              isEmphasized: true,
            ),
          ),
          _verticalDivider(colorScheme),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _SummaryMetric(
                label: 'Daily Avg',
                value: CurrencyFormatter.format(_dailyAvg),
                valueColor: colorScheme.onSurface,
              ),
            ),
          ),
          _verticalDivider(colorScheme),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _SummaryMetric(
                label: 'Peak Day',
                value: hasSpending
                    ? '$_peakDay $shortMonthLabel (${_formatCellAmount(_peakDayAmount)})'
                    : '—',
                valueColor: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider(ColorScheme colorScheme) {
    return Container(
      height: 28,
      width: 1,
      color: colorScheme.outline.withValues(alpha: 0.2),
    );
  }

  Widget _buildDayCell(
    BuildContext context, {
    required int dayNum,
    required DateTime now,
    required String monthYearLabel,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final amt = _dayTotalsMap[dayNum] ?? 0.0;
    final bgColor = _getIntensityColor(context, amt);

    final isToday = now.year == _displayYear &&
        now.month == _displayMonth &&
        now.day == dayNum;
    final isSelected = _selectedDate != null &&
        _selectedDate!.year == _displayYear &&
        _selectedDate!.month == _displayMonth &&
        _selectedDate!.day == dayNum;

    final isHighIntensity = amt > 2000;
    final dayTextColor =
        isHighIntensity ? colorScheme.onPrimary : colorScheme.onSurface;
    final amtTextColor = isHighIntensity
        ? colorScheme.onPrimary.withValues(alpha: 0.92)
        : colorScheme.primary;

    // Distinct visual borders: Selected uses secondary/onSurface; Today uses primary (or onPrimary on deep fill).
    final Color borderColor;
    final double borderWidth;
    if (isSelected) {
      borderColor =
          isHighIntensity ? colorScheme.onPrimary : colorScheme.secondary;
      borderWidth = 2.2;
    } else if (isToday) {
      borderColor =
          amt > 5000 ? colorScheme.onPrimary : colorScheme.primary;
      borderWidth = 2.0;
    } else {
      borderColor = colorScheme.outline.withValues(alpha: 0.18);
      borderWidth = 0.6;
    }

    return Semantics(
      label:
          '$dayNum $monthYearLabel. Spending ${CurrencyFormatter.format(amt)}. ${_getSemanticIntensityLabel(amt)}',
      button: true,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onDayTapped(dayNum),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: isToday
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.25),
                        blurRadius: 4,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$dayNum',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight:
                        (isToday || isSelected) ? FontWeight.w900 : FontWeight.w700,
                    color: dayTextColor,
                    height: 1.1,
                  ),
                ),
                if (amt > 0) ...[
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatCellAmount(amt),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: amtTextColor,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendFooter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tiers = [
      colorScheme.surfaceContainerHigh.withValues(alpha: 0.45),
      colorScheme.primary.withValues(alpha: 0.16),
      colorScheme.primary.withValues(alpha: 0.45),
      colorScheme.primary.withValues(alpha: 0.72),
      colorScheme.primary,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Spending Scale:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Less',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 5),
            for (final color in tiers) ...[
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ],
            const SizedBox(width: 5),
            Text(
              'More',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool isEmphasized;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isEmphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: isEmphasized ? 15 : 13,
              fontWeight: isEmphasized ? FontWeight.w900 : FontWeight.w700,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
