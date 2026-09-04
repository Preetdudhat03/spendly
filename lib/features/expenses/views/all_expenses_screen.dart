import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/widgets/capsule_top_bar.dart';
import 'package:spendly/core/widgets/shimmer_loading.dart';
import 'package:spendly/features/expenses/widgets/expense_detail_modal.dart';
import 'package:spendly/models/expense.dart';

class AllExpensesScreen extends ConsumerStatefulWidget {
  const AllExpensesScreen({super.key});

  @override
  ConsumerState<AllExpensesScreen> createState() => _AllExpensesScreenState();
}

class _AllExpensesScreenState extends ConsumerState<AllExpensesScreen> {
  final _searchController = TextEditingController();
  String _selectedFilterCategory = 'All';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'iconPath': 'assets/category/globe.svg'},
    {'name': 'Food', 'iconPath': 'assets/category/food.svg'},
    {'name': 'Groceries', 'iconPath': 'assets/category/groceries.svg'},
    {'name': 'Petrol', 'iconPath': 'assets/category/fuel.svg'},
    {'name': 'Recharges', 'iconPath': 'assets/category/recharge.svg'},
    {'name': 'Travel', 'iconPath': 'assets/category/travel.svg'},
    {'name': 'Gas', 'iconPath': 'assets/category/gas.svg'},
    {'name': 'Electricity', 'iconPath': 'assets/category/electricity.svg'},
    {'name': 'Medical', 'iconPath': 'assets/category/medical.svg'},
    {'name': 'Insurances', 'iconPath': 'assets/category/insurances.svg'},
    {'name': 'Rent', 'iconPath': 'assets/category/rent.svg'},
    {'name': 'Shopping', 'iconPath': 'assets/category/shopping.svg'},
    {'name': 'Entertainment', 'iconPath': 'assets/category/entertainment.svg'},
    {'name': 'Education', 'iconPath': 'assets/category/education.svg'},
    {'name': 'College', 'iconPath': 'assets/category/college.svg'},
    {'name': 'Others', 'iconPath': 'assets/category/others.svg'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Apply filtering & searching
    final filteredExpenses = expenseState.expenses.where((e) {
      final matchesCategory = _selectedFilterCategory == 'All' ||
          e.category.toLowerCase() == _selectedFilterCategory.toLowerCase();
      final matchesSearch = e.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.amount.toString().contains(_searchQuery) ||
          e.createdByName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    // Group expenses by date (formatted as "MMMM dd, yyyy")
    final Map<String, List<Expense>> groupedExpenses = {};
    for (var exp in filteredExpenses) {
      final formattedDate = DateFormat('MMMM dd, yyyy').format(exp.expenseDate);
      if (!groupedExpenses.containsKey(formattedDate)) {
        groupedExpenses[formattedDate] = [];
      }
      groupedExpenses[formattedDate]!.add(exp);
    }

    final groupedKeys = groupedExpenses.keys.toList();

    final isWide = MediaQuery.of(context).size.width > 720;
    final topInset = MediaQuery.of(context).padding.top;
    final contentTopPadding = topInset + 58.0;

    // Search Bar Widget
    Widget searchBar = Padding(
      padding: EdgeInsets.fromLTRB(16.0, contentTopPadding, 16.0, 8.0),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search description, member or amount...',
          prefixIcon: Icon(Icons.search_rounded, color: colorScheme.onSurfaceVariant),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: theme.cardTheme.color ?? colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark
                  ? colorScheme.outline.withValues(alpha: 0.4)
                  : colorScheme.outline.withValues(alpha: 0.8),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark
                  ? colorScheme.outline.withValues(alpha: 0.4)
                  : colorScheme.outline.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );

    Widget buildCategoryChip(Map<String, dynamic> cat) {
      final isSelected = _selectedFilterCategory == cat['name'];
      final iconColor = isSelected
          ? (isDark ? Colors.white : colorScheme.primary)
          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));
      final textColor = isSelected
          ? (isDark ? Colors.white : colorScheme.primary)
          : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155));
      final bgColor = isSelected
          ? (isDark ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0.15))
          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));
      final borderColor = isSelected
          ? colorScheme.primary
          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedFilterCategory = cat['name']!;
            });
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  cat['iconPath'] ?? 'assets/category/others.svg',
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
                const SizedBox(width: 6),
                Text(
                  cat['name'] ?? '',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget categoryFiltersHorizontal = SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: buildCategoryChip(cat),
          );
        },
      ),
    );

    Widget categoryFiltersWrap = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((cat) => buildCategoryChip(cat)).toList(),
    );

    // Calculate filtered summary statistics
    final totalSpentFiltered = filteredExpenses.fold<double>(0.0, (sum, exp) => sum + exp.amount);
    final formattedTotal = NumberFormat.currency(
      locale: 'en_IN',
      decimalDigits: 0,
      symbol: '₹',
    ).format(totalSpentFiltered);

    Widget summaryPanel = Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface.withValues(alpha: 0.7)
            : colorScheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? colorScheme.outline.withValues(alpha: 0.4)
              : colorScheme.primary.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FILTERED SUMMARY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Entries', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
              Text(
                '${filteredExpenses.length} transactions',
                style: TextStyle(fontWeight: FontWeight.w700, color: colorScheme.onSurface, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Spending', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
              Text(
                formattedTotal,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    Widget expensesListView = expenseState.isLoading
        ? const ShimmerLoading(
            isLoading: true,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: ShimmerListPlaceholder(itemCount: 8),
            ),
          )
        : filteredExpenses.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.receipt_long_outlined, size: 48, color: colorScheme.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions found',
                        style: TextStyle(fontSize: 16, color: colorScheme.onSurface, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try adjusting your search or category filter',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, isWide ? 20.0 : 100.0),
                itemCount: groupedKeys.length,
                itemBuilder: (context, groupIndex) {
                  final dateKey = groupedKeys[groupIndex];
                  final groupItems = groupedExpenses[dateKey]!;
                  final groupTotal = groupItems.fold<double>(0.0, (sum, e) => sum + e.amount);
                  final groupTotalStr = NumberFormat.currency(
                    locale: 'en_IN',
                    decimalDigits: 0,
                    symbol: '₹',
                  ).format(groupTotal);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Group Header with Day Total Pill
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getDateHeaderLabel(dateKey),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurfaceVariant,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? colorScheme.surfaceContainer
                                    : colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                groupTotalStr,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Day's Expenses List Card
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color ?? colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? colorScheme.outline.withValues(alpha: 0.4)
                                : colorScheme.outline.withValues(alpha: 0.8),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.15)
                                  : colorScheme.shadow.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          children: List.generate(groupItems.length, (index) {
                            final exp = groupItems[index];
                            final amtStr = NumberFormat.currency(
                              locale: 'en_IN',
                              decimalDigits: 0,
                              symbol: '₹',
                            ).format(exp.amount);
                            final catColor = getCategoryColor(exp.category);
                            final iconPath = getCategoryIconPath(exp.category);
                            final isLast = index == groupItems.length - 1;

                            return Column(
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => showExpenseDetail(context, ref, exp),
                                    borderRadius: BorderRadius.vertical(
                                      top: index == 0 ? const Radius.circular(20) : Radius.zero,
                                      bottom: isLast ? const Radius.circular(20) : Radius.zero,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            padding: const EdgeInsets.all(9),
                                            decoration: BoxDecoration(
                                              color: catColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: SvgPicture.asset(
                                              iconPath,
                                              colorFilter: ColorFilter.mode(catColor, BlendMode.srcIn),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  exp.description.isNotEmpty ? exp.description : exp.category,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
                                                    color: colorScheme.onSurface,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: isDark
                                                            ? colorScheme.surfaceContainer
                                                            : colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        exp.createdByName,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w600,
                                                          color: colorScheme.onSurfaceVariant,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'via ${exp.paymentMethod}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: colorScheme.onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '-$amtStr',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              color: Color(0xFFEF4444),
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (!isLast)
                                  Divider(
                                    height: 1,
                                    indent: 68,
                                    color: isDark
                                        ? colorScheme.outline.withValues(alpha: 0.2)
                                        : colorScheme.outline.withValues(alpha: 0.4),
                                  ),
                              ],
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: CapsuleHeader(
          title: 'All Expenses',
          icon: Icons.receipt_long_rounded,
          badge: filteredExpenses.isNotEmpty ? '${filteredExpenses.length}' : null,
        ),
      ),
      body: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        searchBar,
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            'Filter by Category',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: categoryFiltersWrap,
                        ),
                        const SizedBox(height: 16),
                        summaryPanel,
                      ],
                    ),
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  color: isDark
                      ? colorScheme.outline.withValues(alpha: 0.2)
                      : colorScheme.outline.withValues(alpha: 0.4),
                ),
                Expanded(
                  flex: 6,
                  child: expensesListView,
                ),
              ],
            )
          : Column(
              children: [
                searchBar,
                categoryFiltersHorizontal,
                const SizedBox(height: 8),
                Expanded(child: expensesListView),
              ],
            ),
    );
  }

  String _getDateHeaderLabel(String formattedDate) {
    final now = DateTime.now();
    final today = DateFormat('MMMM dd, yyyy').format(now);
    final yesterday = DateFormat('MMMM dd, yyyy').format(now.subtract(const Duration(days: 1)));

    if (formattedDate == today) {
      return 'TODAY';
    } else if (formattedDate == yesterday) {
      return 'YESTERDAY';
    }
    return formattedDate.toUpperCase();
  }
}
