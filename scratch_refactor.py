import re

def process():
    p = r'p:\pro\spendly\lib\features\analytics\providers\analytics_providers.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Add global cache variables
    global_cache = """// Global cache to prevent recomputation on tab switch or irrelevant state changes
AnalyticsState? _cachedAnalyticsState;
int? _cachedInputHash;
"""
    content = content.replace("final analyticsProvider =", global_cache + "\nfinal analyticsProvider =")
    
    # 2. Add hash computation inside _triggerCalculation
    # Let's find _triggerCalculation
    old_trigger_start = """    final input = AnalyticsInput(
      expenses: expenseState.expenses
          .map(
            (e) => ExpenseAnalyticsInput(
              id: e.id,
              amount: e.amount,
              category: e.category,
              description: e.description,
              paymentMethod: e.paymentMethod,
              expenseDate: e.expenseDate,
              createdBy: e.createdBy,
              createdByName: e.createdByName,
            ),
          )
          .toList(),
      budgetLimit: budgetState.currentBudget?.monthlyBudget ?? 20000.0,
      activeMembersCount: familyState.members.isEmpty
          ? 1
          : familyState.members.length,
      filterTypeIndex: filterType.index,
      customRange: customRange,
      memberIdToName: {
        for (var m in familyState.members) m.userId: m.displayName,
      },
      selectedMemberId: selectedMemberId,
      now: DateTime.now(),
      calculationVersion: 1,
    );

    // Compute in background isolate to prevent UI freezing
    final result = await compute(runCalculations, input);"""
    
    new_trigger_start = """    final input = AnalyticsInput(
      expenses: expenseState.expenses
          .map(
            (e) => ExpenseAnalyticsInput(
              id: e.id,
              amount: e.amount,
              category: e.category,
              description: e.description,
              paymentMethod: e.paymentMethod,
              expenseDate: e.expenseDate,
              createdBy: e.createdBy,
              createdByName: e.createdByName,
            ),
          )
          .toList(),
      budgetLimit: budgetState.currentBudget?.monthlyBudget ?? 20000.0,
      activeMembersCount: familyState.members.isEmpty
          ? 1
          : familyState.members.length,
      filterTypeIndex: filterType.index,
      customRange: customRange,
      memberIdToName: {
        for (var m in familyState.members) m.userId: m.displayName,
      },
      selectedMemberId: selectedMemberId,
      now: DateTime.now(),
      calculationVersion: 1, // You could increment this to force cache invalidation
    );

    // Calculate a fast hash of the inputs
    final currentHash = Object.hash(
      input.budgetLimit,
      input.activeMembersCount,
      input.filterTypeIndex,
      input.customRange?.start,
      input.customRange?.end,
      input.selectedMemberId,
      Object.hashAll(expenseState.expenses.map((e) => e.id)),
      Object.hashAll(expenseState.expenses.map((e) => e.amount)), // Catches edits to same ID
    );

    if (_cachedInputHash == currentHash && _cachedAnalyticsState != null) {
      // Return immediately from memory cache without running isolate
      state = _cachedAnalyticsState!;
      return;
    }

    // Compute in background isolate to prevent UI freezing
    final result = await compute(runCalculations, input);"""
    
    content = content.replace(old_trigger_start, new_trigger_start)
    
    # 3. Save to cache after computing
    old_state_update = """    if (mounted) {
      state = AnalyticsState.fromResult(result, state);
    }"""
    
    new_state_update = """    if (mounted) {
      final newState = AnalyticsState.fromResult(result, state);
      _cachedAnalyticsState = newState;
      _cachedInputHash = currentHash;
      state = newState;
    }"""
    
    content = content.replace(old_state_update, new_state_update)

    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
