import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/services/auth_deep_link_service.dart';
import 'package:spendly/core/widgets/capsule_top_bar.dart';

class AuthCallbackScreen extends ConsumerStatefulWidget {
  final Uri? callbackUri;
  final String? fallbackError;

  const AuthCallbackScreen({
    super.key,
    this.callbackUri,
    this.fallbackError,
  });

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  bool _processed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _processIfNeeded());
  }

  Future<void> _processIfNeeded() async {
    if (_processed || !mounted) return;
    _processed = true;
    if (widget.callbackUri != null) {
      final parsed = AuthDeepLinkService.parseCallbackUri(widget.callbackUri!);
      if (parsed.kind != AuthCallbackKind.ignored) {
        await ref.read(authProvider.notifier).handleAuthCallback(parsed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = isDark ? const Color(0xFF818CF8) : colorScheme.primary;

    final errorText = widget.fallbackError ?? authState.error;
    final isLoading = authState.isLoading;
    final isError = !isLoading && errorText != null && errorText.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const CapsuleHeader(
          title: 'Account Verification',
          icon: Icons.verified_user_rounded,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ??
                  (isDark ? const Color(0xFF1E293B) : Colors.white),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isLoading) ...[
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 20),
                  Text(
                    'Verifying your request...',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ] else if (isError) ...[
                  Icon(
                    Icons.error_outline_rounded,
                    size: 52,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Verification Issue',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    errorText,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(authProvider.notifier).clearPendingVerification();
                      context.go(
                        authState.userId != null ? '/home' : '/login',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      authState.userId != null ? 'GO TO HOME' : 'BACK TO LOGIN',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 52,
                    color: accentColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Verification Complete',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    authState.statusMessage ??
                        'Your email verification was processed successfully.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go(
                      authState.userId != null ? '/home' : '/login',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      authState.userId != null ? 'CONTINUE TO APP' : 'GO TO LOGIN',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
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
