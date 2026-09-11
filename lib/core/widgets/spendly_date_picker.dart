import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Shows an advanced, beautifully styled date picker matching Spendly's design system.
Future<DateTime?> showSpendlyDatePicker({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String title = 'Select Expense Date',
}) async {
  return showDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    builder: (context) => SpendlyDatePickerDialog(
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2030),
      title: title,
    ),
  );
}

class SpendlyDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;

  const SpendlyDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.title = 'Select Expense Date',
  });

  @override
  State<SpendlyDatePickerDialog> createState() =>
      _SpendlyDatePickerDialogState();
}

class _SpendlyDatePickerDialogState extends State<SpendlyDatePickerDialog> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;
  bool _isMonthYearPickerOpen = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  void _onDateSelected(DateTime date) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
      if (_currentMonth.year != date.year ||
          _currentMonth.month != date.month) {
        _currentMonth = DateTime(date.year, date.month, 1);
      }
    });
  }

  void _previousMonth() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + 1,
        1,
      );
    });
  }

  String _getRelativeLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diffDays = today.difference(target).inDays;

    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Yesterday';
    if (diffDays == 2) return '2 days ago';
    if (diffDays == -1) return 'Tomorrow';
    return DateFormat('EEEE').format(date);
  }

  Color _getRelativeBadgeColor(DateTime date, ColorScheme colorScheme) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diffDays = today.difference(target).inDays;

    if (diffDays == 0) return const Color(0xFF22C55E); // Green
    if (diffDays == 1) return colorScheme.primary;
    if (diffDays == 2) return const Color(0xFF8B5CF6); // Purple
    return colorScheme.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final heroBg = isDark
        ? const Color(0xFF0F172A)
        : colorScheme.primary.withValues(alpha: 0.04);

    return Dialog(
      backgroundColor: cardBg,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: borderColor, width: 1.2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Bar
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                      backgroundColor: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Selected Date Hero Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: heroBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            const Color(0xFF636AE8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('d').format(_selectedDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('MMM').format(_selectedDate).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, yyyy').format(_selectedDate),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('MMMM d, yyyy').format(_selectedDate),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _getRelativeBadgeColor(_selectedDate, colorScheme)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getRelativeLabel(_selectedDate),
                        style: TextStyle(
                          color: _getRelativeBadgeColor(_selectedDate, colorScheme),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Quick Shortcuts Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildShortcutChip(
                      label: 'Today',
                      icon: Icons.bolt_rounded,
                      date: DateTime.now(),
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildShortcutChip(
                      label: 'Yesterday',
                      icon: Icons.history_rounded,
                      date: DateTime.now().subtract(const Duration(days: 1)),
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildShortcutChip(
                      label: '2 Days Ago',
                      icon: Icons.calendar_today_rounded,
                      date: DateTime.now().subtract(const Duration(days: 2)),
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildShortcutChip(
                      label: '1st of Month',
                      icon: Icons.first_page_rounded,
                      date: DateTime(
                        _currentMonth.year,
                        _currentMonth.month,
                        1,
                      ),
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Month Navigation & Year Selector Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _isMonthYearPickerOpen = !_isMonthYearPickerOpen;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('MMMM yyyy').format(_currentMonth),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _isMonthYearPickerOpen
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        visualDensity: VisualDensity.compact,
                        onPressed: _previousMonth,
                        tooltip: 'Previous Month',
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurface,
                          backgroundColor: isDark
                              ? const Color(0xFF334155).withValues(alpha: 0.5)
                              : const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        visualDensity: VisualDensity.compact,
                        onPressed: _nextMonth,
                        tooltip: 'Next Month',
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurface,
                          backgroundColor: isDark
                              ? const Color(0xFF334155).withValues(alpha: 0.5)
                              : const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 5. Calendar Grid OR Fast Month-Year Selector
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: _isMonthYearPickerOpen
                    ? _buildMonthYearSelector(theme, colorScheme, isDark)
                    : _buildCalendarGrid(theme, colorScheme, isDark),
              ),
              const SizedBox(height: 20),

              // 6. Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(
                          color: borderColor,
                          width: 1.2,
                        ),
                        foregroundColor: colorScheme.onSurfaceVariant,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).pop(_selectedDate);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        shadowColor: colorScheme.primary.withValues(alpha: 0.4),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Confirm Date',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutChip({
    required String label,
    required IconData icon,
    required DateTime date,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    final isSelected = _selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day;

    return InkWell(
      onTap: () => _onDateSelected(date),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : isDark
                  ? const Color(0xFF334155).withValues(alpha: 0.6)
                  : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : colorScheme.primary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? const Color(0xFFF8FAFC)
                        : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(
      _currentMonth.year,
      _currentMonth.month,
    );

    // Monday is weekday 1 in Dart, Sunday is 7
    final firstWeekdayOffset = firstDayOfMonth.weekday - 1;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      key: ValueKey('calendar_${_currentMonth.year}_${_currentMonth.month}'),
      children: [
        // Weekday header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.asMap().entries.map((entry) {
              final isWeekend = entry.key >= 5;
              return Expanded(
                child: Center(
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isWeekend
                          ? colorScheme.primary.withValues(alpha: 0.8)
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 1, thickness: 0.8),
        const SizedBox(height: 6),

        // Day cells
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 42, // 6 weeks * 7 days
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            final dayNumber = index - firstWeekdayOffset + 1;

            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox.shrink();
            }

            final cellDate = DateTime(
              _currentMonth.year,
              _currentMonth.month,
              dayNumber,
            );
            final isSelected = cellDate.year == _selectedDate.year &&
                cellDate.month == _selectedDate.month &&
                cellDate.day == _selectedDate.day;

            final isToday = cellDate.year == today.year &&
                cellDate.month == today.month &&
                cellDate.day == today.day;

            final isFuture = cellDate.isAfter(today);

            return InkWell(
              onTap: () => _onDateSelected(cellDate),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            colorScheme.primary,
                            const Color(0xFF636AE8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected
                      ? null
                      : isToday
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: isToday && !isSelected
                      ? Border.all(
                          color: colorScheme.primary,
                          width: 1.5,
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w900
                          : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? colorScheme.primary
                              : isFuture
                                  ? colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.6)
                                  : colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMonthYearSelector(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final years = List.generate(
      widget.lastDate.year - widget.firstDate.year + 1,
      (i) => widget.firstDate.year + i,
    );

    return Column(
      key: const ValueKey('month_year_selector'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Year scroll selector
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: years.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final y = years[index];
              final isCurrentYear = y == _currentMonth.year;
              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _currentMonth = DateTime(y, _currentMonth.month, 1);
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCurrentYear
                        ? colorScheme.primary
                        : isDark
                            ? const Color(0xFF334155).withValues(alpha: 0.5)
                            : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$y',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isCurrentYear ? FontWeight.w800 : FontWeight.w600,
                      color: isCurrentYear
                          ? Colors.white
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // 3x4 Month Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 12,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.4,
          ),
          itemBuilder: (context, index) {
            final monthNum = index + 1;
            final isCurrentMonth = monthNum == _currentMonth.month;

            return InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _currentMonth = DateTime(
                    _currentMonth.year,
                    monthNum,
                    1,
                  );
                  _isMonthYearPickerOpen = false;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isCurrentMonth
                      ? colorScheme.primary
                      : isDark
                          ? const Color(0xFF334155).withValues(alpha: 0.3)
                          : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrentMonth
                        ? colorScheme.primary
                        : isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Text(
                  months[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isCurrentMonth ? FontWeight.w800 : FontWeight.w600,
                    color: isCurrentMonth
                        ? Colors.white
                        : colorScheme.onSurface,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
