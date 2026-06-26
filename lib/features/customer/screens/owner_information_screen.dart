import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/app/providers/app_providers.dart';
import 'package:festivo/core/constants/app_colors.dart';
import 'package:festivo/core/constants/app_strings.dart';
import 'package:festivo/features/auth/models/user_model.dart';
import 'package:festivo/features/customer/screens/customer_profile_subpages.dart';
import 'package:festivo/features/customer/state/customer_user_providers.dart';

class OwnerInformationScreen extends ConsumerWidget {
  final String ownerId;
  final String? venueName;

  const OwnerInformationScreen({
    super.key,
    required this.ownerId,
    this.venueName,
  });

  static void open(
    BuildContext context, {
    required String ownerId,
    String? venueName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerInformationScreen(
          ownerId: ownerId,
          venueName: venueName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(isDarkProvider);
    final ownerAsync = ref.watch(userByIdProvider(ownerId));

    return ProfileSubPage(
      title: AppStrings.ownerInformation,
      subtitle: venueName ?? AppStrings.ownerContactSub,
      body: ownerAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.accent(dark)),
        ),
        error: (_, __) => _ErrorState(
          dark: dark,
          message: AppStrings.couldNotLoadOwner,
          onRetry: () => ref.invalidate(userByIdProvider(ownerId)),
        ),
        data: (owner) {
          if (owner == null) {
            return _ErrorState(
              dark: dark,
              message: AppStrings.ownerNotFound,
              onRetry: () => ref.invalidate(userByIdProvider(ownerId)),
            );
          }
          return _OwnerBody(owner: owner, dark: dark);
        },
      ),
    );
  }
}

class _OwnerBody extends StatelessWidget {
  final UserModel owner;
  final bool dark;

  const _OwnerBody({required this.owner, required this.dark});

  @override
  Widget build(BuildContext context) {
    final name = owner.name.trim().isNotEmpty ? owner.name.trim() : null;
    final phone = owner.phone.trim().isNotEmpty ? owner.phone.trim() : null;
    final email = owner.email.trim().isNotEmpty ? owner.email.trim() : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.softRose.withValues(alpha: 0.25),
            child: Text(
              owner.initial,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textD(dark),
              ),
            ),
          ),
          if (name != null) ...[
            const SizedBox(height: 16),
            Text(
              name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textD(dark),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          _ContactCard(
            dark: dark,
            icon: Icons.person_outline_rounded,
            label: AppStrings.fullName,
            value: name ?? AppStrings.notAvailable,
            missing: name == null,
          ),
          const SizedBox(height: 12),
          _ContactCard(
            dark: dark,
            icon: Icons.phone_outlined,
            label: AppStrings.phoneNumber,
            value: phone ?? AppStrings.notAvailable,
            missing: phone == null,
          ),
          const SizedBox(height: 12),
          _ContactCard(
            dark: dark,
            icon: Icons.email_outlined,
            label: AppStrings.emailAddress,
            value: email ?? AppStrings.notAvailable,
            missing: email == null,
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final bool dark;
  final IconData icon;
  final String label;
  final String value;
  final bool missing;

  const _ContactCard({
    required this.dark,
    required this.icon,
    required this.label,
    required this.value,
    required this.missing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(dark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppColors.shadow(dark)],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.softRose.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.softRose, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textM(dark),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: missing
                        ? AppColors.textL(dark)
                        : AppColors.textD(dark),
                    fontStyle: missing ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final bool dark;
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.dark,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textM(dark)),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: AppColors.textM(dark), fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
