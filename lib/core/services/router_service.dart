import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/features/auth/views/login_screen.dart';
import 'package:spendly/features/auth/views/register_screen.dart';
import 'package:spendly/features/auth/views/forgot_password_screen.dart';
import 'package:spendly/features/auth/views/verify_email_screen.dart';
import 'package:spendly/features/auth/views/startup_screen.dart';
import 'package:spendly/features/family/views/family_setup_screen.dart';
import 'package:spendly/features/navigation/views/main_layout.dart';
import 'package:spendly/features/expenses/views/home_screen.dart';
import 'package:spendly/features/expenses/views/add_expense_screen.dart';
import 'package:spendly/features/analytics/presentation/pages/analytics_page.dart';
import 'package:spendly/features/expenses/views/all_expenses_screen.dart';
import 'package:spendly/features/profile/views/profile_screen.dart';
import 'package:spendly/features/profile/views/account_security_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
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
      final isPendingMigration = auth.isMigrationPending;
      
      final publicRoutes = ['/login', '/register', '/forgot-password', '/verify-email', '/splash'];
      final isPublicRoute = publicRoutes.contains(state.matchedLocation);

      if (!isLoggedIn) {
        // If unauthenticated, allow public routes, else redirect to /login
        return isPublicRoute ? null : '/login';
      }

      // User is logged in (either legacy user or native Supabase user)
      if (isPendingMigration) {
        // If they are in the middle of a migration, they MUST stay on verify-email
        return state.matchedLocation == '/verify-email' ? null : '/verify-email';
      }

      // If they are logged in and verified, prevent accessing public authentication routes
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
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const StartupScreen(),
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
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
    ],
  );
});

// A simple Listenable that merges riverpod states to notify GoRouter when Auth/Family changes.
class _ProviderListenable extends ChangeNotifier {
  _ProviderListenable(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
    ref.listen(familyProvider, (_, __) => notifyListeners());
  }
}
