class Budget {
  final String id;
  final String familyId;
  final double monthlyBudget;
  final int month;
  final int year;

  Budget({
    required this.id,
    required this.familyId,
    required this.monthlyBudget,
    required this.month,
    required this.year,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      monthlyBudget: (json['monthly_budget'] as num).toDouble(),
      month: json['month'] as int,
      year: json['year'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'monthly_budget': monthlyBudget,
      'month': month,
      'year': year,
    };
  }

  Budget copyWith({
    String? id,
    String? familyId,
    double? monthlyBudget,
    int? month,
    int? year,
  }) {
    return Budget(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Budget &&
        other.id == id &&
        other.familyId == familyId &&
        other.monthlyBudget == monthlyBudget &&
        other.month == month &&
        other.year == year;
  }

  @override
  int get hashCode => Object.hash(id, familyId, monthlyBudget, month, year);
}
