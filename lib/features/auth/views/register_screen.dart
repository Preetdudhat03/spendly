import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/utils/crypto_utils.dart';
import 'package:spendly/core/utils/schema_validator.dart';
import 'package:spendly/core/widgets/spendly/spendly.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String? initialEmail;
  const RegisterScreen({super.key, this.initialEmail});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final success = await ref.read(authProvider.notifier).signUp(email, password, name);

    if (!mounted) return;

    if (success) {
      final stateMsg = ref.read(authProvider).error ?? 'Check your email for confirmation!';
      final spendly = context.spendly;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111827) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: spendly.radius.large),
          title: const Text('Confirm Email', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(stateMsg),
          actions: [
            SpendlyButton(
              text: 'OK',
              size: SpendlyButtonSize.small,
              onPressed: () {
                Navigator.pop(context); // Close dialog
                context.go('/login'); // Return to login
              },
            ),
          ],
        ),
      );
    } else {
      final error = ref.read(authProvider).error ?? 'Registration failed';
      SpendlySnackbar.show(
        context: context,
        message: error,
        isError: true,
      );
    }
  }

  String _checkPasswordStrength(String password) {
    if (password.isEmpty) return '';
    if (password.length < 6) return 'Weak';
    
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    
    if (password.length >= 8 && hasUppercase && hasDigits && hasSpecialCharacters) {
      return 'Strong';
    }
    if (password.length >= 6 && (hasDigits || hasSpecialCharacters)) {
      return 'Medium';
    }
    return 'Weak';
  }

  Color _getStrengthColor(String strength, SpendlyThemeData spendly) {
    switch (strength) {
      case 'Strong':
        return spendly.colors.success;
      case 'Medium':
        return spendly.colors.warning;
      case 'Weak':
      default:
        return spendly.colors.error;
    }
  }

  double _getStrengthPercent(String strength) {
    switch (strength) {
      case 'Strong':
        return 1.0;
      case 'Medium':
        return 0.6;
      case 'Weak':
      default:
        return 0.3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isWide = MediaQuery.of(context).size.width > 720;
    final spendly = context.spendly;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: BoxConstraints(maxWidth: isWide ? 460 : double.infinity),
            child: SpendlyCard(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 72,
                      width: 72,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Join Spendly',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: spendly.colors.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start tracking expenses together with your family securely.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: spendly.colors.neutral500),
                    ),
                    const SizedBox(height: 28),
                    SpendlyInputField(
                      controller: _nameController,
                      label: 'Your Name (e.g. Dad, Mom, Preet)',
                      prefixIcon: Icon(Icons.person_outline, color: spendly.colors.neutral400),
                      validator: (value) {
                        try {
                          SchemaValidator.validateDisplayName(value);
                          return null;
                        } catch (e) {
                          return e.toString();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    SpendlyInputField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      label: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined, color: spendly.colors.neutral400),
                      validator: (value) {
                        try {
                          SchemaValidator.validateEmail(value);
                          return null;
                        } catch (e) {
                          return e.toString();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    SpendlyInputField(
                      controller: _passwordController,
                      isPassword: true,
                      label: 'Password',
                      prefixIcon: Icon(Icons.lock_outline, color: spendly.colors.neutral400),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.vpn_key_outlined, size: 20, color: spendly.colors.neutral400),
                        tooltip: 'Suggest Strong Password',
                        onPressed: () {
                          final strongPass = CryptoUtils.generateStrongPassword();
                          setState(() {
                            _passwordController.text = strongPass;
                          });
                        },
                      ),
                      onChanged: (val) {
                        setState(() {});
                      },
                      validator: (value) {
                        try {
                          SchemaValidator.validateStrictPassword(value);
                          return null;
                        } catch (e) {
                          return e.toString();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final strength = _checkPasswordStrength(_passwordController.text);
                        if (strength.isEmpty) return const SizedBox.shrink();
                        final color = _getStrengthColor(strength, spendly);
                        final percent = _getStrengthPercent(strength);
                        
                        String tip = 'Tip: Use at least 6 characters, including numbers and symbols.';
                        if (strength == 'Medium') {
                          tip = 'Tip: Add capital letters and symbols to make it Strong.';
                        } else if (strength == 'Strong') {
                          tip = 'Excellent! Your password is highly secure.';
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Password Strength: $strength',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SpendlyProgressBar(
                              value: percent,
                              color: color,
                              height: 6,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              tip,
                              style: TextStyle(fontSize: 12, color: spendly.colors.neutral400),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    SpendlyButton(
                      text: 'CREATE ACCOUNT',
                      variant: SpendlyButtonVariant.primary,
                      size: SpendlyButtonSize.large,
                      isLoading: authState.isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account?",
                          style: TextStyle(color: spendly.colors.neutral500),
                        ),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: Text(
                            "Login",
                            style: TextStyle(
                              color: spendly.colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
