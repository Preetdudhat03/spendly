class Expense {
  final String id;
  final String familyId;
  final String createdBy;
  final double amount;
  final String category;
  final String description;
  final String paymentMethod;
  final DateTime expenseDate;
  final DateTime createdAt;
  final String createdByName; // Cached or joined display name for UI contributions

  Expense({
    required this.id,
    required this.familyId,
    required this.createdBy,
    required this.amount,
    required this.category,
    required this.description,
    required this.paymentMethod,
    required this.expenseDate,
    required this.createdAt,
    required this.createdByName,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      createdBy: json['created_by'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      description: json['description'] as String? ?? '',
      paymentMethod: json['payment_method'] as String? ?? 'UPI',
      expenseDate: DateTime.parse(json['expense_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      createdByName: json['created_by_name'] as String? ?? 'Family Member',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'created_by': createdBy,
      'amount': amount,
      'category': category,
      'description': description,
      'payment_method': paymentMethod,
      'expense_date': expenseDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'created_by_name': createdByName,
    };
  }

  Expense copyWith({
    String? id,
    String? familyId,
    String? createdBy,
    double? amount,
    String? category,
    String? description,
    String? paymentMethod,
    DateTime? expenseDate,
    DateTime? createdAt,
    String? createdByName,
  }) {
    return Expense(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      createdBy: createdBy ?? this.createdBy,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      expenseDate: expenseDate ?? this.expenseDate,
      createdAt: createdAt ?? this.createdAt,
      createdByName: createdByName ?? this.createdByName,
    );
  }
}
