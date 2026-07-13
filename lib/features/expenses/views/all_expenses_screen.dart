import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/widgets/shimmer_loading.dart';
import 'package:spendly/core/widgets/spendly/spendly.dart';
import 'package:spendly/models/expense.dart';
import 'package:spendly/features/expenses/widgets/expense_detail_modal.dart';

class AllExpensesScreen extends ConsumerStatefulWidget {
  const AllExpensesScreen({super.key});

  @override
  ConsumerState<AllExpensesScreen> createState() => _AllExpensesScreenState();
}

class _AllExpensesScreenState extends ConsumerState<AllExpensesScreen> {
  final _searchController = TextEditingController();
  String _selectedFilterCategory = 'All';
  String _searchQuery = '';

  final List<Map<String, String>> _categories = [
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
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);
    final spendly = context.spendly;
    final theme = Theme.of(context);

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
            child: SpendlySearchBar(
              controller: _searchController,
              hint: 'Search description, member or amount...',
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              onClear: () {
                setState(() {
                  _searchQuery = '';
                });
              },
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
                  child: SpendlyFilterChip(
                    label: '${cat['emoji']} ${cat['name']}',
                    isSelected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilterCategory = cat['name']!;
                      });
                    },
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
              return SpendlyFilterChip(
                label: '${cat['emoji']} ${cat['name']}',
                isSelected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilterCategory = cat['name']!;
                  });
                },
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

          Widget summaryPanel = SpendlyCard(
            title: 'Summary',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Transactions:', style: TextStyle(color: spendly.colors.neutral500)),
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
                    Text('Filtered Spend:', style: TextStyle(color: spendly.colors.neutral500)),
                    Text(
                      formattedTotal,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: spendly.colors.primary,
                      ),
                    ),
                  ],
                ),
              ],
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
                  ? const SpendlyEmptyState(
                      title: 'No expenses found',
                      description: 'Try adjusting filters or search query.',
                      icon: Icons.receipt_long_outlined,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: groupedKeys.length,
                      itemBuilder: (context, groupIndex) {
                        final dateKey = groupedKeys[groupIndex];
                        final groupItems = groupedExpenses[dateKey]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Text(
                                _getDateHeaderLabel(dateKey),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: spendly.colors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),

                            Card(
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: spendly.radius.large,
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: groupItems.length,
                                separatorBuilder: (context, index) => const SpendlyDivider(),
                                itemBuilder: (context, index) {
                                  final exp = groupItems[index];
                                  final amtStr = NumberFormat.currency(
                                    locale: 'en_IN',
                                    decimalDigits: 0,
                                    symbol: '₹',
                                  ).format(exp.amount);

                                  final catColor = spendly.charts.getCategoryColor(exp.category);

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                    leading: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: catColor.withOpacity(0.12),
                                      child: Text(
                                        _getCategoryEmoji(exp.category),
                                        style: const TextStyle(fontSize: 20),
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
                                            color: theme.brightness == Brightness.dark ? Colors.white12 : Colors.grey[200],
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            exp.createdByName,
                                            style: TextStyle(fontSize: 10, color: spendly.colors.neutral500),
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
                                  );
                                },
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: summaryPanel,
                        ),
                      ],
                    ),
                  ),
                ),
                VerticalDivider(width: 1, color: spendly.colors.neutral200),
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

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return '🍔';
      case 'groceries':
        return '🛒';
      case 'transport':
      case 'fuel':
      case 'petrol':
        return '🚗';
      case 'recharges':
        return '📱';
      case 'travel':
        return '✈️';
      case 'gas':
        return '⛽';
      case 'electricity':
      case 'water':
      case 'utility':
        return '⚡';
      case 'medical':
        return '💊';
      case 'insurances':
        return '🛡️';
      case 'shopping':
        return '🛍️';
      case 'rent':
        return '🏠';
      case 'entertainment':
        return '🎬';
      case 'education':
        return '📚';
      case 'college':
      case 'collage':
        return '🎓';
      default:
        return '💰';
    }
  }
}
