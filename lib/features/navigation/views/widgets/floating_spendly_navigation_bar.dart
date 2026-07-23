import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spendly/core/theme/spendly_tokens.dart';

class FloatingSpendlyNavigationBar extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddTap;

  const FloatingSpendlyNavigationBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.spendly.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware colors
    final pillBgColor = isDark
        ? colors.neutral900.withOpacity(0.85)
        : Colors.white.withOpacity(0.88);

    final borderColor = isDark
        ? colors.neutral800.withOpacity(0.5)
        : colors.neutral200.withOpacity(0.6);

    final shadowColor = isDark
        ? Colors.black.withOpacity(0.4)
        : Colors.black.withOpacity(0.08);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Main Navigation Pill Container
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: pillBgColor,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: borderColor,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildNavItem(
                          context,
                          index: 0,
                          label: 'Home',
                          iconPath: 'assets/icons/home.svg',
                          isSelected: currentTab == 0,
                        ),
                        const SizedBox(width: 4),
                        _buildNavItem(
                          context,
                          index: 2,
                          label: 'Analytics',
                          iconPath: 'assets/icons/chart.svg',
                          isSelected: currentTab == 2,
                        ),
                        const SizedBox(width: 4),
                        _buildNavItem(
                          context,
                          index: 4,
                          label: 'Profile',
                          iconPath: 'assets/icons/user.svg',
                          isSelected: currentTab == 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Floating Circular Add Button
            _AddExpenseFloatingButton(
              onTap: onAddTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required String label,
    required String iconPath,
    required bool isSelected,
  }) {
    final colors = context.spendly.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeBgColor = isDark
        ? colors.primary.withOpacity(0.20)
        : colors.primary.withOpacity(0.12);

    final activeColor = colors.primary;
    final inactiveColor = isDark ? colors.neutral400 : colors.neutral500;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTabSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16.0 : 12.0,
          vertical: 10.0,
        ),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(
                isSelected ? activeColor : inactiveColor,
                BlendMode.srcIn,
              ),
            ),
            AnimatedCrossFade(
              firstChild: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: activeColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              secondChild: const SizedBox.shrink(),
              crossFadeState: isSelected
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 220),
              sizeCurve: Curves.easeInOutCubic,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddExpenseFloatingButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AddExpenseFloatingButton({required this.onTap});

  @override
  State<_AddExpenseFloatingButton> createState() =>
      __AddExpenseFloatingButtonState();
}

class __AddExpenseFloatingButtonState
    extends State<_AddExpenseFloatingButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse().then((_) {
      widget.onTap();
    });
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.spendly.colors;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.primary,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/plus.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
