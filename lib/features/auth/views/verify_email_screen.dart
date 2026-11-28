import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/core/constants/auth_constants.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/widgets/capsule_top_bar.dart';
import 'package:spendly/core/widgets/spendly_toast.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    _cooldownSeconds = ref.read(authProvider).resendCooldownRemaining;
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
    super.dispose();
  }

  Future<void> _resendConfirmation(String email) async {
    if (email.isEmpty || _cooldownSeconds > 0) return;
    final ok = await ref
        .read(authProvider.notifier)
        .resendSignupVerification(email);
    if (!mounted) return;
    setState(() {
      _cooldownSeconds = ref.read(authProvider).resendCooldownRemaining;
    });
    if (ok) {
      SpendlyToast.showSuccess(
        context,
        'Verification email resent. Please check your inbox.',
        isAboveNavBar: false,
      );
    } else {
      final err = ref.read(authProvider).error ?? 'Failed to resend email.';
      SpendlyToast.showError(context, err, isAboveNavBar: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 720;
    final accentColor = isDark ? const Color(0xFF818CF8) : colorScheme.primary;

    final pendingEmail =
        (authState.pendingEmail ?? authState.email ?? '').trim();
    final maskedEmail = pendingEmail.isNotEmpty
        ? AuthConstants.maskEmail(pendingEmail)
        : '';

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
          onPressed: () {
            ref.read(authProvider.notifier).clearPendingVerification();
            context.go('/login');
          },
        ),
        title: const CapsuleHeader(
          title: 'Verify Email',
          icon: Icons.mark_email_read_rounded,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24.0,
            contentTopPadding + 8.0,
            24.0,
            32.0,
          ),
          child: Container(
            constraints: BoxConstraints(maxWidth: isWide ? 480 : double.infinity),
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
                            child: Icon(
                              Icons.mark_email_read_outlined,
                              size: 38,
                              color: accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Check Your Inbox',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pendingEmail.isNotEmpty
                              ? 'We sent a confirmation link to:\n$maskedEmail ($pendingEmail)'
                              : 'A verification link has been sent to your registered email address.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Next Steps:',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildStepRow(
                                context,
                                '1',
                                'Open your email inbox (or spam folder).',
                                accentColor,
                              ),
                              const SizedBox(height: 10),
                              _buildStepRow(
                                context,
                                '2',
                                'Tap the confirmation link to open Spendly, or enter the 6-digit code.',
                                accentColor,
                              ),
                              const SizedBox(height: 10),
                              _buildStepRow(
                                context,
                                '3',
                                'Once verified, you will be signed in to your account.',
                                accentColor,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (authState.isLoading)
                          const Center(child: CircularProgressIndicator())
                        else ...[
                          ElevatedButton.icon(
                            onPressed: (_cooldownSeconds > 0 || pendingEmail.isEmpty)
                                ? null
                                : () => _resendConfirmation(pendingEmail),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: Text(
                              _cooldownSeconds > 0
                                  ? 'RESEND EMAIL IN ${_cooldownSeconds}S'
                                  : 'RESEND VERIFICATION EMAIL',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                          if (pendingEmail.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                context.push(
                                  '/otp-verify?mode=signup&email=${Uri.encodeComponent(pendingEmail)}',
                                );
                              },
                              icon: const Icon(Icons.pin_outlined, size: 18),
                              label: const Text(
                                'ENTER 6-DIGIT OTP CODE',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                context.go(
                                  '/register?email=${Uri.encodeComponent(pendingEmail)}',
                                );
                              },
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
                              onPressed: () {
                                ref
                                    .read(authProvider.notifier)
                                    .clearPendingVerification();
                                context.go('/login');
                              },
                              child: Text(
                                'Back to Login',
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

  Widget _buildStepRow(
    BuildContext context,
    String number,
    String text,
    Color accentColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accentColor,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
