import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/features/expenses/views/home_screen.dart';
import 'package:spendly/features/expenses/views/add_expense_screen.dart';
import 'package:spendly/features/analytics/presentation/pages/analytics_page.dart';
import 'package:spendly/features/expenses/views/all_expenses_screen.dart';
import 'package:spendly/features/profile/views/profile_screen.dart';
import 'package:spendly/features/navigation/views/widgets/floating_spendly_navigation_bar.dart';

class MainLayout extends ConsumerStatefulWidget {
  final int initialTab;

  const MainLayout({super.key, required this.initialTab});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _lastTab = 0;

  @override
  void initState() {
    super.initState();
    _lastTab = widget.initialTab;
  }

  @override
  void didUpdateWidget(MainLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _lastTab = oldWidget.initialTab;
    }
  }

  int getVisualIndex(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 0; // Home
      case 2:
        return 1; // Analytics
      case 3:
        return 3; // Expenses
      case 4:
        return 4; // Profile
      case 1:
        return 2; // Add
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              if (isWide)
                NavigationRail(
                  selectedIndex: getVisualIndex(widget.initialTab),
                  onDestinationSelected: (index) {
                    switch (index) {
                      case 0:
                        context.go('/home');
                        break;
                      case 1:
                        context.go('/analytics');
                        break;
                      case 2:
                        context.go('/add');
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
                      icon: Icon(Icons.bar_chart_outlined),
                      selectedIcon: Icon(Icons.bar_chart, color: Colors.white),
                      label: Text('Analytics'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.add_circle_outline),
                      selectedIcon: Icon(Icons.add_circle, color: Colors.white),
                      label: Text('Add'),
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
                child: _FadeIndexedStack(
                  index: widget.initialTab,
                  lastIndex: _lastTab,
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
                bottom: true,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FloatingSpendlyNavigationBar(
                    currentTab: widget.initialTab,
                    onTabSelected: (index) {
                      switch (index) {
                        case 0:
                          context.go('/home');
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
                    onAddTap: () {
                      context.go('/add');
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FadeIndexedStack extends StatefulWidget {
  final int index;
  final int lastIndex;
  final List<Widget> children;

  const _FadeIndexedStack({
    required this.index,
    required this.lastIndex,
    required this.children,
  });

  @override
  State<_FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<_FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(_FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _getVisualOrderIndex(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 0; // Home
      case 2:
        return 1; // Analytics
      case 1:
        return 2; // Add
      case 3:
        return 3; // Expenses
      case 4:
        return 4; // Profile
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
   /* final lastVisualIndex = _getVisualOrderIndex(widget.lastIndex);
    final currentVisualIndex = _getVisualOrderIndex(widget.index);
    final isForward = currentVisualIndex >= lastVisualIndex;

    return Stack(
      children: List.generate(widget.children.length, (i) {
        final isCurrent = i == widget.index;
        final isLast = i == widget.lastIndex;

        if (!isCurrent && !isLast) {
          return Offstage(
            offstage: true,
            child: widget.children[i],
          );
        }

        final child = widget.children[i];

        if (isCurrent) {
          final slideOffset = isForward ? const Offset(0.06, 0.0) : const Offset(-0.06, 0.0);
          final slide = Tween<Offset>(
            begin: slideOffset,
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic,
          ));

          return SlideTransition(
            position: slide,
            child: FadeTransition(
              opacity: _controller,
              child: child,
            ),
          );
        } else {
          final slideOffset = isForward ? const Offset(-0.06, 0.0) : const Offset(0.06, 0.0);
          final slide = Tween<Offset>(
            begin: Offset.zero,
            end: slideOffset,
          ).animate(CurvedAnimation(
            parent: _controller,
            curve: Curves.easeInCubic,
          ));

          final fade = Tween<double>(
            begin: 1.0,
            end: 0.0,
          ).animate(CurvedAnimation(
            parent: _controller,
            curve: Curves.easeInCubic,
          ));

          return SlideTransition(
            position: slide,
            child: FadeTransition(
              opacity: fade,
              child: IgnorePointer(
                child: child,
              ),
            ),
          );
        }
      }),
    );*/





    return Scaffold(
      body: Stack(
        children: [
          // 1. The main content screens
          _FadeIndexedStack(
            index: widget.initialTab,
            lastIndex: _lastTab,
            children: const [
              HomeScreen(),
              AddExpenseScreen(),
              AnalyticsPage(),
              AllExpensesScreen(),
              ProfileScreen(),
            ],
          ),
          
          // 2. The Floating Navigation Bar (Now shows unconditionally on all screen sizes)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24), // Added a bit more padding so it floats nicely
                child: FloatingSpendlyNavigationBar(
                  currentTab: widget.initialTab,
                  onTabSelected: (index) {
                    switch (index) {
                      case 0:
                        context.go('/home');
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
                  onAddTap: () {
                    context.go('/add');
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  
  }
}
