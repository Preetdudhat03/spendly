import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/features/expenses/widgets/expense_detail_modal.dart';

class QuickCategoryCarousel extends ConsumerWidget {
  const QuickCategoryCarousel({super.key});

  static const List<Map<String, String>> categories = [
    {'name': 'Food', 'icon': 'assets/category/food.svg'},
    {'name': 'Petrol', 'icon': 'assets/category/fuel.svg'},
    {'name': 'Groceries', 'icon': 'assets/category/groceries.svg'},
    {'name': 'Electricity', 'icon': 'assets/category/electricity.svg'},
    {'name': 'Medical', 'icon': 'assets/category/medical.svg'},
    {'name': 'Recharges', 'icon': 'assets/category/recharge.svg'},
    {'name': 'Shopping', 'icon': 'assets/category/shopping.svg'},
    {'name': 'Travel', 'icon': 'assets/category/travel.svg'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Add Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 98,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final name = cat['name']!;
              final iconPath = cat['icon']!;
              final catColor = getCategoryColor(name);

              return Container(
                width: 78,
                margin: const EdgeInsets.only(right: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ref.read(selectedCategoryProvider.notifier).state = name;
                      context.go('/add');
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color ?? colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? colorScheme.outline.withValues(alpha: 0.4)
                              : colorScheme.outline.withValues(alpha: 0.8),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.15)
                                : colorScheme.shadow.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: SvgPicture.asset(
                              iconPath,
                              colorFilter: ColorFilter.mode(catColor, BlendMode.srcIn),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
