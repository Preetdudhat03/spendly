import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/providers/state_providers.dart';

// Provider to hold quick-add categories selected from home screen
final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final prefilledAmountProvider = StateProvider<double?>((ref) => null);
final prefilledDescriptionProvider = StateProvider<String?>((ref) => null);

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedCategory;
  String _paymentMethod = 'UPI';
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, String>> _categoriesList = [
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
    // Use postFrameCallback to read provider state without side effects during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quickCategory = ref.read(selectedCategoryProvider);
      final quickAmount = ref.read(prefilledAmountProvider);
      final quickDesc = ref.read(prefilledDescriptionProvider);

      setState(() {
        if (quickCategory != null) {
          _selectedCategory = quickCategory;
          ref.read(selectedCategoryProvider.notifier).state = null;
        }
        if (quickAmount != null) {
          _amountController.text = quickAmount.toStringAsFixed(0);
          ref.read(prefilledAmountProvider.notifier).state = null;
        }
        if (quickDesc != null) {
          _descriptionController.text = quickDesc;
          ref.read(prefilledDescriptionProvider.notifier).state = null;
        }
      });
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Category!'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount greater than 0.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    final desc = _descriptionController.text.trim();

    await ref.read(expenseProvider.notifier).addExpense(
          amount: amount,
          category: _selectedCategory!,
          description: desc.isEmpty ? _selectedCategory! : desc,
          paymentMethod: _paymentMethod,
          expenseDate: _selectedDate,
        );

    if (!mounted) return;

    // Show success & redirect
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Expense Saved Successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // Clear form
    _amountController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedCategory = null;
      _paymentMethod = 'UPI';
      _selectedDate = DateTime.now();
    });

    // Go back to Home
    context.go('/home');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
      ),
      body: expenseState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: isWide ? 600 : double.infinity),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Amount Field (Large Input)
                    Card(
                      elevation: 0,
                      color: Theme.of(context).primaryColor.withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.15)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Enter Amount',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 15),
                            ),
                            TextFormField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                              decoration: const InputDecoration(
                                hintText: '₹0',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                prefixStyle: TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
                                filled: false,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Enter amount';
                                if (double.tryParse(value) == null) return 'Enter a valid number';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category Header
                    Text(
                      'Select Category',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),

                    // Category Grid Selector
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _categoriesList.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.1,
                      ),
                      itemBuilder: (context, index) {
                        final cat = _categoriesList[index];
                        final isSelected = _selectedCategory == cat['name'];
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat['name'];
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? Theme.of(context).primaryColor : const Color(0xFFE2E8F0),
                                width: 2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  cat['emoji']!,
                                  style: const TextStyle(fontSize: 26),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  cat['name']!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Payment Method Toggle
                    Text(
                      'Payment Method',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: ['UPI', 'Cash', 'Card'].map((method) {
                        final isSelected = _paymentMethod == method;
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.white,
                                foregroundColor: isSelected ? Colors.white : Colors.black87,
                                side: BorderSide(
                                  color: isSelected ? Theme.of(context).primaryColor : const Color(0xFFE2E8F0),
                                  width: 1.5,
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _paymentMethod = method;
                                });
                              },
                              child: Text(
                                method,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Description and Date fields
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (e.g. Dinner, Petrol refuel)',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date Picker Trigger Button
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, color: Colors.grey),
                                SizedBox(width: 12),
                                Text(
                                  'Expense Date',
                                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                                ),
                              ],
                            ),
                            Text(
                              DateFormat('dd MMM yyyy').format(_selectedDate),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                                fontSize: 16,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Giant SAVE EXPENSE button
                    ElevatedButton(
                      onPressed: _saveExpense,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      child: const Text('SAVE EXPENSE'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
                ),
              ),
            ),
          ),
    );
  }
}
