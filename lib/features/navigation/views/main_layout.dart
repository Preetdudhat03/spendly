import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/features/navigation/views/widgets/floating_spendly_navigation_bar.dart';

class MainLayout extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. The main content screens provided by GoRouter's StatefulShellRoute
          navigationShell,
          
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
                  currentTab: navigationShell.currentIndex,
                  onTabSelected: (index) {
                    // Navigate to the branch for the selected index
                    navigationShell.goBranch(
                      index,
                      initialLocation: index == navigationShell.currentIndex,
                    );
                  },
                  onAddTap: () {
                    // Navigate to the add expense branch (index 1)
                    navigationShell.goBranch(
                      1,
                      initialLocation: 1 == navigationShell.currentIndex,
                    );
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

class PersistentStack extends StatelessWidget {
  final int index;
  final List<Widget> children;

  const PersistentStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(children.length, (i) {
        final isCurrent = i == index;
        
        return Positioned.fill(
          // Static key ensures Flutter never unmounts this branch
          key: ValueKey('persistent_branch_$i'),
          child: TickerMode(
            // Disable animations when not active
            enabled: isCurrent,
            child: IgnorePointer(
              // Prevent touches from hitting inactive layers
              ignoring: !isCurrent,
              child: RepaintBoundary(
                // Cache the heavy widget tree (SVGs, Charts) to GPU memory
                child: Opacity(
                  // 1.0 is fully visible. 
                  // 0.001 forces Flutter to paint and cache it, but it's invisible to the eye.
                  // This completely avoids the layout/paint freeze of Offstage.
                  opacity: isCurrent ? 1.0 : 0.001,
                  child: children[i],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}


