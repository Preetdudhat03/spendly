import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/utils/schema_validator.dart';
import 'package:spendly/core/widgets/spendly/spendly.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final success = await ref.read(authProvider.notifier).signIn(email, password);

    if (!mounted) return;

    if (!success) {
      final error = ref.read(authProvider).error;
      if (error == 'USER_NOT_FOUND') {
        SpendlySnackbar.show(
          context: context,
          message: 'This account does not exist. Please sign up first.',
          isError: false,
        );
        context.push('/register?email=${Uri.encodeComponent(email)}');
      } else {
        SpendlySnackbar.show(
          context: context,
          message: error ?? 'Authentication failed',
          isError: true,
        );
      }
    } else {
      final authState = ref.read(authProvider);
      if (authState.isMigrationPending) {
        context.go('/verify-email');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final connection = ref.watch(connectionProvider);
    final isWide = MediaQuery.of(context).size.width > 720;
    final spendly = context.spendly;
    final theme = Theme.of(context);

    return Scaffold(
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
                      'Spendly',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: spendly.colors.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Simple Family Expense Tracker',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: spendly.colors.neutral500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: spendly.colors.neutral100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: connection == ConnectionStatus.online
                                    ? spendly.colors.success
                                    : (connection == ConnectionStatus.sandbox ? Colors.blue : spendly.colors.warning),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              connection == ConnectionStatus.online
                                  ? 'Connected to Supabase'
                                  : (connection == ConnectionStatus.sandbox
                                      ? 'Offline Sandbox (Local Mode)'
                                      : 'Offline (No Connection)'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: spendly.colors.neutral600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
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
                      validator: (value) {
                        try {
                          SchemaValidator.validateBasicPassword(value);
                          return null;
                        } catch (e) {
                          return e.toString();
                        }
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: spendly.colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SpendlyButton(
                      text: 'LOGIN',
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
                          "Don't have an account?",
                          style: TextStyle(color: spendly.colors.neutral500),
                        ),
                        TextButton(
                          onPressed: () => context.push('/register'),
                          child: Text(
                            "Sign Up",
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
