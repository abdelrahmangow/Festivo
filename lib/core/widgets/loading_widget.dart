import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../../app/providers/app_providers.dart';

// ─────────────────────────────────────────────
// Centered loading indicator that respects dark mode
// ─────────────────────────────────────────────
class LoadingWidget extends ConsumerWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(isDarkProvider);
    return Center(
      child: CircularProgressIndicator(
        color: AppColors.accent(d),
      ),
    );
  }
}
