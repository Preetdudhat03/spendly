import re

def process():
    p = r'p:\pro\spendly\lib\features\analytics\providers\analytics_providers.dart'
    with open(p, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    for i in range(len(lines)):
        if "status: filteredExps.isEmpty ? AnalyticsStatus.empty : AnalyticsStatus.success," in lines[i] or "status: AnalyticsStatus.initial," in lines[i]:
            if i < 300: # inside AnalyticsState.initial
                lines[i] = "      status: AnalyticsStatus.initial,\n"
            else: # inside fromResult
                lines[i] = "      status: filteredExps.isEmpty ? AnalyticsStatus.empty : AnalyticsStatus.success,\n"
                
    with open(p, 'w', encoding='utf-8') as f:
        f.writelines(lines)

if __name__ == '__main__':
    process()
