import 'package:spendly/models/expense.dart';

class ExpenseSuggestion {
  final String category;
  final double amount;
  final String description;
  final int frequency;

  ExpenseSuggestion({
    required this.category,
    required this.amount,
    required this.description,
    required this.frequency,
  });
}

class SuggestionsService {
  /// Analyzes past expenses to find recurring patterns
  static List<ExpenseSuggestion> generateSuggestions(List<Expense> expenses) {
    if (expenses.isEmpty) return [];

    // Map of "category|description|amount" -> count
    final Map<String, int> frequencies = {};
    
    for (var exp in expenses) {
      // Normalize description
      final desc = exp.description.trim().toLowerCase();
      // Skip empty or very generic descriptions
      if (desc.isEmpty) continue;
      
      final key = '${exp.category}|${exp.description}|${exp.amount}';
      frequencies[key] = (frequencies[key] ?? 0) + 1;
    }

    final List<ExpenseSuggestion> suggestions = [];
    
    frequencies.forEach((key, freq) {
      // If an expense appears 2 or more times, suggest it
      if (freq >= 2) {
        final parts = key.split('|');
        suggestions.add(ExpenseSuggestion(
          category: parts[0],
          description: parts[1],
          amount: double.tryParse(parts[2]) ?? 0.0,
          frequency: freq,
        ));
      }
    });

    // Sort by frequency (highest first)
    suggestions.sort((a, b) => b.frequency.compareTo(a.frequency));
    
    // Limit to top 3 suggestions to keep UI clean
    return suggestions.take(3).toList();
  }
}
