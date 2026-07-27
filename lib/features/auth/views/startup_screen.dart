import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StartupScreen extends ConsumerStatefulWidget {
  const StartupScreen({super.key});

  @override
  ConsumerState<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends ConsumerState<StartupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _titleOpacity;
  late Animation<double> _attributionOpacity;

  Timer? _slowStartupTimer;
  bool _showSlowFallback = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _logoScale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.80, curve: Curves.easeOut),
      ),
    );

    _attributionOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Minimum branded splash display duration (~1000ms) for smooth entrance & transition
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        ref.read(splashFinishedProvider.notifier).state = true;
      }
    });

    // Slow startup fallback timer (triggers if session check takes > 1.5 seconds)
    _slowStartupTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showSlowFallback = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _slowStartupTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryTextColor = isDark ? Colors.white : theme.primaryColor;
    final attributionColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : (theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.45) ??
            Colors.black38);

    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),

            // CENTER BRAND SECTION (Logo + Title as one unified block)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo with subtle fade & scale
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      if (disableAnimations) {
                        return child!;
                      }
                      return FadeTransition(
                        opacity: _logoOpacity,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: child,
                        ),
                      );
                    },
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 88,
                      width: 88,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 44,
                            color: theme.primaryColor,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // "Spendly" App Title
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      if (disableAnimations) {
                        return child!;
                      }
                      return FadeTransition(
                        opacity: _titleOpacity,
                        child: child,
                      );
                    },
                    child: Text(
                      'Spendly',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: primaryTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 3),

            // SLOW STARTUP FALLBACK (Subtle indicator if > 1.2s)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _showSlowFallback ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          attributionColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Restoring your session...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: attributionColor,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // BOTTOM BRAND ATTRIBUTION
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                if (disableAnimations) {
                  return child!;
                }
                return FadeTransition(
                  opacity: _attributionOpacity,
                  child: child,
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  'Crafted by Preet',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: attributionColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
