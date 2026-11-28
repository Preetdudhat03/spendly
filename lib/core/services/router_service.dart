import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/features/auth/views/login_screen.dart';
import 'package:spendly/features/auth/views/register_screen.dart';
import 'package:spendly/features/auth/views/forgot_password_screen.dart';
import 'package:spendly/features/auth/views/verify_email_screen.dart';
import 'package:spendly/features/auth/views/otp_verification_screen.dart';
import 'package:spendly/features/auth/views/auth_callback_screen.dart';
import 'package:spendly/features/auth/views/startup_screen.dart';
import 'package:spendly/features/family/views/family_setup_screen.dart';
import 'package:spendly/features/navigation/views/main_layout.dart';
import 'package:spendly/features/expenses/views/home_screen.dart';
import 'package:spendly/features/expenses/views/add_expense_screen.dart';
import 'package:spendly/features/analytics/presentation/pages/analytics_page.dart';
import 'package:spendly/features/expenses/views/all_expenses_screen.dart';
import 'package:spendly/features/profile/views/profile_screen.dart';
import 'package:spendly/features/profile/views/account_security_screen.dart';
import 'package:spendly/features/notifications/presentation/pages/notifications_page.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'spendlyRootNav');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    // Listen to changes to run redirect
    refreshListenable: _ProviderListenable(ref),
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final family = ref.read(familyProvider);

      if (auth.isInitializing) {
        return '/splash';
      }

      final isLoggedIn = auth.userId != null;

      final publicRoutes = [
        '/login',
        '/register',
        '/forgot-password',
        '/verify-email',
        '/otp-verify',
        '/auth-callback',
        '/reset-password',
        '/splash',
      ];
      final isPublicRoute = publicRoutes.contains(state.matchedLocation);

      // Allow OTP verification and auth-callback routes for both authenticated
      // (e.g. email change) and unauthenticated (e.g. signup / OTP login) users.
      if (state.matchedLocation == '/otp-verify' ||
          state.matchedLocation == '/auth-callback' ||
          state.matchedLocation == '/reset-password') {
        return null;
      }

      if (!isLoggedIn) {
        // If verification is pending and user is not already on verify/otp/register/login,
        // direct them to the verification screen instead of leaving a blank screen.
        if (auth.isVerificationPending && !isPublicRoute) {
          return '/verify-email';
        }
        // If unauthenticated, allow public routes, else redirect to /login
        return isPublicRoute ? null : '/login';
      }

      // If they are logged in, prevent accessing public authentication routes
      if (state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/verify-email' ||
          state.matchedLocation == '/splash') {
        return '/home';
      }

      // Wait for states to load before making family routing decisions
      if (auth.isLoading || family.isLoading || !family.hasLoaded) {
        return null;
      }

      final hasFamily = family.family != null;
      final isSettingUpFamily = state.matchedLocation == '/family-setup';

      if (!hasFamily && !isSettingUpFamily) {
        return '/family-setup';
      }

      if (hasFamily && isSettingUpFamily) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const StartupScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return RegisterScreen(initialEmail: email);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/otp-verify',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          final modeStr = state.uri.queryParameters['mode'];
          final mode = switch (modeStr) {
            'signup' => OtpVerificationMode.signup,
            'emailChange' => OtpVerificationMode.emailChange,
            _ => OtpVerificationMode.login,
          };
          return OtpVerificationScreen(email: email, mode: mode);
        },
      ),
      GoRoute(
        path: '/auth-callback',
        builder: (context, state) => AuthCallbackScreen(callbackUri: state.uri),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => AuthCallbackScreen(callbackUri: state.uri),
      ),
      GoRoute(
        path: '/family-setup',
        builder: (context, state) => const FamilySetupScreen(),
      ),
      StatefulShellRoute(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        navigatorContainerBuilder: (context, navigationShell, children) {
          return PersistentStack(
            index: navigationShell.currentIndex,
            children: children,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/add',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: AddExpenseScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: AnalyticsPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/expenses',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: AllExpensesScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/account-security',
        builder: (context, state) => const AccountSecurityScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
    ],
    errorBuilder: (context, state) => AuthCallbackScreen(
      callbackUri: state.uri,
      fallbackError: state.error?.toString() ??
          'We could not open that page. Please return to Spendly.',
    ),
  );
});

class _ProviderListenable extends ChangeNotifier {
  _ProviderListenable(Ref ref) {
    ref.listen(authProvider, (previous, next) {
      if (previous?.userId != next.userId ||
          previous?.status != next.status ||
          previous?.isInitializing != next.isInitializing ||
          previous?.isLoading != next.isLoading) {
        notifyListeners();
      }
    });
    ref.listen(familyProvider, (previous, next) {
      if (previous?.family?.id != next.family?.id ||
          previous?.hasLoaded != next.hasLoaded ||
          previous?.isLoading != next.isLoading) {
        notifyListeners();
      }
    });
  }
}
