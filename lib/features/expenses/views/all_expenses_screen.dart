import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/widgets/shimmer_loading.dart';
import 'package:spendly/models/expense.dart';
import 'package:spendly/features/expenses/widgets/expense_detail_modal.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    {'name': 'All', 'emoji': '🌐', 'iconPath': 'assets/category/globe.svg'},
    {'name': 'Food', 'emoji': '🍔', 'iconPath': 'assets/category/food.svg'},
    {'name': 'Groceries', 'emoji': '🛒', 'iconPath': 'assets/category/groceries.svg'},
    {'name': 'Petrol', 'emoji': '🚗', 'iconPath': 'assets/category/fuel.svg'},
    {'name': 'Recharges', 'emoji': '📱', 'iconPath': 'assets/category/recharge.svg'},
    {'name': 'Travel', 'emoji': '✈️', 'iconPath': 'assets/category/travel.svg'},
    {'name': 'Gas', 'emoji': '⛽', 'iconPath': 'assets/category/gas.svg'},
    {'name': 'Electricity', 'emoji': '⚡', 'iconPath': 'assets/category/electricity.svg'},
    {'name': 'Medical', 'emoji': '💊', 'iconPath': 'assets/category/medical.svg'},
    {'name': 'Insurances', 'emoji': '🛡️', 'iconPath': 'assets/category/insurances.svg'},
    {'name': 'Rent', 'emoji': '🏠', 'iconPath': 'assets/category/rent.svg'},
    {'name': 'Shopping', 'emoji': '🛍️', 'iconPath': 'assets/category/shopping.svg'},
    {'name': 'Entertainment', 'emoji': '🎬', 'iconPath': 'assets/category/entertainment.svg'},
    {'name': 'Education', 'emoji': '📚', 'iconPath': 'assets/category/education.svg'},
    {'name': 'College', 'emoji': '🎓', 'iconPath': 'assets/category/college.svg'},
    {'name': 'Others', 'emoji': '💰', 'iconPath': 'assets/category/others.svg'},
  ];
  /*final List<Map<String, String>> _categories = [
    {'name': 'All', 'emoji': '🌐'},
    {'name': 'Food', 'emoji': '🍔'},
    {'name': 'Groceries', 'emoji': '🛒'},
    {'name': 'Petrol', 'emoji': '🚗'},
    {'name': 'Recharges', 'emoji': '📱'},
    {'name': 'Travel', 'emoji': '✈️'},
    {'name': 'Gas', 'emoji': '⛽'},
    {'name': 'Electricity', 'emoji': '⚡'},
    {'name': 'Medical', 'emoji': '💊'},
    {'name': 'Insurances', 'emoji': '🛡️'},
    {'name': 'Rent', 'emoji': '🏠'},
    {'name': 'Shopping', 'emoji': '🛍️'},
    {'name': 'Entertainment', 'emoji': '🎬'},
    {'name': 'Education', 'emoji': '📚'},
    {'name': 'College', 'emoji': '🎓'},
    {'name': 'Others', 'emoji': '💰'},
  ];*/

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);

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

    // Group expenses by date (formatted as "June 25, 2026")
    final Map<String, List<Expense>> groupedExpenses = {};
    for (var exp in filteredExpenses) {
      final formattedDate = DateFormat('MMMM dd, yyyy').format(exp.expenseDate);
      if (!groupedExpenses.containsKey(formattedDate)) {
        groupedExpenses[formattedDate] = [];
      }
      groupedExpenses[formattedDate]!.add(exp);
    }

    // Sort grouped keys in reverse chronological order
    final groupedKeys = groupedExpenses.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Family Expenses'),
      ),
      body: Builder(
        builder: (context) {
          final isWide = MediaQuery.of(context).size.width > 720;

          // Shared widgets
          Widget searchBar = Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search description, member or amount...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          );

          Widget categoryFiltersHorizontal = SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedFilterCategory == cat['name'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    avatar: SvgPicture.asset(
                      cat['iconPath'] ?? 'assets/category/others.svg',
                      
                      width: 20, //18
                      height: 20, //18
                      colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
                    ),
                    label: Text(cat['name'] ?? ''),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilterCategory = cat['name']!;
                      });
                    },

                    /*avatar: Text(cat['emoji'] ?? '💰'),
                    label: Text(cat['name'] ?? ''),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilterCategory = cat['name']!;
                      });
                    },*/
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).primaryColor,
                  ),
                );
              },
            ),
          );

          Widget categoryFiltersWrap = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final isSelected = _selectedFilterCategory == cat['name'];
              return FilterChip(
                avatar: SvgPicture.asset(
                  cat['iconPath'] ?? 'assets/category/others.svg',
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
                ),
                label: Text(cat['name'] ?? ''),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilterCategory = cat['name']!;
                  });
                },
                selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                checkmarkColor: Theme.of(context).primaryColor,
              );
            }).toList(),
          );

          // Calculate filtered summary statistics
          final totalSpentFiltered = filteredExpenses.fold<double>(0.0, (sum, exp) => sum + exp.amount);
          final formattedTotal = NumberFormat.currency(
            locale: 'en_IN',
            decimalDigits: 2,
            symbol: '₹',
          ).format(totalSpentFiltered);

          Widget summaryPanel = Card(
            margin: const EdgeInsets.all(16.0),
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.15)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Transactions:', style: TextStyle(color: Colors.grey)),
                      Text(
                        '${filteredExpenses.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filtered Spend:', style: TextStyle(color: Colors.grey)),
                      Text(
                        formattedTotal,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );

          Widget expensesListView = expenseState.isLoading
              ? ShimmerLoading(
                  isLoading: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: const ShimmerListPlaceholder(itemCount: 8),
                  ),
                )
              : filteredExpenses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No expenses found',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text('Try adjusting filters or search query.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, isWide ? 0.0 : 90.0), //100
                      itemCount: groupedKeys.length,
                      itemBuilder: (context, groupIndex) {
                        final dateKey = groupedKeys[groupIndex];
                        final groupItems = groupedExpenses[dateKey]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sticky-style Date Header
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Text(
                                _getDateHeaderLabel(dateKey),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),

                            // Card containing the day's expenses list
                            Card(
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: List.generate(groupItems.length, (index) {
                                  final exp = groupItems[index];
                                  final amtStr = NumberFormat.currency(
                                    locale: 'en_IN',
                                    decimalDigits: 0,
                                    symbol: '₹',
                                  ).format(exp.amount);

                                  final isLast = index == groupItems.length - 1;

                                  return Column(
                                    children: [
                                      ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                        leading: CircleAvatar(
                                          radius: 22,
                                          backgroundColor: getCategoryColor(exp.category).withOpacity(0.12),
                                          child: SvgPicture.asset(
                                            getCategoryIconPath(exp.category),
                                            width: 24,
                                            height: 24,
                                            colorFilter: ColorFilter.mode(getCategoryColor(exp.category), BlendMode.srcIn),
                                          ),
                                        ),
                                        title: Row(
                                          children: [
                                            Text(
                                              exp.category,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                exp.createdByName,
                                                style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                                              ),
                                            ),
                                          ],
                                        ),
                                        subtitle: Text(
                                          exp.description.isNotEmpty ? exp.description : 'Logged via ${exp.paymentMethod}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: Text(
                                          amtStr,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        onTap: () => showExpenseDetail(context, ref, exp),
                                      ),
                                      if (!isLast) const Divider(height: 1, indent: 70),
                                    ],
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Search & Filters
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        searchBar,
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Filter by Category',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 12),
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
                // Divider
                VerticalDivider(width: 1, color: Colors.grey[300]),
                // Right Column: Expenses List
                Expanded(
                  flex: 6,
                  child: expensesListView,
                ),
              ],
            );
          } else {
            return Column(
              children: [
                searchBar,
                categoryFiltersHorizontal,
                const SizedBox(height: 12),
                Expanded(child: expensesListView),
              ],
            );
          }
        },
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

