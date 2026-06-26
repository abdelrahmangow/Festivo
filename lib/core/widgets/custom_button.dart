import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../../app/providers/app_providers.dart';

// ─────────────────────────────────────────────
// Reusable pink/accent full-width button
// ─────────────────────────────────────────────
class CustomButton extends ConsumerWidget {
  final String label;
  final VoidCallback onTap;
  final bool outlined;

  const CustomButton({
    super.key,
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(isDarkProvider);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : AppColors.accent(d),
          borderRadius: BorderRadius.circular(14),
          border: outlined ? Border.all(color: AppColors.accent(d)) : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: outlined ? AppColors.accent(d) : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
