enum PasswordStrengthLevel { none, weak, medium, strong }

class PasswordStrengthEvaluation {
  final PasswordStrengthLevel level;
  final String label;
  final double percent;
  final bool isValid;
  final String tip;
  final String? validationError;

  const PasswordStrengthEvaluation({
    required this.level,
    required this.label,
    required this.percent,
    required this.isValid,
    required this.tip,
    this.validationError,
  });
}

class SchemaValidationException implements Exception {
  final String message;
  const SchemaValidationException(this.message);

  @override
  String toString() => message;
}

class SchemaValidator {
  // RFC 5322 Email regex
  static final RegExp _emailRegExp = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$",
  );

  static final RegExp _upperCaseRegExp = RegExp(r'[A-Z]');
  static final RegExp _lowerCaseRegExp = RegExp(r'[a-z]');
  static final RegExp _digitRegExp = RegExp(r'[0-9]');
  // Allow any printable ASCII special character (non-alphanumeric, non-whitespace)
  static final RegExp _specialCharRegExp = RegExp(r'[^A-Za-z0-9\s]');
  static final RegExp _whitespaceRegExp = RegExp(r'\s');

  // Alphanumeric name validation to prevent HTML injection/control chars
  static final RegExp _nameRegExp = RegExp(r"^[a-zA-Z0-9\s\-_']+$");

  // Valid expense categories
  static const Set<String> validCategories = {
    'food',
    'groceries',
    'petrol',
    'fuel',
    'recharges',
    'travel',
    'gas',
    'electricity',
    'utility',
    'medical',
    'insurances',
    'shopping',
    'rent',
    'bills',
    'entertainment',
    'education',
    'college',
    'others'
  };

  // Valid payment methods
  static const Set<String> validPaymentMethods = {
    'upi',
    'card',
    'cash',
    'net banking'
  };

  /// Validate Email structure
  static String validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      throw const SchemaValidationException('Email address cannot be empty.');
    }
    if (email.length > 100) {
      throw const SchemaValidationException('Email address must be 100 characters or less.');
    }
    if (!_emailRegExp.hasMatch(email.trim())) {
      throw const SchemaValidationException('Please enter a valid email address.');
    }
    return email.trim();
  }

  /// Unified password policy evaluation used by both validation and strength UI.
  /// Guarantees that 100% ("Strong") is never reported when validation fails.
  static PasswordStrengthEvaluation evaluatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return const PasswordStrengthEvaluation(
        level: PasswordStrengthLevel.none,
        label: '',
        percent: 0.0,
        isValid: false,
        tip: 'Use at least 8 characters with uppercase, lowercase, number, and symbol.',
        validationError: 'Password cannot be empty.',
      );
    }

    if (password.length > 64) {
      return const PasswordStrengthEvaluation(
        level: PasswordStrengthLevel.weak,
        label: 'Too Long',
        percent: 0.3,
        isValid: false,
        tip: 'Password must be 64 characters or less.',
        validationError: 'Password must be 64 characters or less.',
      );
    }

    if (_whitespaceRegExp.hasMatch(password)) {
      return const PasswordStrengthEvaluation(
        level: PasswordStrengthLevel.weak,
        label: 'Invalid',
        percent: 0.3,
        isValid: false,
        tip: 'Password cannot contain spaces or whitespace.',
        validationError: 'Password cannot contain spaces.',
      );
    }

    final hasMinLength = password.length >= 8;
    final hasUpper = _upperCaseRegExp.hasMatch(password);
    final hasLower = _lowerCaseRegExp.hasMatch(password);
    final hasDigit = _digitRegExp.hasMatch(password);
    final hasSpecial = _specialCharRegExp.hasMatch(password);

    final missing = <String>[];
    if (!hasMinLength) missing.add('at least 8 characters');
    if (!hasUpper) missing.add('an uppercase letter');
    if (!hasLower) missing.add('a lowercase letter');
    if (!hasDigit) missing.add('a number');
    if (!hasSpecial) missing.add('a special character');

    if (missing.isEmpty) {
      return const PasswordStrengthEvaluation(
        level: PasswordStrengthLevel.strong,
        label: 'Strong',
        percent: 1.0,
        isValid: true,
        tip: 'Excellent! Your password meets all security requirements.',
      );
    }

    final metCount = (hasMinLength ? 1 : 0) +
        (hasUpper ? 1 : 0) +
        (hasLower ? 1 : 0) +
        (hasDigit ? 1 : 0) +
        (hasSpecial ? 1 : 0);

    final errorMsg = 'Password must include ${missing.join(', ')}.';

    if (!hasMinLength || metCount <= 2) {
      return PasswordStrengthEvaluation(
        level: PasswordStrengthLevel.weak,
        label: 'Weak',
        percent: 0.3,
        isValid: false,
        tip: 'Add ${missing.join(', ')}.',
        validationError: errorMsg,
      );
    }

    return PasswordStrengthEvaluation(
      level: PasswordStrengthLevel.medium,
      label: 'Medium',
      percent: metCount == 4 ? 0.8 : 0.6,
      isValid: false,
      tip: 'Almost there! Add ${missing.join(', ')}.',
      validationError: errorMsg,
    );
  }

  /// Strict Password validation (For signup & password resets only)
  static String validateStrictPassword(String? password) {
    final evaluation = evaluatePassword(password);
    if (!evaluation.isValid) {
      throw SchemaValidationException(
        evaluation.validationError ?? 'Password does not meet security requirements.',
      );
    }
    return password!;
  }

  /// Basic Password validation (For login only to ensure backward compatibility)
  static String validateBasicPassword(String? password) {
    if (password == null || password.isEmpty) {
      throw const SchemaValidationException('Password cannot be empty.');
    }
    return password;
  }

  /// Validate Display Name / Family Name
  static String validateDisplayName(String? name, {String fieldName = 'Name'}) {
    if (name == null || name.trim().isEmpty) {
      throw SchemaValidationException('$fieldName cannot be empty.');
    }
    final cleanName = name.trim();
    if (cleanName.length < 2 || cleanName.length > 50) {
      throw SchemaValidationException('$fieldName must be between 2 and 50 characters.');
    }
    if (!_nameRegExp.hasMatch(cleanName)) {
      throw SchemaValidationException('$fieldName contains invalid characters. Use letters, numbers, spaces, hyphens, and underscores only.');
    }
    return cleanName;
  }

  /// Validate Expense Inputs
  static double validateExpenseAmount(double? amount) {
    if (amount == null || amount.isNaN || amount.isInfinite) {
      throw const SchemaValidationException('Expense amount must be a valid number.');
    }
    if (amount <= 0.0) {
      throw const SchemaValidationException('Expense amount must be greater than zero.');
    }
    if (amount > 10000000.0) {
      throw const SchemaValidationException('Expense amount cannot exceed ₹10,000,000.');
    }
    return double.parse(amount.toStringAsFixed(2)); // Standardize to 2 decimals
  }

  static String validateExpenseCategory(String? category) {
    if (category == null || category.trim().isEmpty) {
      throw const SchemaValidationException('Category must be selected.');
    }
    final cleanCategory = category.trim().toLowerCase();
    if (!validCategories.contains(cleanCategory)) {
      throw const SchemaValidationException('Selected category is invalid.');
    }
    return category.trim(); // Keep original casing
  }

  static String validateExpenseDescription(String? description) {
    if (description == null) return '';
    final cleanDesc = description.trim();
    if (cleanDesc.length > 200) {
      throw const SchemaValidationException('Description cannot exceed 200 characters.');
    }
    // Reject HTML/Script injections
    if (cleanDesc.contains('<') || cleanDesc.contains('>')) {
      throw const SchemaValidationException('Description contains invalid characters.');
    }
    return cleanDesc;
  }

  static String validatePaymentMethod(String? method) {
    if (method == null || method.trim().isEmpty) {
      throw const SchemaValidationException('Payment method is required.');
    }
    final cleanMethod = method.trim().toLowerCase();
    if (!validPaymentMethods.contains(cleanMethod)) {
      throw const SchemaValidationException('Invalid payment method.');
    }
    return method.trim();
  }

  static DateTime validateExpenseDate(DateTime? date) {
    if (date == null) {
      throw const SchemaValidationException('Expense date is required.');
    }
    final now = DateTime.now();
    // Allow 1 hour future tolerance for timezone buffers
    if (date.isAfter(now.add(const Duration(hours: 1)))) {
      throw const SchemaValidationException('Expense date cannot be in the future.');
    }
    if (date.year < 2020) {
      throw const SchemaValidationException('Expense date must be after January 1, 2020.');
    }
    return date;
  }

  /// Validate Budget Inputs
  static double validateBudgetAmount(double? amount) {
    if (amount == null || amount.isNaN || amount.isInfinite) {
      throw const SchemaValidationException('Budget amount must be a valid number.');
    }
    if (amount < 0.0) {
      throw const SchemaValidationException('Budget amount cannot be negative.');
    }
    if (amount > 10000000.0) {
      throw const SchemaValidationException('Budget amount cannot exceed ₹10,000,000.');
    }
    return double.parse(amount.toStringAsFixed(2));
  }

  static int validateBudgetMonth(int? month) {
    if (month == null || month < 1 || month > 12) {
      throw const SchemaValidationException('Month must be between 1 and 12.');
    }
    return month;
  }

  static int validateBudgetYear(int? year) {
    if (year == null || year < 2020 || year > 2050) {
      throw const SchemaValidationException('Year must be between 2020 and 2050.');
    }
    return year;
  }
}
