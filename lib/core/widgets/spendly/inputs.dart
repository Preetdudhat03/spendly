import 'package:flutter/material.dart';
import 'package:spendly/core/theme/spendly_tokens.dart';

class SpendlyInputField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final FormFieldValidator<String>? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final bool enabled;

  const SpendlyInputField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  State<SpendlyInputField> createState() => _SpendlyInputFieldState();
}

class _SpendlyInputFieldState extends State<SpendlyInputField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spendly = context.spendly;

    final cardBg = theme.brightness == Brightness.dark
        ? const Color(0xFF111827)
        : Colors.white;

    final borderCol = theme.brightness == Brightness.dark
        ? const Color(0xFF334155)
        : const Color(0xFFE5E7EB);

    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: widget.isPassword && _obscureText,
      validator: widget.validator,
      onChanged: widget.onChanged,
      maxLines: widget.maxLines,
      enabled: widget.enabled,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        color: theme.brightness == Brightness.dark ? Colors.white : spendly.colors.neutral900,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        filled: true,
        fillColor: cardBg,
        contentPadding: EdgeInsets.all(spendly.spacing.x4),
        border: OutlineInputBorder(
          borderRadius: spendly.radius.small,
          borderSide: BorderSide(color: borderCol, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: spendly.radius.small,
          borderSide: BorderSide(color: borderCol, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: spendly.radius.small,
          borderSide: BorderSide(color: spendly.colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: spendly.radius.small,
          borderSide: BorderSide(color: spendly.colors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: spendly.radius.small,
          borderSide: BorderSide(color: spendly.colors.error, width: 2),
        ),
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: spendly.colors.neutral400,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : widget.suffixIcon,
        labelStyle: TextStyle(
          color: spendly.colors.neutral500,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: spendly.colors.neutral400,
        ),
      ),
    );
  }
}

class SpendlyDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final Widget? prefixIcon;

  const SpendlyDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spendly = context.spendly;

    final cardBg = theme.brightness == Brightness.dark
        ? const Color(0xFF111827)
        : Colors.white;

    final borderCol = theme.brightness == Brightness.dark
        ? const Color(0xFF334155)
        : const Color(0xFFE5E7EB);

    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        color: theme.brightness == Brightness.dark ? Colors.white : spendly.colors.neutral900,
      ),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: cardBg,
        contentPadding: EdgeInsets.symmetric(horizontal: spendly.spacing.x4, vertical: spendly.spacing.x4),
        border: OutlineInputBorder(
          borderRadius: spendly.radius.small,
          borderSide: BorderSide(color: borderCol, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: spendly.radius.small,
          borderSide: BorderSide(color: borderCol, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: spendly.radius.small,
          borderSide: BorderSide(color: spendly.colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: spendly.radius.small,
          borderSide: BorderSide(color: spendly.colors.error, width: 1.5),
        ),
        prefixIcon: prefixIcon,
        labelStyle: TextStyle(
          color: spendly.colors.neutral500,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class SpendlyDatePicker extends StatelessWidget {
  final String label;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Widget? prefixIcon;

  const SpendlyDatePicker({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spendly = context.spendly;

    final cardBg = theme.brightness == Brightness.dark
        ? const Color(0xFF111827)
        : Colors.white;

    final borderCol = theme.brightness == Brightness.dark
        ? const Color(0xFF334155)
        : const Color(0xFFE5E7EB);

    final displayString = '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: theme.copyWith(
                colorScheme: theme.colorScheme.copyWith(
                  primary: spendly.colors.primary,
                  onPrimary: Colors.white,
                  surface: theme.brightness == Brightness.dark ? const Color(0xFF111827) : Colors.white,
                  onSurface: theme.brightness == Brightness.dark ? Colors.white : spendly.colors.neutral900,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: cardBg,
          contentPadding: EdgeInsets.symmetric(horizontal: spendly.spacing.x4, vertical: spendly.spacing.x4),
          border: OutlineInputBorder(
            borderRadius: spendly.radius.small,
            borderSide: BorderSide(color: borderCol, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: spendly.radius.small,
            borderSide: BorderSide(color: borderCol, width: 1.5),
          ),
          prefixIcon: prefixIcon ?? Icon(Icons.calendar_today_outlined, size: 20, color: spendly.colors.neutral400),
          labelStyle: TextStyle(
            color: spendly.colors.neutral500,
            fontWeight: FontWeight.w500,
          ),
        ),
        child: Text(
          displayString,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.brightness == Brightness.dark ? Colors.white : spendly.colors.neutral900,
          ),
        ),
      ),
    );
  }
}

class SpendlySearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final VoidCallback? onClear;

  const SpendlySearchBar({
    super.key,
    this.hint = 'Search...',
    this.onChanged,
    this.controller,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spendly = context.spendly;

    final bg = theme.brightness == Brightness.dark
        ? const Color(0xFF111827)
        : Colors.white;

    final borderCol = theme.brightness == Brightness.dark
        ? const Color(0xFF334155)
        : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: spendly.radius.medium,
        border: Border.all(color: borderCol, width: 1),
        boxShadow: spendly.elevation.surface1,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.brightness == Brightness.dark ? Colors.white : spendly.colors.neutral900,
        ),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(Icons.search, color: spendly.colors.neutral400, size: 20),
          suffixIcon: controller != null && controller!.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    controller!.clear();
                    if (onClear != null) onClear!();
                    if (onChanged != null) onChanged!('');
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: spendly.spacing.x3, horizontal: spendly.spacing.x4),
          filled: false,
        ),
      ),
    );
  }
}
