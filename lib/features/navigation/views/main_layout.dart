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

class PersistentStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const PersistentStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  State<PersistentStack> createState() => _PersistentStackState();
}

class _PersistentStackState extends State<PersistentStack> {
  late final List<bool> _visited;

  @override
  void initState() {
    super.initState();
    _visited = List.generate(widget.children.length, (i) => i == widget.index);
  }

  @override
  void didUpdateWidget(PersistentStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_visited[widget.index]) {
      setState(() {
        _visited[widget.index] = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: List.generate(widget.children.length, (i) {
        if (_visited[i]) {
          return RepaintBoundary(
            key: ValueKey('persistent_branch_$i'),
            child: widget.children[i],
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }
}


