import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/services/suggestions_service.dart';
import 'package:spendly/core/widgets/shimmer_loading.dart';
import 'package:spendly/features/expenses/widgets/budget_overview_card.dart';
import 'package:spendly/features/expenses/widgets/financial_hero.dart';
import 'package:spendly/features/expenses/widgets/frequent_expenses_carousel.dart';
import 'package:spendly/features/expenses/widgets/home_header.dart';
import 'package:spendly/features/expenses/widgets/quick_category_carousel.dart';
import 'package:spendly/features/expenses/widgets/recent_transactions_section.dart';
import 'package:spendly/features/expenses/widgets/spending_metric_card.dart';
import 'package:spendly/main.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final familyState = ref.watch(familyProvider);
    final expenseState = ref.watch(expenseProvider);
    final budgetState = ref.watch(budgetProvider);
    final connection = ref.watch(connectionProvider);

    // Date & Calculations
    final now = DateTime.now();
    final currentUserId = authState.userId;
    final userExpenses = (currentUserId != null && currentUserId.isNotEmpty)
        ? expenseState.expenses.where((e) => e.createdBy == currentUserId)
        : expenseState.expenses;

    // Today's Spending
    final todayExpenses = userExpenses.where((e) {
      return e.expenseDate.year == now.year &&
          e.expenseDate.month == now.month &&
          e.expenseDate.day == now.day;
    });
    final todayTotal = todayExpenses.fold<double>(0, (sum, item) => sum + item.amount);

    // Current Month Spending
    final monthExpenses = userExpenses.where((e) {
      return e.expenseDate.year == now.year && e.expenseDate.month == now.month;
    });
    final monthTotal = monthExpenses.fold<double>(0, (sum, item) => sum + item.amount);

    // Previous Month Spending (for subtle comparison indicator)
    final prevMonthDate = DateTime(now.year, now.month - 1, 1);
    final prevMonthExpenses = userExpenses.where((e) {
      return e.expenseDate.year == prevMonthDate.year &&
          e.expenseDate.month == prevMonthDate.month;
    });
    final prevMonthTotal = prevMonthExpenses.fold<double>(0, (sum, item) => sum + item.amount);

    // Family-wide month total for Family Budget Progress card
    final familyMonthExpenses = expenseState.expenses.where((e) {
      return e.expenseDate.year == now.year && e.expenseDate.month == now.month;
    });
    final familyMonthTotal = familyMonthExpenses.fold<double>(0, (sum, item) => sum + item.amount);

    // Budget Calculations
    final hasBudget = budgetState.currentBudget != null && budgetState.currentBudget!.monthlyBudget > 0;
    final budgetLimit = hasBudget ? budgetState.currentBudget!.monthlyBudget : 20000.0;
    final double budgetPercent = budgetLimit > 0 ? (familyMonthTotal / budgetLimit) : 0.0;

    final double remainingBudget;
    final bool isBudgetExceeded;
    if (hasBudget) {
      final diff = budgetLimit - monthTotal;
      if (diff < 0) {
        remainingBudget = 0.0;
        isBudgetExceeded = true;
      } else {
        remainingBudget = diff;
        isBudgetExceeded = false;
      }
    } else {
      remainingBudget = 0.0;
      isBudgetExceeded = false;
    }

    // Determine budget status color
    Color budgetColor = const Color(0xFF22C55E); // Green (<70%)
    if (budgetPercent > 0.7 && budgetPercent <= 0.9) {
      budgetColor = const Color(0xFFF59E0B); // Amber (70%-90%)
    } else if (budgetPercent > 0.9) {
      budgetColor = const Color(0xFFEF4444); // Red (>90%)
    }

    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Smart Suggestions
    final blacklistedKeys = ref.watch(blacklistSuggestionsProvider);
    final suggestions = SuggestionsService.generateSuggestions(expenseState.expenses).where((sug) {
      final key = '${sug.category}|${sug.description}|${sug.amount}';
      return !blacklistedKeys.contains(key);
    }).toList();

    final displayName = authState.displayName ?? 'Family Member';
    final familyName = familyState.family?.name ?? 'Spendly';

    final topInset = MediaQuery.of(context).padding.top;
    final contentTopPadding = topInset + 58.0; // Space for pinned floating capsule

    return Scaffold(
      body: Stack(
        children: [
          // 1. SCROLLABLE DASHBOARD CONTENT
          expenseState.isLoading || familyState.isLoading
              ? _buildShimmerLoading(contentTopPadding)
              : RefreshIndicator(
                  edgeOffset: contentTopPadding,
                  onRefresh: () async {
                    ref.read(connectionProvider.notifier).checkConnection();
                    await ref.read(syncServiceProvider).syncNow();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(20.0, contentTopPadding, 20.0, 90.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 720;

                        final greetingWidget = HomeGreetingSection(displayName: displayName);

                        final heroWidget = FinancialHero(
                          monthTotal: monthTotal,
                          currencyFormat: currencyFormat,
                          previousMonthTotal: prevMonthTotal > 0 ? prevMonthTotal : null,
                        );

                        final metricsWidget = SpendingMetricCards(
                          todayAmount: currencyFormat.format(todayTotal),
                          remainingAmount: hasBudget ? currencyFormat.format(remainingBudget) : '—',
                          hasBudget: hasBudget,
                          isBudgetExceeded: isBudgetExceeded,
                          budgetLimitFormatted: currencyFormat.format(budgetLimit),
                        );

                        final budgetWidget = BudgetOverviewCard(
                          familySpent: familyMonthTotal,
                          budgetLimit: budgetLimit,
                          budgetPercent: budgetPercent,
                          budgetColor: budgetColor,
                          currencyFormat: currencyFormat,
                        );

                        final suggestionsWidget = FrequentExpensesCarousel(
                          suggestions: suggestions,
                          currencyFormat: currencyFormat,
                        );

                        const quickAddWidget = QuickCategoryCarousel();

                        final recentExpensesWidget = RecentTransactionsSection(
                          expenses: expenseState.expenses,
                          currencyFormat: currencyFormat,
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
                                    const SizedBox(height: 8),
                                    greetingWidget,
                                    const SizedBox(height: 20),
                                    heroWidget,
                                    const SizedBox(height: 16),
                                    metricsWidget,
                                    const SizedBox(height: 24),
                                    budgetWidget,
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    if (suggestions.isNotEmpty) ...[
                                      suggestionsWidget,
                                      const SizedBox(height: 24),
                                    ],
                                    quickAddWidget,
                                    const SizedBox(height: 24),
                                    recentExpensesWidget,
                                  ],
                                ),
                              ),
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            greetingWidget,
                            const SizedBox(height: 20),
                            heroWidget,
                            const SizedBox(height: 16),
                            metricsWidget,
                            const SizedBox(height: 24),
                            budgetWidget,
                            if (suggestions.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              suggestionsWidget,
                            ],
                            const SizedBox(height: 24),
                            quickAddWidget,
                            const SizedBox(height: 24),
                            recentExpensesWidget,
                          ],
                        );
                      },
                    ),
                  ),
                ),

          // 2. PINNED FLOATING FAMILY CAPSULE (Holds position when scrolling, transparent sides)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: true,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Center(
                  child: FamilyHeader(
                    familyName: familyName,
                    connection: connection,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading(double topPadding) {
    return ShimmerLoading(
      isLoading: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.0, topPadding, 20.0, 90.0),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            ShimmerPlaceholder(width: 180, height: 28),
            SizedBox(height: 6),
            ShimmerPlaceholder(width: 120, height: 16),
            SizedBox(height: 24),
            ShimmerPlaceholder(height: 140, borderRadius: 24),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: ShimmerPlaceholder(height: 110, borderRadius: 20)),
                SizedBox(width: 14),
                Expanded(child: ShimmerPlaceholder(height: 110, borderRadius: 20)),
              ],
            ),
            SizedBox(height: 24),
            ShimmerPlaceholder(height: 140, borderRadius: 24),
            SizedBox(height: 24),
            ShimmerPlaceholder(width: 160, height: 22),
            SizedBox(height: 12),
            ShimmerPlaceholder(height: 96, borderRadius: 18),
            SizedBox(height: 24),
            ShimmerPlaceholder(width: 160, height: 22),
            SizedBox(height: 12),
            ShimmerListPlaceholder(itemCount: 4),
          ],
        ),
      ),
    );
  }
}
