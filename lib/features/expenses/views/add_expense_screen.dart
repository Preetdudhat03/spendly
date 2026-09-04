import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/utils/schema_validator.dart';
import 'package:spendly/features/expenses/widgets/expense_detail_modal.dart';

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

  final List<Map<String, dynamic>> _categoriesList = [
    {'name': 'Food', 'iconPath': 'assets/category/food.svg'},
    {'name': 'Groceries', 'iconPath': 'assets/category/groceries.svg'},
    {'name': 'Petrol', 'iconPath': 'assets/category/fuel.svg'},
    {'name': 'Recharges', 'iconPath': 'assets/category/recharge.svg'},
    {'name': 'Travel', 'iconPath': 'assets/category/travel.svg'},
    {'name': 'Gas', 'iconPath': 'assets/category/gas.svg'},
    {'name': 'Electricity', 'iconPath': 'assets/category/electricity.svg'},
    {'name': 'Medical', 'iconPath': 'assets/category/medical.svg'},
    {'name': 'Insurances', 'iconPath': 'assets/category/insurances.svg'},
    {'name': 'Rent', 'iconPath': 'assets/category/rent.svg'},
    {'name': 'Shopping', 'iconPath': 'assets/category/shopping.svg'},
    {'name': 'Entertainment', 'iconPath': 'assets/category/entertainment.svg'},
    {'name': 'Education', 'iconPath': 'assets/category/education.svg'},
    {'name': 'College', 'iconPath': 'assets/category/college.svg'},
    {'name': 'Others', 'iconPath': 'assets/category/others.svg'},
  ];

  @override
  void initState() {
    super.initState();
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
              primary: Theme.of(context).colorScheme.primary,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.amber[800],
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(expenseProvider).error ?? 'Failed to save expense'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Show success & clear
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Expense logged successfully!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF22C55E),
      ),
    );

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'Add Expense',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isWide ? 600 : double.infinity),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, isWide ? 20.0 : 100.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. AMOUNT INPUT HERO CARD
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.surface.withValues(alpha: 0.7)
                          : colorScheme.primary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? colorScheme.outline.withValues(alpha: 0.4)
                            : colorScheme.primary.withValues(alpha: 0.12),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.2)
                              : colorScheme.shadow.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'ENTER AMOUNT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                            letterSpacing: -1.5,
                          ),
                          decoration: InputDecoration(
                            hintText: '₹0',
                            hintStyle: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                              letterSpacing: -1.5,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter an amount';
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
                  const SizedBox(height: 24),

                  // 2. CATEGORY SELECTOR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (_selectedCategory != null)
                        Text(
                          _selectedCategory!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _categoriesList.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.15,
                    ),
                    itemBuilder: (context, index) {
                      final cat = _categoriesList[index];
                      final name = cat['name'] as String;
                      final isSelected = _selectedCategory == name;
                      final catColor = getCategoryColor(name);

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategory = name;
                            });
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? colorScheme.primaryContainer : colorScheme.primary.withValues(alpha: 0.12))
                                  : (theme.cardTheme.color ?? colorScheme.surface),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : (isDark
                                        ? colorScheme.outline.withValues(alpha: 0.4)
                                        : colorScheme.outline.withValues(alpha: 0.8)),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: colorScheme.primary.withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      )
                                    ]
                                  : [
                                      BoxShadow(
                                        color: isDark
                                            ? Colors.black.withValues(alpha: 0.15)
                                            : colorScheme.shadow.withValues(alpha: 0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: catColor.withValues(alpha: isSelected ? 0.22 : 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: SvgPicture.asset(
                                    cat['iconPath']!,
                                    colorFilter: ColorFilter.mode(
                                      isSelected ? colorScheme.primary : catColor,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // 3. PAYMENT METHOD SELECTOR
                  Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: ['UPI', 'Cash', 'Card'].map((method) {
                      final isSelected = _paymentMethod == method;
                      IconData methodIcon;
                      if (method == 'UPI') {
                        methodIcon = Icons.phone_android_rounded;
                      } else if (method == 'Cash') {
                        methodIcon = Icons.payments_outlined;
                      } else {
                        methodIcon = Icons.credit_card_outlined;
                      }

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: method != 'Card' ? 8.0 : 0,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _paymentMethod = method;
                                });
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark ? colorScheme.primaryContainer : colorScheme.primary.withValues(alpha: 0.12))
                                      : (theme.cardTheme.color ?? colorScheme.surface),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : (isDark
                                            ? colorScheme.outline.withValues(alpha: 0.4)
                                            : colorScheme.outline.withValues(alpha: 0.8)),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      methodIcon,
                                      size: 18,
                                      color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      method,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // 4. DESCRIPTION FIELD
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional note)',
                      hintText: 'e.g. Dinner, Fuel refill',
                      prefixIcon: const Icon(Icons.edit_note_rounded),
                      filled: true,
                      fillColor: theme.cardTheme.color ?? colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark
                              ? colorScheme.outline.withValues(alpha: 0.4)
                              : colorScheme.outline.withValues(alpha: 0.8),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark
                              ? colorScheme.outline.withValues(alpha: 0.4)
                              : colorScheme.outline.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 5. DATE PICKER
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color ?? colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? colorScheme.outline.withValues(alpha: 0.4)
                                : colorScheme.outline.withValues(alpha: 0.8),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Expense Date',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                DateFormat('dd MMM yyyy').format(_selectedDate),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 6. SAVE EXPENSE BUTTON
                  ElevatedButton(
                    onPressed: expenseState.isLoading ? null : _saveExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: expenseState.isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'SAVE EXPENSE',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
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
