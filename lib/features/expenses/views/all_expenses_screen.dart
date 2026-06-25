import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/models/expense.dart';

class AllExpensesScreen extends ConsumerStatefulWidget {
  const AllExpensesScreen({super.key});

  @override
  ConsumerState<AllExpensesScreen> createState() => _AllExpensesScreenState();
}

class _AllExpensesScreenState extends ConsumerState<AllExpensesScreen> {
  final _searchController = TextEditingController();
  String _selectedFilterCategory = 'All';
  String _searchQuery = '';

  final List<Map<String, String>> _categories = [
    {'name': 'All', 'emoji': '🌐'},
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
    {'name': 'Others', 'emoji': '💰'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getCategoryEmoji(String category) {
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
      default:
        return '💰';
    }
  }

  Color _getCategoryColor(String category) {
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
      default:
        return const Color(0xFF64748B);
    }
  }

  void _showExpenseDetail(Expense expense) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final dateStr = DateFormat('EEEE, MMMM dd, yyyy').format(expense.expenseDate);
        final amtStr = NumberFormat.currency(locale: 'en_IN', decimalDigits: 2, symbol: '₹').format(expense.amount);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
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
                      backgroundColor: _getCategoryColor(expense.category).withOpacity(0.15),
                      child: Text(
                        _getCategoryEmoji(expense.category),
                        style: const TextStyle(fontSize: 28),
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
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditExpenseSheet(expense);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('EDIT'),
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
                          _confirmDeleteExpense(expense.id);
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('DELETE'),
                      ),
                    ),
                  ],
                ),
              ],
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

  void _confirmDeleteExpense(String id) {
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

  void _showEditExpenseSheet(Expense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Expense updated successfully!')),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);

    // Apply filtering & searching
    final filteredExpenses = expenseState.expenses.where((e) {
      final matchesCategory = _selectedFilterCategory == 'All' ||
          e.category.toLowerCase() == _selectedFilterCategory.toLowerCase();
      final matchesSearch = e.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.amount.toString().contains(_searchQuery) ||
          e.createdByName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    // Group expenses by date (formatted as "June 25, 2026")
    final Map<String, List<Expense>> groupedExpenses = {};
    for (var exp in filteredExpenses) {
      final formattedDate = DateFormat('MMMM dd, yyyy').format(exp.expenseDate);
      if (!groupedExpenses.containsKey(formattedDate)) {
        groupedExpenses[formattedDate] = [];
      }
      groupedExpenses[formattedDate]!.add(exp);
    }

    // Sort grouped keys in reverse chronological order
    final groupedKeys = groupedExpenses.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Family Expenses'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search description, member or amount...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          ),

          // Horizontal Category Filter bar
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedFilterCategory == cat['name'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    avatar: Text(cat['emoji'] ?? '💰'),
                    label: Text(cat['name'] ?? ''),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilterCategory = cat['name']!;
                      });
                    },
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).primaryColor,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Loading & List View
          Expanded(
            child: expenseState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredExpenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No expenses found',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            const Text('Try adjusting filters or search query.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: groupedKeys.length,
                        itemBuilder: (context, groupIndex) {
                          final dateKey = groupedKeys[groupIndex];
                          final groupItems = groupedExpenses[dateKey]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sticky-style Date Header
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Text(
                                  _getDateHeaderLabel(dateKey),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),

                              // Card containing the day's expenses list
                              Card(
                                margin: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: groupItems.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
                                  itemBuilder: (context, index) {
                                    final exp = groupItems[index];
                                    final amtStr = NumberFormat.currency(
                                      locale: 'en_IN',
                                      decimalDigits: 0,
                                      symbol: '₹',
                                    ).format(exp.amount);

                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                      leading: CircleAvatar(
                                        radius: 22,
                                        backgroundColor: _getCategoryColor(exp.category).withOpacity(0.12),
                                        child: Text(
                                          _getCategoryEmoji(exp.category),
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                      title: Row(
                                        children: [
                                          Text(
                                            exp.category,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              exp.createdByName,
                                              style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Text(
                                        exp.description.isNotEmpty ? exp.description : 'Logged via ${exp.paymentMethod}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Text(
                                        amtStr,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      onTap: () => _showExpenseDetail(exp),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _getDateHeaderLabel(String formattedDate) {
    final now = DateTime.now();
    final today = DateFormat('MMMM dd, yyyy').format(now);
    final yesterday = DateFormat('MMMM dd, yyyy').format(now.subtract(const Duration(days: 1)));

    if (formattedDate == today) {
      return 'TODAY';
    } else if (formattedDate == yesterday) {
      return 'YESTERDAY';
    }
    return formattedDate.toUpperCase();
  }
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
    final amt = double.tryParse(_amountController.text) ?? 0.0;
    if (amt <= 0) return;

    widget.onSave(
      amt,
      _selectedCategory,
      _descriptionController.text.trim(),
      _paymentMethod,
      _selectedDate,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMMM dd, yyyy').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Expense'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
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
              // Amount field
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
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Enter valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (e.g. Milk, Petrol, Vegetables)',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 24),

              // Category Selector label
              const Text(
                'Select Category',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),

              // Category grid wrap
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

              // Payment Method SegmentedButton
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

              // Date Picker
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
            ],
          ),
        ),
      ),
    );
  }
}
