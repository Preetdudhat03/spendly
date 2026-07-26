import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/utils/schema_validator.dart';
import 'package:spendly/models/expense.dart';
import 'package:flutter_svg/flutter_svg.dart';

String getCategoryIconPath(String category) {
  switch (category.toLowerCase()) {
    case 'food':
      return 'assets/category/food.svg';
    case 'groceries':
      return 'assets/category/groceries.svg';
    case 'petrol':
    case 'fuel':
      return 'assets/category/petrol.svg';
    case 'recharges':
      return 'assets/category/recharge.svg';
    case 'travel':
      return 'assets/category/travel.svg';
    case 'gas':
      return 'assets/category/gas.svg';
    case 'electricity':
    case 'utility':
      return 'assets/category/electricity.svg';
    case 'medical':
      return 'assets/category/medical.svg';
    case 'insurances':
      return 'assets/category/insurances.svg';
    case 'shopping':
      return 'assets/category/shopping.svg';
    case 'rent':
      return 'assets/category/rent.svg';
    case 'entertainment':
      return 'assets/category/entertainment.svg';
    case 'education':
      return 'assets/category/education.svg';
    case 'college':
    case 'collage':
      return 'assets/category/college.svg';
    default:
      return 'assets/category/others.svg';
  }
}
/*String getCategoryEmoji(String category) {
  switch (category.toLowerCase()) {
    case 'food':
      return '🍔';
    case 'groceries':
      return '🛒';
    case 'petrol':
    case 'fuel':
      return '🚗';
    case 'recharges':
      return '📱';
    case 'travel':
      return '✈️';
    case 'gas':
      return '⛽';
    case 'electricity':
    case 'utility':
      return '⚡';
    case 'medical':
      return '💊';
    case 'insurances':
      return '🛡️';
    case 'shopping':
      return '🛍️';
    case 'rent':
      return '🏠';
    case 'entertainment':
      return '🎬';
    case 'education':
      return '📚';
    case 'college':
    case 'collage':
      return '🎓';
    default:
      return '💰';
  }
}*/

Color getCategoryColor(String category) {
  switch (category.toLowerCase()) {
    case 'food':
      return const Color(0xFFF59E0B);
    case 'groceries':
      return const Color(0xFF10B981);
    case 'petrol':
    case 'fuel':
      return const Color(0xFF3B82F6);
    case 'recharges':
      return const Color(0xFF06B6D4);
    case 'travel':
      return const Color(0xFF14B8A6);
    case 'gas':
      return const Color(0xFFF97316);
    case 'electricity':
    case 'utility':
      return const Color(0xFF8B5CF6);
    case 'medical':
      return const Color(0xFFEF4444);
    case 'insurances':
      return const Color(0xFF4F46E5);
    case 'shopping':
      return const Color(0xFFEC4899);
    case 'rent':
      return const Color(0xFF78350F);
    case 'entertainment':
      return const Color(0xFFF43F5E);
    case 'education':
      return const Color(0xFF636AE8);
    case 'college':
    case 'collage':
      return const Color(0xFF312E81);
    default:
      return const Color(0xFF64748B);
  }
}

void showExpenseDetail(BuildContext context, WidgetRef ref, Expense expense) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final dateStr = DateFormat('EEEE, MMMM dd, yyyy').format(expense.expenseDate);
      final amtStr = NumberFormat.currency(locale: 'en_IN', decimalDigits: 2, symbol: '₹').format(expense.amount);

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: getCategoryColor(expense.category).withOpacity(0.15),
                    /*child: Text(
                      getCategoryEmoji(expense.category),
                      style: const TextStyle(fontSize: 28),
                    ),*/
                    child: SvgPicture.asset(
                      getCategoryIconPath(expense.category),
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(getCategoryColor(expense.category), BlendMode.srcIn),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.category,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          expense.description.isNotEmpty ? expense.description : 'No description',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    amtStr,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const Divider(height: 36),
              _buildDetailRow(Icons.calendar_today_outlined, 'Logged Date', dateStr),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.payment_outlined, 'Payment Method', expense.paymentMethod),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.person_outline, 'Logged By', expense.createdByName),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        foregroundColor: Theme.of(context).primaryColor,
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditExpenseSheet(context, ref, expense);
                      },
                      icon: const Icon(Icons.edit),
                      label: const FittedBox(fit: BoxFit.scaleDown, child: Text('EDIT')),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red,
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDeleteExpense(context, ref, expense.id);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const FittedBox(fit: BoxFit.scaleDown, child: Text('DELETE')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 70), // Padding to account for the floating navigation bar 80
            ],
          ),
          ),
        ),
      );
    },
  );
}

Widget _buildDetailRow(IconData icon, String label, String value) {
  return Row(
    children: [
      Icon(icon, color: Colors.grey[600], size: 20),
      const SizedBox(width: 12),
      Text(
        '$label:',
        style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
      ),
    ],
  );
}

void _confirmDeleteExpense(BuildContext context, WidgetRef ref, String id) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Expense?'),
      content: const Text('Are you sure you want to delete this expense? This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            ref.read(expenseProvider.notifier).deleteExpense(id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Expense deleted successfully!')),
            );
          },
          child: const Text('DELETE', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

void _showEditExpenseSheet(BuildContext context, WidgetRef ref, Expense expense) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return _EditExpenseForm(
        expense: expense,
        onSave: (amt, cat, desc, pay, date) async {
          await ref.read(expenseProvider.notifier).updateExpense(
                id: expense.id,
                amount: amt,
                category: cat,
                description: desc,
                paymentMethod: pay,
                expenseDate: date,
              );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Expense updated successfully!')),
            );
          }
        },
      );
    },
  );
}

class _EditExpenseForm extends StatefulWidget {
  final Expense expense;
  final Function(double, String, String, String, DateTime) onSave;

  const _EditExpenseForm({required this.expense, required this.onSave});

  @override
  State<_EditExpenseForm> createState() => _EditExpenseFormState();
}

class _EditExpenseFormState extends State<_EditExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late String _selectedCategory;
  late String _paymentMethod;
  late DateTime _selectedDate;

  final List<Map<String, String>> _categories = [
    {'name': 'Food', 'emoji': '🍔'},
    {'name': 'Groceries', 'emoji': '🛒'},
    {'name': 'Petrol', 'emoji': '🚗'},
    {'name': 'Recharges', 'emoji': '📱'},
    {'name': 'Travel', 'emoji': '✈️'},
    {'name': 'Gas', 'emoji': '⛽'},
    {'name': 'Electricity', 'emoji': '⚡'},
    {'name': 'Medical', 'emoji': '💊'},
    {'name': 'Insurances', 'emoji': '🛡️'},
    {'name': 'Rent', 'emoji': '🏠'},
    {'name': 'Shopping', 'emoji': '🛍️'},
    {'name': 'Entertainment', 'emoji': '🎬'},
    {'name': 'Education', 'emoji': '📚'},
    {'name': 'College', 'emoji': '🎓'},
    {'name': 'Others', 'emoji': '💰'},
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.expense.amount.toStringAsFixed(0));
    _descriptionController = TextEditingController(text: widget.expense.description);
    _selectedCategory = widget.expense.category;
    _paymentMethod = widget.expense.paymentMethod;
    _selectedDate = widget.expense.expenseDate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amt = double.tryParse(_amountController.text);
    final desc = _descriptionController.text.trim();

    try {
      SchemaValidator.validateExpenseAmount(amt);
      SchemaValidator.validateExpenseCategory(_selectedCategory);
      SchemaValidator.validateExpenseDescription(desc);
      SchemaValidator.validatePaymentMethod(_paymentMethod);
      SchemaValidator.validateExpenseDate(_selectedDate);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    widget.onSave(
      amt!,
      _selectedCategory,
      desc,
      _paymentMethod,
      _selectedDate,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMMM dd, yyyy').format(_selectedDate);
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Expense'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isWide ? 600 : double.infinity),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 28.0,
              right: 28.0,
              top: 20.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 28.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      prefixText: '₹ ',
                      labelText: 'Amount spent',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Enter amount';
                      final val = double.tryParse(value);
                      try {
                        SchemaValidator.validateExpenseAmount(val);
                        return null;
                      } catch (e) {
                        return e.toString();
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (e.g. Milk, Petrol, Vegetables)',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Select Category',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory.toLowerCase() == cat['name']!.toLowerCase();
                      return ChoiceChip(
                        avatar: Text(cat['emoji']!),
                        label: Text(cat['name']!),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = cat['name']!;
                            });
                          }
                        },
                        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                        checkmarkColor: Theme.of(context).primaryColor,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Payment Method',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'UPI', label: Text('UPI'), icon: Icon(Icons.mobile_friendly)),
                      ButtonSegment(value: 'Cash', label: Text('Cash'), icon: Icon(Icons.money)),
                      ButtonSegment(value: 'Card', label: Text('Card'), icon: Icon(Icons.credit_card)),
                    ],
                    selected: {_paymentMethod},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _paymentMethod = selection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Expense Date: $dateStr',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('SAVE CHANGES'),
                  ),
                  const SizedBox(height: 80),
                ],
                
              ),
            ),
            
          ),
        ),
        
      ),
    );  
  }
}
