import re

def process():
    p = r'p:\pro\spendly\lib\features\analytics\presentation\pages\analytics_page.dart'
    with open(p, 'r', encoding='utf-8') as f:
        c = f.read()

    # 1. Update the ternary logic
    old_logic = """        child: expenseState.isLoading || state.isLoading
            ? _buildLoadingState(context, isWide)
            : expenseState.expenses.isEmpty ||
                  (state.filteredExpenses.isEmpty &&
                      ref.read(analyticsMemberFilterProvider) != null)
            ? _buildEmptyState(context, ref)"""
            
    new_logic = """        child: expenseState.isLoading || state.status == AnalyticsStatus.loading
            ? _buildLoadingState(context, isWide, ref)
            : expenseState.expenses.isEmpty || state.status == AnalyticsStatus.empty
            ? _buildEmptyState(context, ref)"""
            
    c = c.replace(old_logic, new_logic)

    # 2. Update _buildLoadingState signature
    c = c.replace("Widget _buildLoadingState(BuildContext context, bool isWide) {", "Widget _buildLoadingState(BuildContext context, bool isWide, WidgetRef ref) {")

    # 3. Add loading text to _buildLoadingState
    old_loading_col = """        child: Column(
          children: [
            const ShimmerPlaceholder(height: 60, borderRadius: 16),"""
            
    new_loading_col = """        child: Column(
          children: [
            _buildLoadingText(context, ref),
            const SizedBox(height: 16),
            const ShimmerPlaceholder(height: 60, borderRadius: 16),"""
            
    c = c.replace(old_loading_col, new_loading_col)
    
    # 4. Add _buildLoadingText function
    helper = """  Widget _buildLoadingText(BuildContext context, WidgetRef ref) {
    final memberId = ref.watch(analyticsMemberFilterProvider);
    String text = 'Updating analytics...';
    if (memberId != null) {
      final familyState = ref.read(familyProvider);
      try {
        final member = familyState.members.firstWhere((m) => m.userId == memberId);
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
  }"""
  
    c = c.replace("Widget _buildLoadingState(BuildContext context, bool isWide, WidgetRef ref) {", helper + "\n\n  Widget _buildLoadingState(BuildContext context, bool isWide, WidgetRef ref) {")

    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)

if __name__ == '__main__':
    process()
