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
    // Generate children with keys to maintain their state properly in the Stack
    final childrenWithKeys = List.generate(children.length, (i) {
      return KeyedSubtree(
        key: ValueKey(i),
        child: children[i],
      );
    });

    final inactiveChildren = <Widget>[];
    for (int i = 0; i < childrenWithKeys.length; i++) {
      if (i != index) {
        inactiveChildren.add(
          Positioned.fill(
            child: TickerMode(
              enabled: false,
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: childrenWithKeys[i],
                ),
              ),
            ),
          ),
        );
      }
    }

    return Stack(
      children: [
        // 1. Render all inactive tabs at the absolute bottom.
        // They will be fully painted and rasterized (cached in memory) but hidden.
        ...inactiveChildren,

        // 2. An opaque barrier to prevent inactive tabs from bleeding through 
        // if the active tab has any transparent areas.
        Positioned.fill(
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),

        // 3. The active tab on top.
        Positioned.fill(
          child: RepaintBoundary(
            child: childrenWithKeys[index],
          ),
        ),
      ],
    );
  }
}


