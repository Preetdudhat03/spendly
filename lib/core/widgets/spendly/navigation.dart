import 'package:flutter/material.dart';
import 'package:spendly/core/theme/spendly_tokens.dart';

class SpendlyNavigationDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const SpendlyNavigationDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class SpendlyFloatingNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<SpendlyNavigationDestination> destinations;

  const SpendlyFloatingNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final spendly = context.spendly;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF111827) : Colors.white;
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);

    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.fromLTRB(spendly.spacing.x5, 0, spendly.spacing.x5, spendly.spacing.x4),
        height: 68,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: spendly.radius.xxlarge,
          border: Border.all(color: borderCol, width: 1.2),
          boxShadow: spendly.elevation.surface2,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: spendly.spacing.x3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(destinations.length, (index) {
              final dest = destinations[index];
              final isSelected = selectedIndex == index;

              return InkWell(
                onTap: () => onDestinationSelected(index),
                borderRadius: BorderRadius.circular(24),
                child: AnimatedContainer(
                  duration: spendly.animation.fast,
                  padding: EdgeInsets.symmetric(
                    vertical: spendly.spacing.x2,
                    horizontal: spendly.spacing.x4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? spendly.colors.primary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? dest.selectedIcon : dest.icon,
                        color: isSelected ? spendly.colors.primary : spendly.colors.neutral400,
                        size: 24,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dest.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? spendly.colors.primary : spendly.colors.neutral400,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
