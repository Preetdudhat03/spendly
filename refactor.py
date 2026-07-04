import os

path = 'lib/features/expenses/views/all_expenses_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Remove lines 45-308 (which are index 44 to 307) and lines 664 to 900 (index 663 to 899)
new_lines = lines[:44] + lines[308:663]

import_statement = "import 'package:spendly/features/expenses/widgets/expense_detail_modal.dart';\n"
new_lines.insert(6, import_statement)

content = ''.join(new_lines)
content = content.replace('_getCategoryEmoji', 'getCategoryEmoji')
content = content.replace('_getCategoryColor', 'getCategoryColor')
content = content.replace('_showExpenseDetail(exp)', 'showExpenseDetail(context, ref, exp)')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
