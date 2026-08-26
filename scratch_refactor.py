import re

def process():
    # 1. Fix category_comparison_chart
    p1 = r'p:\pro\spendly\lib\features\analytics\presentation\widgets\category_comparison_chart.dart'
    with open(p1, 'r', encoding='utf-8') as f:
        c1 = f.read()
    
    # In my previous script, I replaced `return Padding(\n...` with `return InkWell(\n...child: Padding(\n...`
    # This means the closing tag is `);` which now only closes the Padding. We need `);` to close the InkWell too.
    # The end of the builder looks like this:
    #                   ),
    #                 );
    #               },
    
    c1 = c1.replace("""                    ],
                  ),
                );
              },""", """                    ],
                  ),
                ));
              },""")
              
    with open(p1, 'w', encoding='utf-8') as f:
        f.write(c1)
        
    # 2. Fix insight_drill_down_sheet.dart
    p2 = r'p:\pro\spendly\lib\features\analytics\presentation\widgets\insight_drill_down_sheet.dart'
    with open(p2, 'r', encoding='utf-8') as f:
        c2 = f.read()
        
    c2 = c2.replace("TrendDirection.neutral", "TrendDirection.stable")
    
    with open(p2, 'w', encoding='utf-8') as f:
        f.write(c2)

if __name__ == '__main__':
    process()
