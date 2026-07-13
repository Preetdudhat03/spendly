import 'dart:ui';
import 'package:flutter/material.dart';

class PremiumFloatingDock extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const PremiumFloatingDock({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  State<PremiumFloatingDock> createState() => _PremiumFloatingDockState();
}

class _PremiumFloatingDockState extends State<PremiumFloatingDock> with TickerProviderStateMixin {
  late AnimationController _fabScaleController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _fabScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _fabScaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabScaleController.dispose();
    super.dispose();
  }

  // Map absolute index to dock positions:
  // Position 0: Home (index 0)
  // Position 1: Analytics (index 2)
  // Position 2: Add (index 1) - FAB
  // Position 3: Profile (index 3)
  int _indexToPosition(int index) {
    switch (index) {
      case 0:
        return 0;
      case 2:
        return 1;
      case 1:
        return 2;
      case 3:
        return 3;
      default:
        return 0;
    }
  }

  double _getAlignX(int position) {
    switch (position) {
      case 0:
        return -0.9;
      case 1:
        return -0.35;
      case 2:
        return 0.35;
      case 3:
        return 0.9;
      default:
        return -0.9;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final primaryColor = theme.primaryColor;
    
    // Background and border colors matching theme
    final dockBgColor = isDark 
        ? const Color(0xFF1E293B).withOpacity(0.85)
        : Colors.white.withOpacity(0.85);
    final borderColor = isDark 
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);
    final shadowColor = isDark 
        ? Colors.black.withOpacity(0.4) 
        : Colors.black.withOpacity(0.05);

    final activePosition = _indexToPosition(widget.selectedIndex);
    final showTabIndicator = widget.selectedIndex != 1; // Hide indicator when FAB is active

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: dockBgColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              // 70px FAB space, leaves (width - 70) for 3 tabs
              final tabWidth = (width - 70) / 3;

              return Stack(
                children: [
                  // Sliding Active Indicator
                  if (showTabIndicator)
                    AnimatedAlign(
                      alignment: Alignment(_getAlignX(activePosition), 0.0),
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOutCubic,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Container(
                          width: tabWidth - 12,
                          height: 48,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Tab Items Row
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          // Home
                          Expanded(
                            child: _buildTabItem(
                              position: 0,
                              targetIndex: 0,
                              icon: Icons.home_rounded,
                              label: 'Home',
                              isActive: widget.selectedIndex == 0,
                            ),
                          ),
                          // Analytics
                          Expanded(
                            child: _buildTabItem(
                              position: 1,
                              targetIndex: 2,
                              icon: Icons.bar_chart_rounded,
                              label: 'Analytics',
                              isActive: widget.selectedIndex == 2,
                            ),
                          ),
                          // FAB (Add Expense)
                          SizedBox(
                            width: 70,
                            child: Center(
                              child: _buildFAB(widget.selectedIndex == 1),
                            ),
                          ),
                          // Profile
                          Expanded(
                            child: _buildTabItem(
                              position: 3,
                              targetIndex: 3,
                              icon: Icons.person_rounded,
                              label: 'Profile',
                              isActive: widget.selectedIndex == 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int position,
    required int targetIndex,
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeColor = Colors.white;
    final inactiveColor = isDark ? Colors.white70 : Colors.black54;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onTabSelected(targetIndex),
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: isActive ? activeColor : inactiveColor,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 11,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.bottom(2),
                child: Icon(
                  icon,
                  color: isActive ? activeColor : inactiveColor.withOpacity(0.6),
                  size: isActive ? 24 : 22,
                ),
              ),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAB(bool isActive) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return GestureDetector(
      onTapDown: (_) => _fabScaleController.forward(),
      onTapUp: (_) {
        _fabScaleController.reverse();
        widget.onTabSelected(1);
      },
      onTapCancel: () => _fabScaleController.reverse(),
      child: ScaleTransition(
        scale: _fabScaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? primaryColor : primaryColor.withOpacity(0.9),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(isActive ? 0.5 : 0.3),
                blurRadius: isActive ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
