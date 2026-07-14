import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/core/theme/spendly_tokens.dart';
import 'package:spendly/features/expenses/views/home_screen.dart';
import 'package:spendly/features/expenses/views/add_expense_screen.dart';
import 'package:spendly/features/analytics/presentation/pages/analytics_page.dart';
import 'package:spendly/features/expenses/views/all_expenses_screen.dart';
import 'package:spendly/features/profile/views/profile_screen.dart';

class MainLayout extends ConsumerWidget {
  final int initialTab;

  const MainLayout({super.key, required this.initialTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      body: Stack(
        children: [
          Row(
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
                        context.go('/expenses');
                        break;
                      case 4:
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
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long, color: Colors.white),
                      label: Text('Expenses'),
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
                    AllExpensesScreen(),
                    ProfileScreen(),
                  ],
                ),
              ),
            ],
          ),
          if (!isWide)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? context.spendly.colors.neutral900.withOpacity(0.8)
                                : Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? context.spendly.colors.neutral800.withOpacity(0.4)
                                  : context.spendly.colors.neutral200.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildNavItem(
                                context,
                                index: 0,
                                icon: Icons.home_outlined,
                                selectedIcon: Icons.home,
                                label: 'Home',
                                isSelected: initialTab == 0,
                              ),
                              const SizedBox(width: 2),
                              _buildNavItem(
                                context,
                                index: 2,
                                icon: Icons.add_circle_outline,
                                selectedIcon: Icons.add_circle,
                                label: 'Add',
                                isSelected: initialTab == 1,
                              ),
                              const SizedBox(width: 2),
                              _buildNavItem(
                                context,
                                index: 1,
                                icon: Icons.bar_chart_outlined,
                                selectedIcon: Icons.bar_chart,
                                label: 'Analytics',
                                isSelected: initialTab == 2,
                              ),
                              const SizedBox(width: 2),
                              _buildNavItem(
                                context,
                                index: 3,
                                icon: Icons.receipt_long_outlined,
                                selectedIcon: Icons.receipt_long,
                                label: 'Expenses',
                                isSelected: initialTab == 3,
                              ),
                              const SizedBox(width: 2),
                              _buildNavItem(
                                context,
                                index: 4,
                                icon: Icons.person_outline,
                                selectedIcon: Icons.person,
                                label: 'Profile',
                                isSelected: initialTab == 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
  }) {
    final colors = context.spendly.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeBgColor = isDark
        ? colors.primary.withOpacity(0.2)
        : colors.primary.withOpacity(0.12);
        
    final activeColor = colors.primary;
    final inactiveColor = isDark ? colors.neutral400 : colors.neutral500;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
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
            context.go('/expenses');
            break;
          case 4:
            context.go('/profile');
            break;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12.0 : 8.0,
          vertical: 8.0,
        ),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
