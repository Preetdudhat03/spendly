import re

def process():
    p = r'p:\pro\spendly\lib\features\analytics\models\analytics_models.dart'
    with open(p, 'r', encoding='utf-8') as f:
        c = f.read()

    # Regex to match Map<String, dynamic> toJson() => { ... };
    # and factory ...fromJson(...) => ...;
    
    # We can match `  Map<String, dynamic> toJson() => {` until `  };\n`
    c = re.sub(r'  Map<String, dynamic> toJson\(\) => \{.*?\n  \};\n', '', c, flags=re.DOTALL)
    
    # We can match `  factory <ClassName>.fromJson(...) => <ClassName>(...);`
    c = re.sub(r'  factory \w+\.fromJson\(Map<String, dynamic> json\) => \w+\(.*?\n  \);\n', '', c, flags=re.DOTALL)

    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)

if __name__ == '__main__':
    process()
