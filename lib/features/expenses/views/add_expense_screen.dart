import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/utils/schema_validator.dart';
import 'package:spendly/core/widgets/spendly/spendly.dart';

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
    {'name': 'College', 'emoji': '🎓'},
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

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    final amountVal = double.tryParse(_amountController.text);
    final desc = _descriptionController.text.trim();
    final double amount;

    try {
      amount = SchemaValidator.validateExpenseAmount(amountVal);
      SchemaValidator.validateExpenseCategory(_selectedCategory);
      SchemaValidator.validateExpenseDescription(desc);
      SchemaValidator.validatePaymentMethod(_paymentMethod);
      SchemaValidator.validateExpenseDate(_selectedDate);
    } catch (e) {
      SpendlySnackbar.show(
        context: context,
        message: e.toString(),
        isError: true,
      );
      return;
    }

    final success = await ref.read(expenseProvider.notifier).addExpense(
          amount: amount,
          category: _selectedCategory!,
          description: desc.isEmpty ? _selectedCategory! : desc,
          paymentMethod: _paymentMethod,
          expenseDate: _selectedDate,
        );

    if (!mounted) return;

    if (!success) {
      SpendlySnackbar.show(
        context: context,
        message: ref.read(expenseProvider).error ?? 'Failed to save expense',
        isError: true,
      );
      return;
    }

    // Show success & redirect
    SpendlySnackbar.show(
      context: context,
      message: 'Expense Saved Successfully!',
    );

    // Clear form
    _amountController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedCategory = null;
      _paymentMethod = 'UPI';
      _selectedDate = DateTime.now();
    });
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
    final spendly = context.spendly;
    final theme = Theme.of(context);

    final paymentMethods = ['UPI', 'Cash', 'Card'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
      ),
      body: Center(
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
                  SpendlyCard(
                    backgroundColor: theme.brightness == Brightness.dark
                        ? const Color(0xFF1E293B)
                        : spendly.colors.primary.withOpacity(0.05),
                    child: Column(
                      children: [
                        Text(
                          'Enter Amount',
                          style: TextStyle(fontWeight: FontWeight.w600, color: spendly.colors.neutral500, fontSize: 15),
                        ),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: spendly.colors.primary,
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
                            final val = double.tryParse(value);
                            try {
                              SchemaValidator.validateExpenseAmount(val);
                              return null;
                            } catch (e) {
                              return e.toString();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Category Header
                  SpendlySectionHeader(title: 'Select Category'),
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
                      return SpendlyCard(
                        padding: EdgeInsets.zero,
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat['name'];
                          });
                        },
                        backgroundColor: isSelected
                            ? spendly.colors.primary
                            : (theme.brightness == Brightness.dark ? const Color(0xFF111827) : Colors.white),
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
                                color: isSelected
                                    ? Colors.white
                                    : (theme.brightness == Brightness.dark ? Colors.white70 : spendly.colors.neutral900),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Payment Method Toggle
                  SpendlySectionHeader(title: 'Payment Method'),
                  const SizedBox(height: 12),
                  SpendlySegmentedControl(
                    segments: paymentMethods,
                    selectedIndex: paymentMethods.indexOf(_paymentMethod),
                    onValueChanged: (index) {
                      setState(() {
                        _paymentMethod = paymentMethods[index];
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Description and Date fields
                  SpendlyInputField(
                    controller: _descriptionController,
                    label: 'Description (e.g. Dinner, Petrol refuel)',
                    prefixIcon: Icon(Icons.description_outlined, color: spendly.colors.neutral400),
                  ),
                  const SizedBox(height: 16),

                  // Date Picker Trigger
                  SpendlyDatePicker(
                    label: 'Expense Date',
                    selectedDate: _selectedDate,
                    onDateSelected: (date) {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                  ),
                  const SizedBox(height: 36),

                  // Giant SAVE EXPENSE button
                  SpendlyButton(
                    text: 'SAVE EXPENSE',
                    variant: SpendlyButtonVariant.primary,
                    size: SpendlyButtonSize.large,
                    isLoading: expenseState.isLoading,
                    onPressed: _saveExpense,
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
