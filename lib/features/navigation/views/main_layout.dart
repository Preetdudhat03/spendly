import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/features/expenses/views/home_screen.dart';
import 'package:spendly/features/expenses/views/add_expense_screen.dart';
import 'package:spendly/features/analytics/presentation/pages/analytics_page.dart';
import 'package:spendly/features/profile/views/profile_screen.dart';

class MainLayout extends ConsumerWidget {
  final int initialTab;

  const MainLayout({super.key, required this.initialTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width > 720;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
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
              indicatorColor: Theme.of(context).primaryColor,
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
          : SafeArea(
              child: Container(
                margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 8),
                height: 76,
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.grey[900]!.withOpacity(0.85)
                      : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(38),
                  boxShadow: [
                    BoxShadow(
                      color: isDark 
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.06),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(38),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavItem(
                            context,
                            index: 0,
                            icon: Icons.home_rounded,
                            activeIcon: Icons.home_rounded,
                            label: 'Home',
                            route: '/home',
                          ),
                          _buildNavItem(
                            context,
                            index: 2,
                            icon: Icons.bar_chart_rounded,
                            activeIcon: Icons.bar_chart_rounded,
                            label: 'Stats',
                            route: '/analytics',
                          ),
                          _buildFab(context),
                          _buildExpensesItem(context),
                          _buildNavItem(
                            context,
                            index: 3,
                            icon: Icons.person_rounded,
                            activeIcon: Icons.person_rounded,
                            label: 'Profile',
                            route: '/profile',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
  }) {
    final isActive = initialTab == index;
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurfaceVariant.withOpacity(0.6);

    return GestureDetector(
      onTap: () => context.go(route),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? activeColor : inactiveColor,
              size: 24,
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: isActive ? 60 : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isActive ? 1.0 : 0.0,
                curve: Curves.easeInOut,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: activeColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    final isActive = initialTab == 1;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.go('/add'),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isActive 
                ? [theme.colorScheme.primary, theme.colorScheme.primary]
                : [theme.colorScheme.primary, theme.colorScheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: AnimatedRotation(
          turns: isActive ? 0.125 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildExpensesItem(BuildContext context) {
    final theme = Theme.of(context);
    final inactiveColor = theme.colorScheme.onSurfaceVariant.withOpacity(0.6);

    return GestureDetector(
      onTap: () => context.push('/expenses'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(
          Icons.history_rounded,
          color: inactiveColor,
          size: 24,
        ),
      ),
    );
  }
}
