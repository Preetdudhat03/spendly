import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OtpType;
import 'package:spendly/core/constants/auth_constants.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/widgets/capsule_top_bar.dart';
import 'package:spendly/core/widgets/spendly_toast.dart';

enum OtpVerificationMode {
  login,
  signup,
  emailChange,
}

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String? email;
  final OtpVerificationMode mode;

  const OtpVerificationScreen({
    super.key,
    this.email,
    this.mode = OtpVerificationMode.login,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
  static const int _otpLength = 6;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
    _syncCooldownFromState();
    _startCooldownTicker();
  }

  void _syncCooldownFromState() {
    final remaining = ref.read(authProvider).resendCooldownRemaining;
    if (remaining > 0) {
      _cooldownSeconds = remaining;
    }
  }

  void _startCooldownTicker() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = ref.read(authProvider).resendCooldownRemaining;
      if (remaining != _cooldownSeconds) {
        setState(() {
          _cooldownSeconds = remaining;
        });
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _effectiveEmail {
    final auth = ref.read(authProvider);
    return (widget.email?.trim().isNotEmpty == true
            ? widget.email!
            : (auth.pendingEmail ?? auth.email ?? ''))
        .trim();
  }

  String get _enteredCode => _controllers.map((c) => c.text).join();

  void _handleDigitChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    // Handle paste of full or multi-digit OTP
    if (digits.length > 1) {
      for (int i = 0; i < _otpLength; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final nextIndex =
          digits.length >= _otpLength ? _otpLength - 1 : digits.length;
      _focusNodes[nextIndex].requestFocus();
      setState(() {});
      if (digits.length >= _otpLength) {
        _verifyOtp();
      }
      return;
    }

    if (digits.isEmpty) {
      _controllers[index].text = '';
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      setState(() {});
      return;
    }

    _controllers[index].text = digits;
    _controllers[index].selection = const TextSelection.collapsed(offset: 1);
    if (index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }
    setState(() {});
  }

  Future<void> _verifyOtp() async {
    final email = _effectiveEmail;
    if (email.isEmpty) {
      SpendlyToast.showError(
        context,
        'Email address is missing. Please go back and enter your email.',
        isAboveNavBar: false,
      );
      return;
    }

    final code = _enteredCode;
    if (code.length != _otpLength) {
      SpendlyToast.showWarning(
        context,
        'Please enter all 6 digits of the verification code.',
        isAboveNavBar: false,
      );
      return;
    }

    final otpType = switch (widget.mode) {
      OtpVerificationMode.login => OtpType.email,
      OtpVerificationMode.signup => OtpType.signup,
      OtpVerificationMode.emailChange => OtpType.emailChange,
    };

    final success = await ref.read(authProvider.notifier).verifyEmailOtp(
          email: email,
          token: code,
          type: otpType,
        );

    if (!mounted) return;

    if (success) {
      SpendlyToast.showSuccess(
        context,
        widget.mode == OtpVerificationMode.emailChange
            ? 'Email verified and updated!'
            : 'Email verified successfully!',
        isAboveNavBar: false,
      );
      if (widget.mode == OtpVerificationMode.emailChange) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/profile');
        }
      } else {
        context.go('/home');
      }
    } else {
      final err = ref.read(authProvider).error ?? 'Invalid or expired OTP.';
      SpendlyToast.showError(context, err, isAboveNavBar: false);
    }
  }

  Future<void> _resendOtp() async {
    final email = _effectiveEmail;
    if (email.isEmpty || _cooldownSeconds > 0) return;

    final notifier = ref.read(authProvider.notifier);
    bool sent = false;
    switch (widget.mode) {
      case OtpVerificationMode.login:
        sent = await notifier.sendEmailOtp(email);
        break;
      case OtpVerificationMode.signup:
        sent = await notifier.resendSignupVerification(email);
        break;
      case OtpVerificationMode.emailChange:
        sent = await notifier.updateEmail(email);
        break;
    }

    if (!mounted) return;
    _syncCooldownFromState();
    setState(() {});

    if (sent) {
      SpendlyToast.showSuccess(
        context,
        'A new verification code has been sent.',
        isAboveNavBar: false,
      );
    } else {
      final err = ref.read(authProvider).error ?? 'Could not resend code.';
      SpendlyToast.showError(context, err, isAboveNavBar: false);
    }
  }

  void _handleChangeEmail() {
    if (widget.mode == OtpVerificationMode.emailChange) {
      ref.read(authProvider.notifier).cancelPendingEmailChange();
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/profile');
      }
    } else if (widget.mode == OtpVerificationMode.signup) {
      context.go('/register?email=${Uri.encodeComponent(_effectiveEmail)}');
    } else {
      ref.read(authProvider.notifier).clearPendingVerification();
      context.go('/login');
    }
  }

  void _handleBackToLogin() {
    if (widget.mode == OtpVerificationMode.emailChange) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/profile');
      }
      return;
    }
    ref.read(authProvider.notifier).clearPendingVerification();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 720;
    final accentColor = isDark ? const Color(0xFF818CF8) : colorScheme.primary;
    final email = _effectiveEmail;
    final maskedEmail = email.isNotEmpty ? AuthConstants.maskEmail(email) : '';

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
          onPressed: _handleBackToLogin,
        ),
        title: const CapsuleHeader(
          title: 'Email Verification',
          icon: Icons.pin_rounded,
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
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
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
                            accentColor.withValues(alpha: isDark ? 0.16 : 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 32.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: accentColor.withValues(
                                  alpha: isDark ? 0.3 : 0.2,
                                ),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.mark_email_unread_outlined,
                              size: 36,
                              color: accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Verify Your Email',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "We've sent a verification code to your email address.",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (maskedEmail.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            maskedEmail,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(_otpLength, (index) {
                            return SizedBox(
                              width: 44,
                              child: KeyboardListener(
                                focusNode: FocusNode(skipTraversal: true),
                                onKeyEvent: (event) {
                                  if (event is KeyDownEvent &&
                                      event.logicalKey ==
                                          LogicalKeyboardKey.backspace &&
                                      _controllers[index].text.isEmpty &&
                                      index > 0) {
                                    _focusNodes[index - 1].requestFocus();
                                    _controllers[index - 1].clear();
                                    setState(() {});
                                  }
                                },
                                child: TextField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  maxLength: 6,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    counterText: '',
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                                        : const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: accentColor,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  onChanged: (val) =>
                                      _handleDigitChanged(index, val),
                                ),
                              ),
                            );
                          }),
                        ),
                        if (authState.error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.error.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              authState.error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colorScheme.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ] else if (authState.statusMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              authState.statusMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF16A34A),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (authState.isLoading)
                          const Center(child: CircularProgressIndicator())
                        else
                          ElevatedButton(
                            onPressed: _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'VERIFY OTP',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed:
                              (_cooldownSeconds > 0 || authState.isLoading)
                                  ? null
                                  : _resendOtp,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(
                            _cooldownSeconds > 0
                                ? 'Resend OTP in ${_cooldownSeconds}s'
                                : 'Resend OTP',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: _handleChangeEmail,
                              child: Text(
                                'Change Email',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: accentColor,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _handleBackToLogin,
                              child: Text(
                                widget.mode == OtpVerificationMode.emailChange
                                    ? 'Back to Profile'
                                    : 'Back to Login',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
