import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StartupScreen extends ConsumerWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.shrink(),
    );
  }
}

/*
Original StartupScreen Implementation (Preserved):

class _OriginalStartupScreen extends ConsumerWidget {
  const _OriginalStartupScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // App Logo
                Image.asset(
                  'assets/images/logo.png',
                  height: 96,
                  width: 96,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 48,
                        color: theme.primaryColor,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // App Name
                Text(
                  'Spendly',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Family Finance Companion',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                ),
                const Spacer(),
                // Loading Section
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Restoring your session...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
*/
