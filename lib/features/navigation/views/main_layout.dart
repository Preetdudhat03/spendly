import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';
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

    // We filter the actual tab content. If initialTab is 1 (the 'Add' tab),
    // we display HomeScreen or similar or keep Add screen in IndexedStack.
    // However, since the design puts "+" on the right of the bar as a separate button,
    // let's map initialTab to the 3 main options:
    // Index 0: Home
    // Index 1: Add Expense (shown inside stack, or triggered)
    // Index 2: Analytics
    // Index 3: Profile
    // The design has 4 items in the navigation bar container in the mockup:
    // Left-to-right: Home, Calendar/Stats, Trophy, Profile, and then '+' button.
    // Let's adapt our 4 main tabs to map to the items:
    // In our app we have: Home, Analytics (represented by chart/trophy), Profile.
    // Let's make the nav bar contain:
    // 0: Home (IconlyLight.home / IconlyBold.home)
    // 1: Analytics (IconlyLight.chart / IconlyBold.chart)
    // 2: Profile (IconlyLight.profile / IconlyBold.profile)
    // Plus button on the right triggers navigation to Add Expense.
    
    // We adjust current navigation selection mapping:
    int activeNavItem = 0;
    if (initialTab == 0) activeNavItem = 0;
    if (initialTab == 2) activeNavItem = 1;
    if (initialTab == 3) activeNavItem = 2;

    void onNavItemTap(int index) {
      if (index == 0) context.go('/home');
      if (index == 1) context.go('/analytics');
      if (index == 2) context.go('/profile');
    }

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: activeNavItem,
              onDestinationSelected: onNavItemTap,
              labelType: NavigationRailLabelType.all,
              indicatorColor: theme.primaryColor,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(IconlyLight.home),
                  selectedIcon: Icon(IconlyBold.home, color: Colors.white),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(IconlyLight.chart),
                  selectedIcon: Icon(IconlyBold.chart, color: Colors.white),
                  label: Text('Analytics'),
                ),
                NavigationRailDestination(
                  icon: Icon(IconlyLight.profile),
                  selectedIcon: Icon(IconlyBold.profile, color: Colors.white),
                  label: Text('Profile'),
                ),
              ],
              trailing: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: FloatingActionButton(
                  onPressed: () => context.go('/add'),
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add, size: 28),
                ),
              ),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    // Main navigation pills container
                    Expanded(
                      child: Container(
                        height: 70,
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(35),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildBottomNavItem(
                              context: context,
                              isActive: activeNavItem == 0,
                              activeIcon: IconlyBold.home,
                              inactiveIcon: IconlyLight.home,
                              label: 'Home',
                              onTap: () => onNavItemTap(0),
                            ),
                            _buildBottomNavItem(
                              context: context,
                              isActive: activeNavItem == 1,
                              activeIcon: IconlyBold.chart,
                              inactiveIcon: IconlyLight.chart,
                              label: 'Stats',
                              onTap: () => onNavItemTap(1),
                            ),
                            _buildBottomNavItem(
                              context: context,
                              isActive: activeNavItem == 2,
                              activeIcon: IconlyBold.profile,
                              inactiveIcon: IconlyLight.profile,
                              label: 'Profile',
                              onTap: () => onNavItemTap(2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Floating black circular + button
                    GestureDetector(
                      onTap: () => context.go('/add'),
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : Colors.black,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add,
                          color: isDark ? Colors.black : Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBottomNavItem({
    required BuildContext context,
    required bool isActive,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isActive 
              ? (isDark ? Colors.grey[800] : Colors.grey[300]) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              color: isActive 
                  ? (isDark ? Colors.white : Colors.black) 
                  : Colors.grey[600],
              size: 24,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
