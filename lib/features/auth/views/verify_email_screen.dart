import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/core/providers/state_providers.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _signUpTriggered = false;

  Future<void> _initiateMigration() async {
    final success = await ref.read(authProvider.notifier).startMigrationSignUp();
    if (!mounted) return;
    if (success) {
      setState(() {
        _signUpTriggered = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent! Please check your inbox.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final error = ref.read(authProvider).error ?? 'Failed to send verification email';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _checkVerificationAndComplete() async {
    final success = await ref.read(authProvider.notifier).verifyAndCompleteMigration();
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Migration successful! Welcome to the new secure Spendly.'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/home');
    } else {
      final error = ref.read(authProvider).error ?? 'Verification check failed. Make sure you clicked the link in your email.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _cancelMigration() {
    ref.read(authProvider.notifier).cancelMigration();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isWide = MediaQuery.of(context).size.width > 720;
    
    // Safety check: if no migration is pending, redirect back
    if (!authState.isMigrationPending) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No pending migration session found.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Migration'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isWide ? 500 : double.infinity),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  _signUpTriggered ? Icons.mark_email_read_outlined : Icons.security_outlined,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  _signUpTriggered ? 'Confirm Your Email' : 'Upgrade Account Security',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                
                if (!_signUpTriggered) ...[
                  const Text(
                    'We are upgrading Spendly to native Supabase Authentication for enhanced security (including secure sessions, JWTs, and email verification).\n\n'
                    'Your data (expenses, families, budgets, and settings) will remain completely intact. We just need to register your account on the new system and verify your email.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.blue.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.blue.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Account: ${authState.email}\nNickname: ${authState.displayName}',
                              style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (authState.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    ElevatedButton(
                      onPressed: _initiateMigration,
                      child: const Text('INITIATE MIGRATION'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _cancelMigration,
                      child: const Text('CANCEL & LOGOUT'),
                    ),
                  ],
                ] else ...[
                  Text(
                    'A verification link has been sent to:\n${authState.email}\n\n'
                    '1. Open your email client and find the email from Spendly.\n'
                    '2. Click the confirmation link to activate your native Supabase account.\n'
                    '3. Return to this screen and click the button below to complete your migration.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  if (authState.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    ElevatedButton.icon(
                      onPressed: _checkVerificationAndComplete,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('I HAVE VERIFIED MY EMAIL'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _initiateMigration,
                      icon: const Icon(Icons.refresh),
                      label: const Text('RESEND VERIFICATION EMAIL'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _cancelMigration,
                      child: const Text('Cancel Migration'),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
