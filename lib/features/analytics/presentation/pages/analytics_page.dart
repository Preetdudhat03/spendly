import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/models/expense.dart';

// Import all modular widgets
import '../widgets/analytics_filter.dart';
import '../widgets/summary_card.dart';
import '../widgets/spending_trend_chart.dart';
import '../widgets/spending_heatmap.dart';
import '../widgets/category_donut_chart.dart';
import '../widgets/category_comparison_chart.dart';
import '../widgets/monthly_stacked_chart.dart';
import '../widgets/budget_analysis_card.dart';
import '../widgets/member_leaderboard.dart';
import '../widgets/member_comparison_chart.dart';
import '../widgets/payment_method_chart.dart';
import '../widgets/top_expenses_list.dart';
import '../widgets/spending_calendar.dart';
import '../widgets/spending_patterns_card.dart';
import '../widgets/recurring_expenses_card.dart';
import '../widgets/savings_opportunities_card.dart';
import '../widgets/financial_health_card.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/reports_export_card.dart';
import 'package:spendly/core/widgets/shimmer_loading.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  Future<void> _handleRefresh(WidgetRef ref) async {
    await Future.wait([
      ref.read(expenseProvider.notifier).loadExpenses(),
      ref.read(budgetProvider.notifier).loadBudget(),
      ref.read(familyProvider.notifier).loadMembers(),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsProvider);
    final expenseState = ref.watch(expenseProvider);

    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Financial intelligence',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _handleRefresh(ref),
        color: Theme.of(context).primaryColor,
        child: expenseState.isLoading || state.isLoading
            ? _buildLoadingState(context, isWide)
            : expenseState.expenses.isEmpty || (state.filteredExpenses.isEmpty && ref.read(analyticsMemberFilterProvider) != null)
                ? _buildEmptyState(context, ref)
                : _buildDashboardContent(context, state, expenseState.expenses, isWide),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final selectedMemberId = ref.watch(analyticsMemberFilterProvider);
    final familyState = ref.watch(familyProvider);
    
    String messageTitle = 'No expenses recorded yet';
    String messageBody = 'Log your first family transaction to activate real-time financial intelligence dashboard metrics.';
    
    if (selectedMemberId != null) {
      final memberName = familyState.members.firstWhere(
        (m) => m.userId == selectedMemberId, 
        orElse: () => familyState.members.first
      ).displayName;
      messageTitle = '$memberName has no expenses';
      messageBody = 'No expenses were found for $memberName during this period.';
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.bar_chart_outlined, size: 64, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              messageTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Text(
              messageBody,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            if (selectedMemberId != null)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => ref.read(analyticsMemberFilterProvider.notifier).state = null,
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filter', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => context.go('/add'),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add First Expense', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, bool isWide) {
    return SingleChildScrollView(
      padding: isWide ? const EdgeInsets.symmetric(horizontal: 20, vertical: 10) : const EdgeInsets.fromLTRB(20, 10, 20, 100),//100
      child: ShimmerLoading(
        isLoading: true,
        child: Column(
          children: [
            const ShimmerPlaceholder(height: 60, borderRadius: 16),
            const SizedBox(height: 20),
            Row(
              children: List.generate(
                3,
                (i) => Expanded(
                  child: Container(
                    height: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const ShimmerCardPlaceholder(),
            const SizedBox(height: 20),
            const ShimmerCardPlaceholder(),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, AnalyticsState state, List<Expense> allExpenses, bool isWide) {
    // Wrap items in a FadeIn animation wrapper
    Widget animatedItem(Widget child, int index) {
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 400 + (index * 60)),
        curve: Curves.easeOutCubic,
        builder: (context, val, child) {
          return Opacity(
            opacity: val,
            child: Transform.translate(
              offset: Offset(0, 16 * (1.0 - val)),
              child: child,
            ),
          );
        },
        child: child,
      );
    }

    if (isWide) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            animatedItem(const AnalyticsFilterHeader(), 0),
            const SizedBox(height: 20),
            animatedItem(FinancialSummaryCards(state: state), 1),
            const SizedBox(height: 24),
            
            // Grid layout for tablet/desktop split view
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      animatedItem(SpendingTrendChart(state: state), 2),
                      const SizedBox(height: 20),
                      animatedItem(CategoryDonutChart(state: state), 4),
                      const SizedBox(height: 20),
                      animatedItem(CategoryComparisonChart(state: state), 6),
                      const SizedBox(height: 20),
                      animatedItem(MonthlyStackedChart(state: state), 8),
                      const SizedBox(height: 20),
                      animatedItem(MemberComparisonChart(state: state), 10),
                      const SizedBox(height: 20),
                      animatedItem(PaymentMethodChart(state: state), 12),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right Column
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      animatedItem(FinancialHealthCard(state: state), 3),
                      const SizedBox(height: 20),
                      animatedItem(BudgetAnalysisCard(state: state), 5),
                      const SizedBox(height: 20),
                      animatedItem(FamilyMemberLeaderboard(state: state), 7),
                      const SizedBox(height: 20),
                      animatedItem(TopExpensesList(state: state), 9),
                      const SizedBox(height: 20),
                      animatedItem(SpendingPatternsCard(state: state), 11),
                      const SizedBox(height: 20),
                      animatedItem(SpendingHeatmap(state: state, allExpenses: allExpenses), 13),
                      const SizedBox(height: 20),
                      animatedItem(SpendingCalendar(state: state), 14),
                      const SizedBox(height: 20),
                      animatedItem(RecurringExpensesCard(state: state), 15),
                      const SizedBox(height: 20),
                      animatedItem(SavingsOpportunitiesCard(state: state), 16),
                      const SizedBox(height: 20),
                      animatedItem(AiInsightCard(state: state), 17),
                      const SizedBox(height: 20),
                      animatedItem(ReportsExportCard(state: state), 18),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),//20, 12, 20, 100
        child: Column(
          children: [
            animatedItem(const AnalyticsFilterHeader(), 0),
            const SizedBox(height: 16),
            animatedItem(FinancialSummaryCards(state: state), 1),
            const SizedBox(height: 16),
            animatedItem(FinancialHealthCard(state: state), 2),
            const SizedBox(height: 16),
            animatedItem(BudgetAnalysisCard(state: state), 3),
            const SizedBox(height: 16),
            animatedItem(SpendingTrendChart(state: state), 4),
            const SizedBox(height: 16),
            animatedItem(SpendingHeatmap(state: state, allExpenses: allExpenses), 5),
            const SizedBox(height: 16),
            animatedItem(CategoryDonutChart(state: state), 6),
            const SizedBox(height: 16),
            animatedItem(CategoryComparisonChart(state: state), 7),
            const SizedBox(height: 16),
            animatedItem(MonthlyStackedChart(state: state), 8),
            const SizedBox(height: 16),
            animatedItem(FamilyMemberLeaderboard(state: state), 9),
            const SizedBox(height: 16),
            animatedItem(MemberComparisonChart(state: state), 10),
            const SizedBox(height: 16),
            animatedItem(PaymentMethodChart(state: state), 11),
            const SizedBox(height: 16),
            animatedItem(TopExpensesList(state: state), 12),
            const SizedBox(height: 16),
            animatedItem(SpendingCalendar(state: state), 13),
            const SizedBox(height: 16),
            animatedItem(SpendingPatternsCard(state: state), 14),
            const SizedBox(height: 16),
            animatedItem(RecurringExpensesCard(state: state), 15),
            const SizedBox(height: 16),
            animatedItem(SavingsOpportunitiesCard(state: state), 16),
            const SizedBox(height: 16),
            animatedItem(AiInsightCard(state: state), 17),
            const SizedBox(height: 16),
            animatedItem(ReportsExportCard(state: state), 18),
            const SizedBox(height: 24),
          ],
        ),
      );
    }
  }
}
