import re

def process():
    p = r'p:\pro\spendly\lib\features\analytics\presentation\widgets\member_leaderboard.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()

    # Import InsightDrillDownSheet & AnalyticsModels
    import_models = "import 'package:spendly/features/analytics/models/analytics_models.dart';"
    if import_models not in content:
        content = content.replace("import 'package:spendly/features/analytics/providers/analytics_providers.dart';", "import 'package:spendly/features/analytics/providers/analytics_providers.dart';\n" + import_models)
        
    import_drill = "import 'package:spendly/features/analytics/presentation/widgets/insight_drill_down_sheet.dart';"
    if import_drill not in content:
        content = content.replace("import 'drill_down_sheet.dart';", "import 'drill_down_sheet.dart';\n" + import_drill)
    
    # state.memberShares -> state.diagnostic!.memberInsights
    content = content.replace("if (state.memberShares.isEmpty) {", "if (state.diagnostic?.memberInsights.isEmpty ?? true) {")
    content = content.replace("state.memberShares.fold<double>", "state.diagnostic!.memberInsights.fold<double>")
    content = content.replace("m.totalSpent", "m.currentSpend")
    content = content.replace("state.memberShares.length", "state.diagnostic!.memberInsights.length")
    content = content.replace("state.memberShares[idx]", "state.diagnostic!.memberInsights[idx]")
    
    content = content.replace("member.name", "member.memberName")
    content = content.replace("member.totalSpent", "member.currentSpend")
    content = content.replace("member.count", "member.transactionCount")
    content = content.replace("member.average", "member.averageTransaction")
    content = content.replace("member.favoriteCategory", "member.topCategory")
    
    # Replace DrillDownSheet.show(...)
    old_show = """                      DrillDownSheet.show(
                        context,
                        title: member.memberName,
                        subtitle: 'Member spending details',
                        icon: Icons.person,
                        color: color,
                        totalAmount: member.currentSpend,
                        expenses: memberExpenses,
                        aiSummary:
                            '${member.memberName} has logged ${member.transactionCount} expenses with an average of ${currencyFmt.format(member.averageTransaction)}. Their top category is ${member.topCategory}.',
                      );"""
                      
    new_show = """                      InsightDrillDownSheet.showForMember(
                        context,
                        insight: member,
                      );"""
    
    # Since we use Python regex, we must match the memberExpenses filter too
    old_tap = """                    onTap: () {
                      final memberExpenses =
                          state.filteredExpenses
                              .where((e) => e.createdByName == member.memberName)
                              .toList()
                            ..sort(
                              (a, b) => b.expenseDate.compareTo(a.expenseDate),
                            );

                      DrillDownSheet.show(
                        context,
                        title: member.memberName,
                        subtitle: 'Member spending details',
                        icon: Icons.person,
                        color: color,
                        totalAmount: member.currentSpend,
                        expenses: memberExpenses,
                        aiSummary:
                            '${member.memberName} has logged ${member.transactionCount} expenses with an average of ${currencyFmt.format(member.averageTransaction)}. Their top category is ${member.topCategory}.',
                      );
                    },"""
                    
    new_tap = """                    onTap: () {
                      InsightDrillDownSheet.showForMember(
                        context,
                        insight: member,
                      );
                    },"""
    
    content = content.replace(old_tap, new_tap)
    
    # Replace the text strings that have .largest and .preferredPaymentMethod
    old_text1 = "'${member.transactionCount} Expenses • Avg ${currencyFmt.format(member.averageTransaction)} • Max ${currencyFmt.format(member.largest)}',"
    new_text1 = "'${member.transactionCount} Expenses • Avg ${currencyFmt.format(member.averageTransaction)}',"
    content = content.replace(old_text1, new_text1)
    
    old_text2 = "'Top Category: ${member.topCategory} • Prefers ${member.preferredPaymentMethod}',"
    new_text2 = "'Top Category: ${member.topCategory}',"
    content = content.replace(old_text2, new_text2)
    
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    process()
