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
import 'package:spendly/core/theme/spendly_tokens.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final spendlyTheme = context.spendly;
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

                  // Elegant Greeting Header
                  final hour = DateTime.now().hour;
                  String greetingText = '👋 Good Morning';
                  if (hour >= 12 && hour < 17) {
                    greetingText = '👋 Good Afternoon';
                  } else if (hour >= 17) {
                    greetingText = '👋 Good Evening';
                  }

                  Widget welcomeMessage = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greetingText,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: spendlyTheme.colors.neutral500,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authState.displayName ?? "Family Member",
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white
                                  : spendlyTheme.colors.neutral900,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  );

                  Widget summaryRow = Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          'Today\'s Spending',
                          currencyFormat.format(todayTotal),
                          const Icon(Icons.arrow_upward_rounded, size: 14, color: Colors.red),
                          'vs yesterday',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          'This Month',
                          currencyFormat.format(monthTotal),
                          Icon(Icons.calendar_month_rounded, size: 14, color: spendlyTheme.colors.primary),
                          'current cycle',
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
                              'Frequently Used',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 175,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: suggestions.length,
                                itemBuilder: (context, index) {
                                  final sug = suggestions[index];
                                  return Container(
                                    width: 160,
                                    margin: const EdgeInsets.only(right: 16),
                                    child: Card(
                                      color: theme.brightness == Brightness.dark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFF8FAFC),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: spendlyTheme.radius.medium,
                                        side: BorderSide(
                                          color: theme.brightness == Brightness.dark
                                              ? const Color(0x1AFFFFFF)
                                              : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: BoxDecoration(
                                                        color: spendlyTheme.colors.primary.withValues(alpha: 0.1),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Text(
                                                        _getCategoryEmoji(sug.category),
                                                        style: const TextStyle(fontSize: 16),
                                                      ),
                                                    ),
                                                    PopupMenuButton<String>(
                                                      icon: Icon(Icons.more_horiz_rounded, size: 18, color: spendlyTheme.colors.neutral500),
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
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  sug.description.isEmpty ? sug.category : sug.description,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  sug.category,
                                                  style: TextStyle(fontSize: 11, color: spendlyTheme.colors.neutral500),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  currencyFormat.format(sug.amount),
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: spendlyTheme.colors.primary,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.bolt_rounded,
                                                      color: Colors.white,
                                                      size: 14,
                                                    ),
                                                  ),
                                                )
                                              ],
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
                        'Quick Categories',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 90,
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
                              context.push('/expenses');
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
    Widget icon,
    String subtitle,
  ) {
    final spendlyTheme = context.spendly;
    final theme = Theme.of(context);

    return Card(
      color: theme.brightness == Brightness.dark
          ? const Color(0xFF1E293B)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: spendlyTheme.radius.large,
        side: BorderSide(
          color: theme.brightness == Brightness.dark
              ? const Color(0x1AFFFFFF)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: spendlyTheme.colors.neutral500,
                  ),
                ),
                icon,
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: spendlyTheme.colors.neutral400,
              ),
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
    final spendlyTheme = context.spendly;
    final theme = Theme.of(context);
    final cleanPercent = percent.clamp(0.0, 1.0);

    return Card(
      color: theme.brightness == Brightness.dark
          ? const Color(0xFF1E293B)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: spendlyTheme.radius.large,
        side: BorderSide(
          color: theme.brightness == Brightness.dark
              ? const Color(0x1AFFFFFF)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly Budget Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(percent * 100).toStringAsFixed(0)}%',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: cleanPercent,
                minHeight: 10,
                color: color,
                backgroundColor: theme.brightness == Brightness.dark
                    ? const Color(0x1AFFFFFF)
                    : const Color(0xFFF1F5F9),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent: ${fmt.format(spent)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  'Budget: ${fmt.format(limit)}',
                  style: TextStyle(color: spendlyTheme.colors.neutral400, fontSize: 13),
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
    final spendlyTheme = context.spendly;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              ref.read(selectedCategoryProvider.notifier).state = category;
              context.go('/add');
            },
            borderRadius: BorderRadius.circular(30),
            child: Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0x1AFFFFFF)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: spendlyTheme.colors.neutral600,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildExpenseListItem(
    BuildContext context,
    WidgetRef ref,
    Expense exp,
    NumberFormat fmt,
  ) {
    final spendlyTheme = context.spendly;
    final theme = Theme.of(context);
    final dayStr = DateFormat('dd MMM').format(exp.expenseDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: spendlyTheme.radius.medium,
          side: BorderSide(
            color: theme.brightness == Brightness.dark
                ? const Color(0x1AFFFFFF)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: spendlyTheme.colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getCategoryEmoji(exp.category),
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          title: Text(
            exp.description.isEmpty ? exp.category : exp.description,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Text(
            'by ${exp.createdByName} • $dayStr',
            style: TextStyle(fontSize: 11, color: spendlyTheme.colors.neutral400),
          ),
          onTap: () => showExpenseDetail(context, ref, exp),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '-${fmt.format(exp.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: spendlyTheme.colors.expense,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, size: 20, color: spendlyTheme.colors.neutral400),
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
