import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendly/models/expense.dart';

enum ExplorerLevel {
  year,
  month,
  day,
}

class SpendingHeatmapExplorer extends StatefulWidget {
  final List<Expense> expenses;
  final int initialYear;
  final String? activeMemberName;

  const SpendingHeatmapExplorer({
    super.key,
    required this.expenses,
    required this.initialYear,
    this.activeMemberName,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Expense> expenses,
    required int initialYear,
    String? activeMemberName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SpendingHeatmapExplorer(
        expenses: expenses,
        initialYear: initialYear,
        activeMemberName: activeMemberName,
      ),
    );
  }

  @override
  State<SpendingHeatmapExplorer> createState() => _SpendingHeatmapExplorerState();
}

class _SpendingHeatmapExplorerState extends State<SpendingHeatmapExplorer> {
  late ExplorerLevel _level;
  late int _selectedYear;
  int? _selectedMonth; // 1..12
  int? _selectedDay; // 1..31

  // Indexing maps for ultra-fast lookup without recomputation during rebuilds
  late Map<String, List<Expense>> _dailyExpensesMap;
  late Map<String, double> _dailyTotalMap;
  late List<int> _availableYears;

  @override
  void initState() {
    super.initState();
    _level = ExplorerLevel.year;
    _selectedYear = widget.initialYear;
    _indexExpenses();
  }

  void _indexExpenses() {
    _dailyExpensesMap = {};
    _dailyTotalMap = {};
    final Set<int> yearsSet = {widget.initialYear, DateTime.now().year};

    for (final exp in widget.expenses) {
      final key = '${exp.expenseDate.year}-${exp.expenseDate.month}-${exp.expenseDate.day}';
      _dailyExpensesMap.putIfAbsent(key, () => []).add(exp);
      _dailyTotalMap[key] = (_dailyTotalMap[key] ?? 0.0) + exp.amount;
      yearsSet.add(exp.expenseDate.year);
    }

    _availableYears = yearsSet.toList()..sort();
  }

  String _dateKey(int year, int month, int day) => '$year-$month-$day';

  double _getDayTotal(int year, int month, int day) {
    return _dailyTotalMap[_dateKey(year, month, day)] ?? 0.0;
  }

  List<Expense> _getDayExpenses(int year, int month, int day) {
    final list = _dailyExpensesMap[_dateKey(year, month, day)] ?? [];
    return List.from(list)..sort((a, b) => b.amount.compareTo(a.amount));
  }

  Color _getIntensityColor(BuildContext context, double amount) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    if (amount <= 0) {
      return colorScheme.surfaceContainerHigh.withValues(alpha: 0.5);
    } else if (amount <= 500) {
      return primary.withValues(alpha: 0.30);
    } else if (amount <= 2000) {
      return primary.withValues(alpha: 0.65);
    } else {
      return primary;
    }
  }

  String _getSemanticIntensityLabel(double amount) {
    if (amount <= 0) return 'No spending';
    if (amount <= 500) return 'Low spending';
    if (amount <= 2000) return 'Medium spending';
    return 'High spending';
  }

  void _drillUp() {
    if (_level == ExplorerLevel.day) {
      setState(() {
        _level = ExplorerLevel.month;
        _selectedDay = null;
      });
    } else if (_level == ExplorerLevel.month) {
      setState(() {
        _level = ExplorerLevel.year;
        _selectedMonth = null;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void _navigateToYear(int year) {
    setState(() {
      _selectedYear = year;
    });
  }

  void _navigateToMonth(int month, {int? year}) {
    setState(() {
      if (year != null) _selectedYear = year;
      _selectedMonth = month;
      _level = ExplorerLevel.month;
    });
  }

  void _navigateToDay(int day) {
    setState(() {
      _selectedDay = day;
      _level = ExplorerLevel.day;
    });
  }

  void _previousYear() {
    setState(() {
      _selectedYear--;
    });
  }

  void _nextYear() {
    setState(() {
      _selectedYear++;
    });
  }

  void _previousMonth() {
    setState(() {
      if (_selectedMonth != null) {
        if (_selectedMonth! > 1) {
          _selectedMonth = _selectedMonth! - 1;
        } else {
          _selectedYear--;
          _selectedMonth = 12;
        }
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_selectedMonth != null) {
        if (_selectedMonth! < 12) {
          _selectedMonth = _selectedMonth! + 1;
        } else {
          _selectedYear++;
          _selectedMonth = 1;
        }
      }
    });
  }

  void _showYearPickerSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Year',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableYears.length,
                  itemBuilder: (context, index) {
                    final yr = _availableYears[index];
                    final isSelected = yr == _selectedYear;
                    return ListTile(
                      title: Text(
                        '$yr',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                      trailing: isSelected ? Icon(Icons.check_circle, color: colorScheme.primary) : null,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToYear(yr);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMonthPickerSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Month',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final monthNum = index + 1;
                    final isSelected = monthNum == _selectedMonth;
                    return ListTile(
                      title: Text(
                        months[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                      trailing: isSelected ? Icon(Icons.check_circle, color: colorScheme.primary) : null,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToMonth(monthNum);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: _level == ExplorerLevel.year,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _drillUp();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(top: 24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Handle Bar
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 12),

              // Header Bar & Breadcrumb
              _buildHeaderBar(context),
              const Divider(height: 1),

              // Main Body with Swipe Gesture Support
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity != null) {
                      if (details.primaryVelocity! < -300) {
                        // Swipe Left -> Next
                        if (_level == ExplorerLevel.year) {
                          _nextYear();
                        } else if (_level == ExplorerLevel.month) {
                          _nextMonth();
                        }
                      } else if (details.primaryVelocity! > 300) {
                        // Swipe Right -> Previous
                        if (_level == ExplorerLevel.year) {
                          _previousYear();
                        } else if (_level == ExplorerLevel.month) {
                          _previousMonth();
                        }
                      }
                    }
                  },
                  child: _buildBodyContent(context),
                ),
              ),

              // Legend Footer
              const Divider(height: 1),
              _buildLegendFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  // Header Bar with Breadcrumb Navigation
  Widget _buildHeaderBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              // Back Button (Drill-Up or Close)
              IconButton(
                semanticsLabel: _level == ExplorerLevel.year ? 'Close Explorer' : 'Go Back',
                icon: Icon(
                  _level == ExplorerLevel.year ? Icons.close : Icons.arrow_back,
                  color: colorScheme.onSurface,
                ),
                onPressed: _drillUp,
              ),
              const SizedBox(width: 8),

              // Breadcrumb Navigation Context
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    InkWell(
                      onTap: _level != ExplorerLevel.year
                          ? () {
                              setState(() {
                                _level = ExplorerLevel.year;
                                _selectedMonth = null;
                                _selectedDay = null;
                              });
                            }
                          : null,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          '$_selectedYear',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _level == ExplorerLevel.year ? colorScheme.primary : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    if (_level == ExplorerLevel.month || _level == ExplorerLevel.day) ...[
                      Icon(Icons.chevron_right, size: 18, color: colorScheme.onSurfaceVariant),
                      InkWell(
                        onTap: _level == ExplorerLevel.day
                            ? () {
                                setState(() {
                                  _level = ExplorerLevel.month;
                                  _selectedDay = null;
                                });
                              }
                            : null,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            monthNames[_selectedMonth! - 1],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _level == ExplorerLevel.month ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (_level == ExplorerLevel.day && _selectedDay != null) ...[
                      Icon(Icons.chevron_right, size: 18, color: colorScheme.onSurfaceVariant),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          '$_selectedDay',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Filter Badge if member filter active
              if (widget.activeMemberName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.activeMemberName!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(BuildContext context) {
    switch (_level) {
      case ExplorerLevel.year:
        return _buildYearView(context);
      case ExplorerLevel.month:
        return _buildMonthView(context);
      case ExplorerLevel.day:
        return _buildDayView(context);
    }
  }

  // ==========================================
  // YEAR VIEW
  // ==========================================
  Widget _buildYearView(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final colorScheme = Theme.of(context).colorScheme;

    // Calculate Year Statistics
    double totalYearSpent = 0;
    final Map<int, double> monthTotals = {};
    int highestMonth = 1;
    double highestMonthSpent = 0;

    for (int m = 1; m <= 12; m++) {
      final daysInM = DateUtils.getDaysInMonth(_selectedYear, m);
      double mSum = 0;
      for (int d = 1; d <= daysInM; d++) {
        mSum += _getDayTotal(_selectedYear, m, d);
      }
      monthTotals[m] = mSum;
      totalYearSpent += mSum;
      if (mSum > highestMonthSpent) {
        highestMonthSpent = mSum;
        highestMonth = m;
      }
    }

    final avgPerMonth = totalYearSpent / 12;
    final monthNamesShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation Header (‹ 2026 ›)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                semanticsLabel: 'Previous Year',
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                onPressed: _previousYear,
              ),
              InkWell(
                onTap: _showYearPickerSelector,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_selectedYear',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, color: colorScheme.primary),
                    ],
                  ),
                ),
              ),
              IconButton(
                semanticsLabel: 'Next Year',
                icon: const Icon(Icons.arrow_forward_ios, size: 18),
                onPressed: _nextYear,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Year Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Spent', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(currencyFmt.format(totalYearSpent), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: colorScheme.primary)),
                    ],
                  ),
                ),
                Container(height: 30, width: 1, color: colorScheme.outline.withValues(alpha: 0.2)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Monthly Avg', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(currencyFmt.format(avgPerMonth), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                      ],
                    ),
                  ),
                ),
                Container(height: 30, width: 1, color: colorScheme.outline.withValues(alpha: 0.2)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Peak Month', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          totalYearSpent > 0 ? '${monthNamesShort[highestMonth - 1]} (${currencyFmt.format(highestMonthSpent)})' : 'None',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 12 Months Grid (3 columns x 4 rows)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final monthNum = index + 1;
              final mTotal = monthTotals[monthNum] ?? 0.0;
              return Semantics(
                label: '${monthNamesShort[index]} $_selectedYear. Total spending ${currencyFmt.format(mTotal)}',
                button: true,
                child: GestureDetector(
                  onTap: () => _navigateToMonth(monthNum),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              monthNamesShort[index],
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface),
                            ),
                            Icon(Icons.chevron_right, size: 14, color: colorScheme.onSurfaceVariant),
                          ],
                        ),
                        Text(
                          mTotal > 0 ? currencyFmt.format(mTotal) : '₹0',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: mTotal > 0 ? colorScheme.primary : colorScheme.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: _buildMiniMonthHeatmap(context, _selectedYear, monthNum),
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
    );
  }

  // Mini Heatmap representation for Year View tiles
  Widget _buildMiniMonthHeatmap(BuildContext context, int year, int month) {
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstWeekday = DateTime(year, month, 1).weekday; // 1=Mon, 7=Sun
    final startOffset = (firstWeekday == 7) ? 0 : firstWeekday; // Sun=0..Sat=6

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 35, // 5 weeks x 7 days
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemBuilder: (context, idx) {
        final dayNum = idx - startOffset + 1;
        if (dayNum >= 1 && dayNum <= daysInMonth) {
          final amt = _getDayTotal(year, month, dayNum);
          return Container(
            decoration: BoxDecoration(
              color: _getIntensityColor(context, amt),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // ==========================================
  // MONTH VIEW
  // ==========================================
  Widget _buildMonthView(BuildContext context) {
    final month = _selectedMonth ?? 1;
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final colorScheme = Theme.of(context).colorScheme;
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final daysInMonth = DateUtils.getDaysInMonth(_selectedYear, month);
    double totalMonthSpent = 0;
    int totalTransactions = 0;
    int highestDay = 1;
    double highestDaySpent = 0;

    for (int d = 1; d <= daysInMonth; d++) {
      final amt = _getDayTotal(_selectedYear, month, d);
      final exps = _getDayExpenses(_selectedYear, month, d);
      totalMonthSpent += amt;
      totalTransactions += exps.length;
      if (amt > highestDaySpent) {
        highestDaySpent = amt;
        highestDay = d;
      }
    }

    final dailyAvg = totalMonthSpent / daysInMonth;
    final now = DateTime.now();

    // Sunday-first weekday headers
    final weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    final firstWeekday = DateTime(_selectedYear, month, 1).weekday;
    final startOffset = (firstWeekday == 7) ? 0 : firstWeekday;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Navigator (‹ July 2026 ›)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                semanticsLabel: 'Previous Month',
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                onPressed: _previousMonth,
              ),
              InkWell(
                onTap: _showMonthPickerSelector,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${monthNames[month - 1]} $_selectedYear',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, color: colorScheme.primary),
                    ],
                  ),
                ),
              ),
              IconButton(
                semanticsLabel: 'Next Month',
                icon: const Icon(Icons.arrow_forward_ios, size: 18),
                onPressed: _nextMonth,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Month Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Spent', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(currencyFmt.format(totalMonthSpent), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: colorScheme.primary)),
                    ],
                  ),
                ),
                Container(height: 30, width: 1, color: colorScheme.outline.withValues(alpha: 0.2)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Daily Avg', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(currencyFmt.format(dailyAvg), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                      ],
                    ),
                  ),
                ),
                Container(height: 30, width: 1, color: colorScheme.outline.withValues(alpha: 0.2)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Peak Day', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          totalMonthSpent > 0 ? '$highestDay ${monthNames[month - 1].substring(0, 3)} (${currencyFmt.format(highestDaySpent)})' : 'None',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Detailed Calendar Grid
          // Weekday Headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Calendar Grid of Days
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ((startOffset + daysInMonth) / 7.0).ceil() * 7,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final dayNum = index - startOffset + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const SizedBox.shrink();
              }

              final amt = _getDayTotal(_selectedYear, month, dayNum);
              final isToday = now.year == _selectedYear && now.month == month && now.day == dayNum;
              final semanticIntensity = _getSemanticIntensityLabel(amt);

              return Semantics(
                label: '${monthNames[month - 1]} $dayNum, $_selectedYear. Spending ${currencyFmt.format(amt)}. $semanticIntensity',
                button: true,
                child: GestureDetector(
                  onTap: () => _navigateToDay(dayNum),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getIntensityColor(context, amt),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isToday ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.2),
                        width: isToday ? 2.0 : 0.5,
                      ),
                      boxShadow: isToday
                          ? [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNum',
                          style: TextStyle(
                            fontWeight: isToday ? FontWeight.w900 : FontWeight.bold,
                            fontSize: 13,
                            color: amt > 2000 ? colorScheme.onPrimary : colorScheme.onSurface,
                          ),
                        ),
                        if (amt > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            currencyFmt.format(amt),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: amt > 2000 ? colorScheme.onPrimary.withValues(alpha: 0.9) : colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DAY VIEW
  // ==========================================
  Widget _buildDayView(BuildContext context) {
    final month = _selectedMonth ?? 1;
    final day = _selectedDay ?? 1;
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFmt = DateFormat('MMM d, yyyy');
    final colorScheme = Theme.of(context).colorScheme;

    final targetDate = DateTime(_selectedYear, month, day);
    final dayExpenses = _getDayExpenses(_selectedYear, month, day);
    final totalSpent = _getDayTotal(_selectedYear, month, day);

    // Grouping by member & category
    final Map<String, double> memberContributions = {};
    final Map<String, double> categoryBreakdown = {};

    for (final exp in dayExpenses) {
      memberContributions[exp.createdByName] = (memberContributions[exp.createdByName] ?? 0) + exp.amount;
      categoryBreakdown[exp.category] = (categoryBreakdown[exp.category] ?? 0) + exp.amount;
    }

    String topCategory = 'None';
    double topCategoryAmt = 0;
    categoryBreakdown.forEach((cat, amt) {
      if (amt > topCategoryAmt) {
        topCategoryAmt = amt;
        topCategory = cat;
      }
    });

    final sortedMembers = memberContributions.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Day Title & Total Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateFmt.format(targetDate),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dayExpenses.length} transactions recorded',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              Text(
                currencyFmt.format(totalSpent),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: colorScheme.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (dayExpenses.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.event_available, size: 48, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(
                  'No expenses recorded on this day',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          )
        else ...[
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildDetailStatBox(context, 'Top Category', topCategory, Icons.category, Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDetailStatBox(context, 'Peak Category Spend', currencyFmt.format(topCategoryAmt), Icons.monetization_on, Colors.teal),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Family Contribution Breakdown
          if (sortedMembers.length > 1) ...[
            Text('Family Member Contribution', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            const SizedBox(height: 12),
            ...sortedMembers.map((m) {
              final pct = totalSpent > 0 ? (m.value / totalSpent) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(m.key, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor: colorScheme.surfaceContainerHigh,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(currencyFmt.format(m.value), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
          ],

          // Detailed Transactions List
          Text('Transactions List', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          const SizedBox(height: 12),
          ...dayExpenses.map((exp) {
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.15)),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    exp.createdByName.isNotEmpty ? exp.createdByName.substring(0, 1).toUpperCase() : 'M',
                    style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
                  ),
                ),
                title: Text(
                  exp.description.isEmpty ? exp.category : exp.description,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface),
                ),
                subtitle: Text(
                  '${exp.category} • ${exp.paymentMethod} • ${exp.createdByName}',
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                ),
                trailing: Text(
                  currencyFmt.format(exp.amount),
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: colorScheme.primary),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildDetailStatBox(BuildContext context, String label, String value, IconData icon, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // Legend Footer
  Widget _buildLegendFooter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Spending Scale:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
          Row(
            children: [
              Text('Less', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
              const SizedBox(width: 6),
              Container(width: 12, height: 12, decoration: BoxDecoration(color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 3),
              Container(width: 12, height: 12, decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.30), borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 3),
              Container(width: 12, height: 12, decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 3),
              Container(width: 12, height: 12, decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 6),
              Text('More', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}
