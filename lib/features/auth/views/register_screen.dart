import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/utils/crypto_utils.dart';
import 'package:spendly/core/utils/schema_validator.dart';
import 'package:spendly/core/widgets/capsule_top_bar.dart';

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
  bool _obscurePassword = true;

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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Confirm Email'),
          content: Text(stateMsg),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                context.go('/login'); // Return to login
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      final error = ref.read(authProvider).error ?? 'Registration failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
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

  Color _getStrengthColor(String strength) {
    switch (strength) {
      case 'Strong':
        return const Color(0xFF22C55E);
      case 'Medium':
        return const Color(0xFFF59E0B);
      case 'Weak':
      default:
        return const Color(0xFFEF4444);
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 720;

    final accentColor = isDark
        ? const Color(0xFF818CF8)
        : colorScheme.primary;

    final topInset = MediaQuery.of(context).padding.top;
    final contentTopPadding = topInset + 58.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const CapsuleHeader(
          title: 'Create Account',
          icon: Icons.person_add_rounded,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24.0, contentTopPadding + 8.0, 24.0, 32.0),
          child: Container(
            constraints: BoxConstraints(maxWidth: isWide ? 460 : double.infinity),
            child: Card(
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Ambient top banner gradient
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 120,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accentColor.withValues(
                              alpha: isDark ? 0.16 : 0.08,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 36.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accentColor.withValues(
                                    alpha: isDark ? 0.3 : 0.2,
                                  ),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withValues(
                                      alpha: isDark ? 0.2 : 0.1,
                                    ),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.account_balance_wallet_rounded,
                                  size: 36,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Join Spendly',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Start tracking expenses together with your family securely.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 28),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Your Name (e.g. Dad, Mom, Preet)',
                              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                                  : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
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
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: const Icon(Icons.email_outlined, size: 20),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                                  : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
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
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            onChanged: (val) {
                              setState(() {});
                            },
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                                  : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.vpn_key_outlined, size: 20),
                                    tooltip: 'Suggest Strong Password',
                                    onPressed: () {
                                      final strongPass = CryptoUtils.generateStrongPassword();
                                      setState(() {
                                        _passwordController.text = strongPass;
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      size: 20,
                                    ),
                                    tooltip: _obscurePassword ? 'Show Password' : 'Hide Password',
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
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
                              final color = _getStrengthColor(strength);
                              final percent = _getStrengthPercent(strength);
                              
                              String tip = 'Tip: Use at least 6 characters, including numbers and symbols.';
                              if (strength == 'Medium') {
                                tip = 'Tip: Add capital letters and symbols to make it Strong.';
                              } else if (strength == 'Strong') {
                                tip = 'Excellent! Your password is highly secure.';
                              }

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: isDark ? 0.12 : 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: color.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Password Strength: $strength',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: color,
                                          ),
                                        ),
                                        Text(
                                          '${(percent * 100).toInt()}%',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: color,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: percent,
                                        minHeight: 5,
                                        color: color,
                                        backgroundColor: color.withValues(alpha: 0.15),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      tip,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 28),
                          if (authState.isLoading)
                            const Center(child: CircularProgressIndicator())
                          else
                            ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'CREATE ACCOUNT',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account?",
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.pop(),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                ),
                                child: Text(
                                  "Login",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
