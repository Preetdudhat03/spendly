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

class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late int _lastIndex;

  @override
  void initState() {
    super.initState();
    _lastIndex = widget.index;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _lastIndex = oldWidget.index;
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
    final lastVisualIndex = _getVisualOrderIndex(_lastIndex);
    final currentVisualIndex = _getVisualOrderIndex(widget.index);
    final isForward = currentVisualIndex >= lastVisualIndex;

    return Stack(
      children: List.generate(widget.children.length, (i) {
        final isCurrent = i == widget.index;
        final isLast = i == _lastIndex;

        if (!isCurrent && !isLast) {
          return Offstage(
            offstage: true,
            child: widget.children[i],
          );
        }

        final child = RepaintBoundary(
          child: widget.children[i],
        );

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
    );
  }
}
