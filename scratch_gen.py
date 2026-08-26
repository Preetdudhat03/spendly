import re

def generate_serialization():
    code = """
  Map<String, dynamic> toJson() {
    return {
      'currentValue': currentValue,
      'previousValue': previousValue,
      'absoluteChange': absoluteChange,
      'percentageChange': percentageChange,
      'direction': direction.index,
    };
  }

  factory PeriodComparison.fromJson(Map<String, dynamic> json) {
    return PeriodComparison(
      currentValue: json['currentValue'] ?? 0.0,
      previousValue: json['previousValue'] ?? 0.0,
      absoluteChange: json['absoluteChange'] ?? 0.0,
      percentageChange: json['percentageChange'] ?? 0.0,
      direction: TrendDirection.values[json['direction'] ?? 0],
    );
  }
"""
    print("Code generation script")

if __name__ == '__main__':
    generate_serialization()
