import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/widgets/spendly/spendly.dart';
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

    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Suggestions
    final blacklistedKeys = ref.watch(blacklistSuggestionsProvider);
    final suggestions = SuggestionsService.generateSuggestions(expenseState.expenses).where((sug) {
      final key = '${sug.category}|${sug.description}|${sug.amount}';
      return !blacklistedKeys.contains(key);
    }).toList();

    final connection = ref.watch(connectionProvider);
    final spendly = context.spendly;

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
                        ? spendly.colors.success
                        : (connection == ConnectionStatus.sandbox ? Colors.blue : spendly.colors.warning),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  connection == ConnectionStatus.online
                      ? 'Online'
                      : (connection == ConnectionStatus.sandbox ? 'Offline (Sandbox)' : 'Offline (No Connection)'),
                  style: TextStyle(fontSize: 11, color: spendly.colors.neutral400, fontWeight: FontWeight.normal),
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
                            color: spendly.colors.neutral500,
                          ),
                    );

                    Widget summaryRow = Row(
                      children: [
                        Expanded(
                          child: SpendlySummaryCard(
                            title: 'Today\'s Spending',
                            value: currencyFormat.format(todayTotal),
                            badgeBg: spendly.colors.primary.withOpacity(0.12),
                            badgeFg: spendly.colors.primary,
                            icon: Icons.today,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SpendlySummaryCard(
                            title: 'This Month',
                            value: currencyFormat.format(monthTotal),
                            badgeBg: spendly.colors.success.withOpacity(0.12),
                            badgeFg: spendly.colors.success,
                            icon: Icons.calendar_month,
                          ),
                        ),
                      ],
                    );

                    Widget budgetCard = SpendlyCard(
                      child: SpendlyBudgetIndicator(
                        percent: budgetPercent,
                        label: 'Family Budget Progress',
                        trailing: '${currencyFormat.format(monthTotal)} / ${currencyFormat.format(budgetLimit)}',
                      ),
                    );

                    Widget smartSuggestions = suggestions.isEmpty
                        ? const SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SpendlySectionHeader(title: 'Frequently used Expenses'),
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
                                      child: SpendlyCard(
                                        padding: const EdgeInsets.all(12),
                                        headerAction: PopupMenuButton<String>(
                                          icon: Icon(Icons.more_vert, size: 18, color: spendly.colors.neutral500),
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
                                                SpendlyToast.show(context, 'Suggestion deleted.');
                                              }
                                            }
                                          },
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                            const SizedBox(height: 8),
                                            SpendlyButton(
                                              text: 'One Tap Save',
                                              size: SpendlyButtonSize.small,
                                              width: double.infinity,
                                              onPressed: () async {
                                                await ref.read(expenseProvider.notifier).addExpense(
                                                      amount: sug.amount,
                                                      category: sug.category,
                                                      description: sug.description,
                                                      paymentMethod: 'UPI',
                                                      expenseDate: DateTime.now(),
                                                    );
                                                if (context.mounted) {
                                                  SpendlyToast.show(context, 'Logged ${sug.description} ${currencyFormat.format(sug.amount)}!');
                                                }
                                              },
                                            ),
                                          ],
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
                        SpendlySectionHeader(title: 'Quick Add Category'),
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
                        SpendlySectionHeader(
                          title: 'Recent Expenses',
                          trailing: TextButton(
                            onPressed: () => context.push('/expenses'),
                            child: const Text('View All'),
                          ),
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

  Widget _buildQuickAddButton(
    BuildContext context,
    WidgetRef ref,
    String emoji,
    String category,
  ) {
    final spendly = context.spendly;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 80,
      child: SpendlyCard(
        padding: EdgeInsets.zero,
        onTap: () {
          ref.read(selectedCategoryProvider.notifier).state = category;
          context.go('/add');
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: spendly.colors.neutral700),
            )
          ],
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
    final spendly = context.spendly;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: SpendlyCard(
        padding: EdgeInsets.zero,
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
            style: TextStyle(fontSize: 12, color: spendly.colors.neutral400),
          ),
          onTap: () => showExpenseDetail(context, ref, exp),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                fmt.format(exp.amount),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: spendly.colors.error),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: spendly.colors.neutral400),
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
    SpendlyDialog.show(
      context: context,
      title: 'Delete Expense?',
      content: 'Are you sure you want to remove this expense?',
      confirmText: 'DELETE',
      cancelText: 'CANCEL',
      onConfirm: () {
        ref.read(expenseProvider.notifier).deleteExpense(id);
      },
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
