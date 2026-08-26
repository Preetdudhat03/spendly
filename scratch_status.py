import re

def process():
    p = r'p:\pro\spendly\lib\features\analytics\providers\analytics_providers.dart'
    with open(p, 'r', encoding='utf-8') as f:
        c = f.read()

    # 1. Add enum
    if "enum AnalyticsStatus" not in c:
        c = c.replace("class AnalyticsState {", "enum AnalyticsStatus { initial, loading, success, empty, error }\n\nclass AnalyticsState {")

    # 2. Replace isLoading with status
    c = c.replace("final bool isLoading;", "final AnalyticsStatus status;")
    c = c.replace("required this.isLoading,", "required this.status,")
    
    # 3. AnalyticsState.initial
    c = c.replace("isLoading: false,", "status: AnalyticsStatus.initial,")
    
    # 4. AnalyticsState.copyWith
    c = c.replace("bool? isLoading,", "AnalyticsStatus? status,")
    c = c.replace("isLoading: isLoading ?? this.isLoading,", "status: status ?? this.status,")
    
    # 5. Where it's used in triggerCalculation
    c = c.replace("isLoading: false,", "status: AnalyticsStatus.success,") # Wait, I already replaced isLoading: false with AnalyticsStatus.initial above.
    
    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)

if __name__ == '__main__':
    process()
