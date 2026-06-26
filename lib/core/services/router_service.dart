import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/features/auth/views/login_screen.dart';
import 'package:spendly/features/auth/views/register_screen.dart';
import 'package:spendly/features/auth/views/forgot_password_screen.dart';
import 'package:spendly/features/auth/views/verify_email_screen.dart';
import 'package:spendly/features/family/views/family_setup_screen.dart';
import 'package:spendly/features/navigation/views/main_layout.dart';
import 'package:spendly/features/expenses/views/all_expenses_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Watch auth and family states to trigger router refresh on changes
  final auth = ref.watch(authProvider);
  final family = ref.watch(familyProvider);

  return GoRouter(
    initialLocation: '/home',
    // Listen to changes to run redirect
    refreshListenable: _ProviderListenable(ref),
    redirect: (context, state) {
      final isLoggedIn = auth.userId != null;
      final isPendingMigration = auth.isMigrationPending;
      
      final publicRoutes = ['/login', '/register', '/forgot-password', '/verify-email'];
      final isPublicRoute = publicRoutes.contains(state.matchedLocation);

      if (!isLoggedIn) {
        // If unauthenticated, allow public routes, else redirect to /login
        return isPublicRoute ? null : '/login';
      }

      // User is logged in (either legacy user or native Supabase user)
      if (isPendingMigration) {
        // If they are in the middle of a migration, they MUST go to /verify-email
        return state.matchedLocation == '/verify-email' ? null : '/verify-email';
      }

      // If they are logged in and verified, prevent accessing public authentication routes
      if (state.matchedLocation == '/login' || 
          state.matchedLocation == '/register' || 
          state.matchedLocation == '/forgot-password') {
        return '/home';
      }

      // Wait for states to load before making family routing decisions
      if (auth.isLoading || family.isLoading) {
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
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
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
      GoRoute(
        path: '/expenses',
        builder: (context, state) => const AllExpensesScreen(),
      ),
      // Shell route or sub-paths for MainLayout
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainLayout(initialTab: 0),
      ),
      GoRoute(
        path: '/add',
        builder: (context, state) => const MainLayout(initialTab: 1),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const MainLayout(initialTab: 2),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const MainLayout(initialTab: 3),
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
