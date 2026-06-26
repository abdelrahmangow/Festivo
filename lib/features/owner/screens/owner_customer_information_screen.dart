import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/core/constants/app_strings.dart';
import 'package:festivo/features/auth/models/user_model.dart';
import 'package:festivo/features/customer/state/customer_user_providers.dart';
import 'package:festivo/features/owner/theme/owner_colors.dart';
import 'package:festivo/features/owner/widgets/owner_widgets.dart';

class OwnerCustomerInformationScreen extends ConsumerWidget {
  final String userId;
  final String? venueName;

  const OwnerCustomerInformationScreen({
    super.key,
    required this.userId,
    this.venueName,
  });

  static void open(
    BuildContext context, {
    required String userId,
    String? venueName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerCustomerInformationScreen(
          userId: userId,
          venueName: venueName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(userByIdProvider(userId));

    return Scaffold(
      backgroundColor: OwnerColors.pinkBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.customerInformation, style: TextStyle(fontSize: 18)),
            Text(
              venueName ?? AppStrings.customerContactSub,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: OwnerColors.pink,
        foregroundColor: Colors.white,
      ),
      body: customerAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: OwnerColors.pink),
        ),
        error: (_, __) => _ErrorState(
          message: AppStrings.couldNotLoadCustomer,
          onRetry: () => ref.invalidate(userByIdProvider(userId)),
        ),
        data: (customer) {
          if (customer == null) {
            return _ErrorState(
              message: AppStrings.customerNotFound,
              onRetry: () => ref.invalidate(userByIdProvider(userId)),
            );
          }
          return _CustomerBody(customer: customer);
        },
      ),
    );
  }
}

class _CustomerBody extends StatelessWidget {
  final UserModel customer;

  const _CustomerBody({required this.customer});

  @override
  Widget build(BuildContext context) {
    final name = customer.name.trim().isNotEmpty ? customer.name.trim() : null;
    final phone = customer.phone.trim().isNotEmpty ? customer.phone.trim() : null;
    final email = customer.email.trim().isNotEmpty ? customer.email.trim() : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: OwnerColors.pinkBorder,
            child: Text(
              customer.initial,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: OwnerColors.textDark,
              ),
            ),
          ),
          if (name != null) ...[
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: OwnerColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          _ContactCard(
            icon: Icons.person_outline_rounded,
            label: AppStrings.fullName,
            value: name ?? AppStrings.notAvailable,
            missing: name == null,
          ),
          const SizedBox(height: 12),
          _ContactCard(
            icon: Icons.phone_outlined,
            label: AppStrings.phoneNumber,
            value: phone ?? AppStrings.notAvailable,
            missing: phone == null,
          ),
          const SizedBox(height: 12),
          _ContactCard(
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
  final IconData icon;
  final String label;
  final String value;
  final bool missing;

  const _ContactCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.missing,
  });

  @override
  Widget build(BuildContext context) {
    return OwnerCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: OwnerColors.pinkBorder,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: OwnerColors.pink, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: OwnerColors.textGrey)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: missing ? OwnerColors.textGrey : OwnerColors.textDark,
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
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: OwnerColors.textGrey),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: OwnerColors.textMid, fontSize: 15),
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
