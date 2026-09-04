import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/widgets/capsule_top_bar.dart';
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
import '../widgets/spending_velocity_card.dart';
import '../widgets/diagnostic_intelligence_card.dart';
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
    final topInset = MediaQuery.of(context).padding.top;
    final contentTopPadding = topInset + 58.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const CapsuleHeader(
          title: 'Financial Intelligence',
          icon: Icons.insights_rounded,
        ),
      ),
      body: RefreshIndicator(
        edgeOffset: contentTopPadding,
        onRefresh: () => _handleRefresh(ref),
        color: Theme.of(context).primaryColor,
        child: expenseState.isLoading || state.status == AnalyticsStatus.loading
            ? _buildLoadingState(context, isWide, ref, contentTopPadding)
            : !state.hasHistoricalExpenses
                ? _buildEmptyState(context, ref, contentTopPadding)
                : _buildDashboardContent(
                    context,
                    state,
                    expenseState.expenses,
                    isWide,
                    ref,
                    contentTopPadding,
                  ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, double contentTopPadding) {
    const String messageTitle = 'No expenses recorded yet';
    const String messageBody =
        'Log your first family transaction to activate real-time financial intelligence dashboard metrics.';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(28.0, contentTopPadding, 28.0, 28.0),
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
                color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bar_chart_outlined,
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              messageTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              messageBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => context.go('/add'),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text(
                'Add First Expense',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPeriodBanner(
    BuildContext context,
    AnalyticsState state,
    WidgetRef ref,
  ) {
    final selectedMemberId = ref.watch(analyticsMemberFilterProvider);
    final familyState = ref.watch(familyProvider);
    final colorScheme = Theme.of(context).colorScheme;

    String title;
    String body;
    Widget? action;

    if (selectedMemberId != null) {
      String memberName = 'Member';
      try {
        final member = familyState.members.firstWhere(
          (m) => m.userId == selectedMemberId,
        );
        memberName = member.displayName;
      } catch (_) {}

      title = '$memberName has no expenses';
      body =
          '$memberName has no expenses during this period.\nTry another period or clear the filter.';
      action = OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          ref.read(analyticsMemberFilterProvider.notifier).state = null;
        },
        icon: const Icon(Icons.clear, size: 16),
        label: const Text(
          'Clear Filter',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    } else {
      switch (state.filterType) {
        case AnalyticsFilterType.today:
          title = 'No expenses today';
          break;
        case AnalyticsFilterType.thisMonth:
          title = 'No expenses this month';
          break;
        case AnalyticsFilterType.lastMonth:
          title = 'No expenses last month';
          break;
        case AnalyticsFilterType.thisYear:
          title = 'No expenses this year';
          break;
        default:
          title = 'No expenses in this period';
          break;
      }
      body = 'No expenses were recorded during this period.';
      action = ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => context.go('/add'),
        icon: const Icon(Icons.add_circle_outline, size: 16),
        label: const Text(
          'Add Expense',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline,
              size: 24,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 12),
            action,
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingText(BuildContext context, WidgetRef ref) {
    final memberId = ref.watch(analyticsMemberFilterProvider);
    String text = 'Updating analytics...';
    if (memberId != null) {
      final familyState = ref.read(familyProvider);
      try {
        final member = familyState.members.firstWhere(
          (m) => m.userId == memberId,
        );
        text = "Loading ${member.displayName}'s expenses...";
      } catch (e) {
        text = "Loading member expenses...";
      }
    }
    return Center(
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, bool isWide, WidgetRef ref, double contentTopPadding) {
    return SingleChildScrollView(
      padding: isWide
          ? EdgeInsets.fromLTRB(20, contentTopPadding, 20, 10)
          : EdgeInsets.fromLTRB(20, contentTopPadding, 20, 140),
      child: ShimmerLoading(
        isLoading: true,
        child: Column(
          children: [
            _buildLoadingText(context, ref),
            const SizedBox(height: 16),
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

  Widget _buildDashboardContent(
    BuildContext context,
    AnalyticsState state,
    List<Expense> allExpenses,
    bool isWide,
    WidgetRef ref,
    double contentTopPadding,
  ) {
    Widget animatedItem(Widget child, int index) {
      return child;
    }

    if (isWide) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(24, contentTopPadding, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            animatedItem(const AnalyticsFilterHeader(), 0),
            const SizedBox(height: 16),
            if (!state.hasExpensesInCurrentPeriod)
              animatedItem(_buildEmptyPeriodBanner(context, state, ref), 0),
            const SizedBox(height: 4),
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
                      animatedItem(SpendingVelocityCard(state: state), 5),
                      const SizedBox(height: 20),
                      animatedItem(DiagnosticIntelligenceCard(state: state), 5),
                      const SizedBox(height: 20),
                      animatedItem(FamilyMemberLeaderboard(state: state), 7),
                      const SizedBox(height: 20),
                      animatedItem(TopExpensesList(state: state), 9),
                      const SizedBox(height: 20),
                      animatedItem(SpendingPatternsCard(state: state), 11),
                      const SizedBox(height: 20),
                      animatedItem(
                        SpendingHeatmap(state: state, allExpenses: allExpenses),
                        13,
                      ),
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
        padding: EdgeInsets.fromLTRB(20, contentTopPadding, 20, 140),
        child: Column(
          children: [
            animatedItem(const AnalyticsFilterHeader(), 0),
            const SizedBox(height: 12),
            if (!state.hasExpensesInCurrentPeriod)
              animatedItem(_buildEmptyPeriodBanner(context, state, ref), 0),
            const SizedBox(height: 4),
            animatedItem(FinancialSummaryCards(state: state), 1),
            const SizedBox(height: 16),
            animatedItem(FinancialHealthCard(state: state), 2),
            const SizedBox(height: 16),
            animatedItem(BudgetAnalysisCard(state: state), 3),
            const SizedBox(height: 16),
            animatedItem(SpendingVelocityCard(state: state), 3),
            const SizedBox(height: 16),
            animatedItem(DiagnosticIntelligenceCard(state: state), 3),
            const SizedBox(height: 16),
            animatedItem(SpendingTrendChart(state: state), 4),
            const SizedBox(height: 16),
            animatedItem(
              SpendingHeatmap(state: state, allExpenses: allExpenses),
              5,
            ),
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
