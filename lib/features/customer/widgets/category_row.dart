import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/core/constants/app_colors.dart';
import 'package:festivo/features/customer/domain/customer_models.dart';
import 'package:festivo/features/customer/state/customer_home_controller.dart';

class CategoryRow extends ConsumerWidget {
  final bool isDark;
  final String selected;

  const CategoryRow({super.key, required this.isDark, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = isDark;
    return Container(
      color: AppColors.bg(d),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
        child: Row(
          children: kCategories.map((cat) {
            final active = selected == cat.label;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => ref
                    .read(customerHomeControllerProvider.notifier)
                    .setCategory(cat.label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: active ? AppColors.accent(d) : AppColors.card(d),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color:
                          active ? AppColors.accent(d) : AppColors.border(d),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(cat.emoji, style: const TextStyle(fontSize: 15)),
                      const SizedBox(width: 6),
                      Text(
                        cat.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.white : AppColors.textM(d),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

