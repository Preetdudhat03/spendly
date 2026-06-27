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
  bool _showInstructions = false;

  Future<void> _initiateMigration() async {
    debugPrint('VerifyEmailScreen: _initiateMigration called.');
    final success = await ref.read(authProvider.notifier).startMigrationSignUp();
    debugPrint('VerifyEmailScreen: startMigrationSignUp success = $success');
    if (!mounted) return;
    if (success) {
      debugPrint('VerifyEmailScreen: setting _showInstructions = true');
      setState(() {
        _showInstructions = true;
      });
    } else {
      final error = ref.read(authProvider).error ?? 'Failed to initiate migration';
      debugPrint('VerifyEmailScreen: initiate failed, error = $error');
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

  Future<void> _checkVerificationAndComplete() async {
    debugPrint('VerifyEmailScreen: _checkVerificationAndComplete called.');
    final success = await ref.read(authProvider.notifier).verifyAndCompleteMigration();
    debugPrint('VerifyEmailScreen: verifyAndCompleteMigration success = $success');
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
      debugPrint('VerifyEmailScreen: verification failed, error = $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _resendEmail() async {
    final success = await ref.read(authProvider.notifier).startMigrationSignUp();
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email resent! Please check your inbox.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final error = ref.read(authProvider).error ?? 'Failed to resend email';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isWide = MediaQuery.of(context).size.width > 720;
    
    // Safety check: if no migration is pending, redirect back
    if (!authState.isMigrationPending) {
      if (authState.userId != null) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
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

    if (_showInstructions) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Verify Your Email'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _showInstructions = false;
              });
            },
          ),
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
                    Icons.mark_email_read_outlined,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Confirm Email',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We have registered your account on native Supabase Auth. A verification email has been sent to:\n${authState.email}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Verification Instructions:', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(radius: 10, child: Text('1', style: TextStyle(fontSize: 11))),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text('Open your email client and check your inbox (or spam folder).'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(radius: 10, child: Text('2', style: TextStyle(fontSize: 11))),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text('Click the confirmation link inside the email to verify your email address.'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(radius: 10, child: Text('3', style: TextStyle(fontSize: 11))),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text('Return to this page and click the button below to complete your migration.'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
                      onPressed: _resendEmail,
                      icon: const Icon(Icons.refresh),
                      label: const Text('RESEND VERIFICATION EMAIL'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Default migration initiation screen
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Upgrade'),
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
                  Icons.security_outlined,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Upgrade Account Security',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
