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

  // Strict Password: Min 8 chars, 1 upper, 1 lower, 1 digit, 1 special char
  static final RegExp _passwordRegExp = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&.])[A-Za-z\d@$!%*?&.]{8,}$',
  );

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

  /// Strict Password validation (For signup & password resets only)
  static String validateStrictPassword(String? password) {
    if (password == null || password.isEmpty) {
      throw const SchemaValidationException('Password cannot be empty.');
    }
    if (password.length > 64) {
      throw const SchemaValidationException('Password must be 64 characters or less.');
    }
    if (!_passwordRegExp.hasMatch(password)) {
      throw const SchemaValidationException(
        'Password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one digit, and one special character (@\$!%*?&.).',
      );
    }
    return password;
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
