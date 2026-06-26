import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../../app/providers/app_providers.dart';

// ─────────────────────────────────────────────
// Reusable styled text field used in auth screens
// ─────────────────────────────────────────────
class CustomTextField extends ConsumerWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool isPassword;
  final bool isObscured;
  final VoidCallback? onToggleVisibility;
  final TextInputType keyboardType;
  final bool readOnly;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.isPassword = false,
    this.isObscured = false,
    this.onToggleVisibility,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(isDarkProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.profileTextD(d),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: readOnly
                ? (d ? const Color(0xFF1A263C) : const Color(0xFFF0E8EA))
                : (d ? const Color(0xFF162236) : AppColors.profilePinkFill),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.profileBorder(d)),
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            obscureText: isPassword ? isObscured : false,
            keyboardType: keyboardType,
            style: TextStyle(
              color:
                  readOnly ? AppColors.profileTextM(d) : AppColors.profileTextD(d),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  TextStyle(color: AppColors.profileTextM(d), fontSize: 14),
              prefixIcon: Icon(icon, color: AppColors.accent(d), size: 20),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isObscured ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: onToggleVisibility,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
