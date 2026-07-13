import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/main.dart';
import 'package:spendly/core/services/suggestions_service.dart';
import 'package:spendly/features/expenses/views/add_expense_screen.dart';
import 'package:spendly/models/expense.dart';
import 'package:spendly/core/widgets/shimmer_loading.dart';
import 'package:spendly/features/expenses/widgets/expense_detail_modal.dart';
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final familyState = ref.watch(familyProvider);
    final expenseState = ref.watch(expenseProvider);
    final budgetState = ref.watch(budgetProvider);

    // Calculations
    final now = DateTime.now();
    final todayExpenses = expenseState.expenses.where((e) {
      return e.expenseDate.year == now.year &&
          e.expenseDate.month == now.month &&
          e.expenseDate.day == now.day;
    });
    final todayTotal = todayExpenses.fold<double>(0, (sum, item) => sum + item.amount);

    final monthExpenses = expenseState.expenses.where((e) {
      return e.expenseDate.year == now.year && e.expenseDate.month == now.month;
    });
    final monthTotal = monthExpenses.fold<double>(0, (sum, item) => sum + item.amount);

    final budgetLimit = budgetState.currentBudget?.monthlyBudget ?? 20000.0; // Default if not set
    final double budgetPercent = budgetLimit > 0 ? (monthTotal / budgetLimit) : 0.0;

    // Determine budget color
    Color budgetColor = const Color(0xFF34D399); // Green (<70%)
    if (budgetPercent > 0.7 && budgetPercent <= 0.9) {
      budgetColor = const Color(0xFFFBBF24); // Orange (70%-90%)
    } else if (budgetPercent > 0.9) {
      budgetColor = const Color(0xFFF87171); // Red (>90%)
    }

    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Suggestions
    final blacklistedKeys = ref.watch(blacklistSuggestionsProvider);
    final suggestions = SuggestionsService.generateSuggestions(expenseState.expenses).where((sug) {
      final key = '${sug.category}|${sug.description}|${sug.amount}';
      return !blacklistedKeys.contains(key);
    }).toList();

    final connection = ref.watch(connectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(familyState.family?.name ?? 'Spendly'),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: connection == ConnectionStatus.online
                        ? Colors.green
                        : (connection == ConnectionStatus.sandbox ? Colors.blue : Colors.amber),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  connection == ConnectionStatus.online
                      ? 'Online'
                      : (connection == ConnectionStatus.sandbox ? 'Offline (Sandbox)' : 'Offline (No Connection)'),
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
      ),
      body: (expenseState.isLoading && expenseState.expenses.isEmpty) || (familyState.isLoading && !familyState.hasLoaded)
          ? ShimmerLoading(
              isLoading: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerPlaceholder(width: 200, height: 28),
                    const SizedBox(height: 18),
                    const Row(
                      children: [
                        Expanded(child: ShimmerPlaceholder(height: 100, borderRadius: 20)),
                        SizedBox(width: 16),
                        Expanded(child: ShimmerPlaceholder(height: 100, borderRadius: 20)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const ShimmerPlaceholder(height: 160, borderRadius: 24),
                    const SizedBox(height: 24),
                    const ShimmerPlaceholder(width: 150, height: 24),
                    const SizedBox(height: 12),
                    const ShimmerListPlaceholder(itemCount: 3),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                ref.read(connectionProvider.notifier).checkConnection();
                await ref.read(syncServiceProvider).syncNow();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Builder(
                builder: (context) {
                  final width = MediaQuery.of(context).size.width;
                  final isWide = width > 720;

                  Widget welcomeMessage = Text(
                    'Hello, ${authState.displayName ?? "Family Member"}! 👋',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                  );

                  Widget summaryRow = Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          'Today\'s Spending',
                          currencyFormat.format(todayTotal),
                          const Color(0xFFE8EAF6),
                          Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          'This Month',
                          currencyFormat.format(monthTotal),
                          const Color(0xFFECFDF5),
                          const Color(0xFF059669),
                        ),
                      ),
                    ],
                  );

                  Widget budgetCard = _buildBudgetCard(
                      context, monthTotal, budgetLimit, budgetPercent, budgetColor, currencyFormat);

                  Widget smartSuggestions = suggestions.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Frequently used Expenses',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: suggestions.length,
                                itemBuilder: (context, index) {
                                  final sug = suggestions[index];
                                  return Container(
                                    width: 220,
                                    margin: const EdgeInsets.only(right: 12),
                                    child: Card(
                                      color: const Color(0xFFF1F5F9),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${sug.description.isEmpty ? sug.category : sug.description} • ${currencyFormat.format(sug.amount)}',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                  ),
                                                ),
                                                PopupMenuButton<String>(
                                                  icon: const Icon(Icons.more_vert, size: 18),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  itemBuilder: (context) => [
                                                    const PopupMenuItem(
                                                      value: 'edit',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.edit_outlined, size: 18),
                                                          SizedBox(width: 8),
                                                          Text('Edit details'),
                                                        ],
                                                      ),
                                                    ),
                                                    const PopupMenuItem(
                                                      value: 'delete',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                                          SizedBox(width: 8),
                                                          Text('Delete card', style: TextStyle(color: Colors.red)),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                  onSelected: (value) async {
                                                    if (value == 'edit') {
                                                      ref.read(selectedCategoryProvider.notifier).state = sug.category;
                                                      ref.read(prefilledAmountProvider.notifier).state = sug.amount;
                                                      ref.read(prefilledDescriptionProvider.notifier).state = sug.description;
                                                      context.go('/add');
                                                    } else if (value == 'delete') {
                                                      final key = '${sug.category}|${sug.description}|${sug.amount}';
                                                      await ref.read(blacklistSuggestionsProvider.notifier).blacklist(key);
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(
                                                            content: Text('Suggestion deleted.'),
                                                            duration: Duration(seconds: 2),
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                            GestureDetector(
                                              onTap: () async {
                                                await ref.read(expenseProvider.notifier).addExpense(
                                                      amount: sug.amount,
                                                      category: sug.category,
                                                      description: sug.description,
                                                      paymentMethod: 'UPI',
                                                      expenseDate: DateTime.now(),
                                                    );
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          'Logged ${sug.description} ${currencyFormat.format(sug.amount)}!'),
                                                      duration: const Duration(seconds: 2),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).primaryColor,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Center(
                                                  child: Text(
                                                    'One Tap Save',
                                                    style: TextStyle(
                                                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );

                  Widget quickAddRow = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Add Category',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildQuickAddButton(context, ref, '🍔', 'Food'),
                            _buildQuickAddButton(context, ref, '🚗', 'Petrol'),
                            _buildQuickAddButton(context, ref, '🛒', 'Groceries'),
                            _buildQuickAddButton(context, ref, '⚡', 'Electricity'),
                            _buildQuickAddButton(context, ref, '💊', 'Medical'),
                          ],
                        ),
                      ),
                    ],
                  );

                  Widget recentExpensesList = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Expenses',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to All Expenses view
                              context.go('/expenses');
                            },
                            child: const Text('View All'),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (expenseState.expenses.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(
                            child: Text(
                              'No expenses logged this month yet.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: expenseState.expenses.length > 5 ? 5 : expenseState.expenses.length,
                          itemBuilder: (context, index) {
                            final exp = expenseState.expenses[index];
                            return _buildExpenseListItem(context, ref, exp, currencyFormat);
                          },
                        ),
                    ],
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              welcomeMessage,
                              const SizedBox(height: 18),
                              summaryRow,
                              const SizedBox(height: 20),
                              budgetCard,
                              const SizedBox(height: 24),
                              smartSuggestions,
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              quickAddRow,
                              const SizedBox(height: 24),
                              recentExpensesList,
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        welcomeMessage,
                        const SizedBox(height: 18),
                        summaryRow,
                        const SizedBox(height: 20),
                        budgetCard,
                        const SizedBox(height: 24),
                        smartSuggestions,
                        if (suggestions.isNotEmpty) const SizedBox(height: 24),
                        quickAddRow,
                        const SizedBox(height: 24),
                        recentExpensesList,
                      ],
                    );
                  }
                },
              ),
            ),
          ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String label,
    String amount,
    Color bg,
    Color textCol,
  ) {
    return Card(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              amount,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textCol),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(
    BuildContext context,
    double spent,
    double limit,
    double percent,
    Color color,
    NumberFormat fmt,
  ) {
    final cleanPercent = percent.clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Family Budget Progress',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${(percent * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                )
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: cleanPercent,
                minHeight: 12,
                color: color,
                backgroundColor: const Color(0xFFE2E8F0),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent: ${fmt.format(spent)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Budget: ${fmt.format(limit)}',
                  style: const TextStyle(color: Colors.grey),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddButton(
    BuildContext context,
    WidgetRef ref,
    String emoji,
    String category,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 80,
      child: InkWell(
        onTap: () {
          ref.read(selectedCategoryProvider.notifier).state = category;
          context.go('/add');
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(
                category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseListItem(
    BuildContext context,
    WidgetRef ref,
    Expense exp,
    NumberFormat fmt,
  ) {
    final dayStr = DateFormat('dd MMM').format(exp.expenseDate);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              _getCategoryEmoji(exp.category),
              style: const TextStyle(fontSize: 22),
            ),
          ),
          title: Text(
            exp.description.isEmpty ? exp.category : exp.description,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'by ${exp.createdByName} • $dayStr',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          onTap: () => showExpenseDetail(context, ref, exp),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                fmt.format(exp.amount),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFF87171)),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                onPressed: () {
                  _showDeleteConfirm(context, ref, exp.id);
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text('Are you sure you want to remove this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              ref.read(expenseProvider.notifier).deleteExpense(id);
              Navigator.pop(context);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
