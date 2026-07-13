import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/features/expenses/views/home_screen.dart';
import 'package:spendly/features/expenses/views/add_expense_screen.dart';
import 'package:spendly/features/analytics/presentation/pages/analytics_page.dart';
import 'package:spendly/features/profile/views/profile_screen.dart';

import 'dart:ui';
import 'package:spendly/core/theme/spendly_tokens.dart';

class MainLayout extends ConsumerWidget {
  final int initialTab;

  const MainLayout({super.key, required this.initialTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width > 720;
    final theme = Theme.of(context);
    final spendlyTheme = context.spendly;

    return Scaffold(
      extendBody: true, // Allows body content to flow behind the bottom nav bar
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: initialTab,
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    context.go('/home');
                    break;
                  case 1:
                    context.go('/add');
                    break;
                  case 2:
                    context.go('/analytics');
                    break;
                  case 3:
                    context.go('/profile');
                    break;
                }
              },
              labelType: NavigationRailLabelType.all,
              indicatorColor: theme.primaryColor,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home, color: Colors.white),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.add_circle_outline),
                  selectedIcon: Icon(Icons.add_circle, color: Colors.white),
                  label: Text('Add'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart, color: Colors.white),
                  label: Text('Analytics'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person, color: Colors.white),
                  label: Text('Profile'),
                ),
              ],
            ),
          Expanded(
            child: IndexedStack(
              index: initialTab,
              children: const [
                HomeScreen(),
                AddExpenseScreen(),
                AnalyticsPage(),
                ProfileScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : Padding(
              padding: EdgeInsets.only(
                left: spendlyTheme.spacing.x4,
                right: spendlyTheme.spacing.x4,
                bottom: spendlyTheme.spacing.x5 + MediaQuery.of(context).padding.bottom,
              ),
              child: ClipRRect(
                borderRadius: spendlyTheme.radius.xlarge,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xBF1E293B)
                          : const Color(0xD9FFFFFF),
                      borderRadius: spendlyTheme.radius.xlarge,
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? const Color(0x1AFFFFFF)
                            : const Color(0x1F000000),
                        width: 1,
                      ),
                      boxShadow: spendlyTheme.elevation.surface2 ?? [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                          context: context,
                          icon: Icons.grid_view_rounded,
                          label: 'Home',
                          isSelected: initialTab == 0,
                          onTap: () => context.go('/home'),
                        ),
                        _buildNavItem(
                          context: context,
                          icon: Icons.bar_chart_rounded,
                          label: 'Analytics',
                          isSelected: initialTab == 2,
                          onTap: () => context.go('/analytics'),
                        ),
                        _buildFabItem(
                          context: context,
                          onTap: () => context.go('/add'),
                        ),
                        _buildNavItem(
                          context: context,
                          icon: Icons.person_rounded,
                          label: 'Profile',
                          isSelected: initialTab == 3,
                          onTap: () => context.go('/profile'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final spendlyTheme = context.spendly;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? spendlyTheme.colors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: isSelected
                  ? spendlyTheme.colors.primary
                  : spendlyTheme.colors.neutral500,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isSelected
                  ? spendlyTheme.colors.primary
                  : spendlyTheme.colors.neutral500,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFabItem({
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    final spendlyTheme = context.spendly;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              spendlyTheme.colors.primary,
              spendlyTheme.colors.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: spendlyTheme.colors.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
