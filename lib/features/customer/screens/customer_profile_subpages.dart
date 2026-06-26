import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/app/providers/app_providers.dart';
import 'package:festivo/core/constants/app_colors.dart';
import 'package:festivo/features/customer/domain/payment_methods.dart';

class ProfileSubPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget body;

  const ProfileSubPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final dark = ref.watch(isDarkProvider);
        return Scaffold(
          backgroundColor: AppColors.profileBg(dark),
          appBar: AppBar(
            backgroundColor: AppColors.profileBg(dark),
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: AppColors.profileTextD(dark), fontSize: 18)),
                Text(subtitle, style: TextStyle(color: AppColors.profileTextM(dark), fontSize: 12)),
              ],
            ),
            iconTheme: IconThemeData(color: AppColors.profileTextD(dark)),
          ),
          body: body,
        );
      },
    );
  }
}

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return ProfileSubPage(
      title: 'Payment Methods',
      subtitle: 'Choose your preferred method',
      body: Consumer(
        builder: (context, ref, _) {
          final dark = ref.watch(isDarkProvider);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...List.generate(kPaymentMethods.length, (i) {
                final m = kPaymentMethods[i];
                final sel = _selected == i;
                return GestureDetector(
                  onTap: () => setState(() => _selected = i),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.profileCard(dark),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel ? AppColors.accent(dark) : AppColors.profileBorder(dark),
                        width: sel ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: m.iconBg, borderRadius: BorderRadius.circular(12)),
                          child: Icon(m.icon, color: m.iconColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.title, style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.profileTextD(dark))),
                              Text(m.subtitle, style: TextStyle(fontSize: 12, color: AppColors.profileTextM(dark))),
                            ],
                          ),
                        ),
                        Icon(
                          sel ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: sel ? AppColors.accent(dark) : AppColors.profileTextM(dark),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class PrivacySecurityPage extends StatelessWidget {
  const PrivacySecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileSubPage(
      title: 'Privacy & Security',
      subtitle: 'Account controls',
      body: Consumer(
        builder: (context, ref, _) {
          final dark = ref.watch(isDarkProvider);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _tile(dark, Icons.lock_outline, 'Change Password', 'Update your login password'),
              _tile(dark, Icons.fingerprint, 'Biometric Login', 'Use fingerprint or face ID'),
              _tile(dark, Icons.visibility_off_outlined, 'Profile Visibility', 'Control who sees your profile'),
              _tile(dark, Icons.delete_outline, 'Delete Account', 'Permanently remove your account', danger: true),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(bool dark, IconData icon, String title, String subtitle, {bool danger = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.profileCard(dark),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [AppColors.shadow(dark)],
      ),
      child: ListTile(
        leading: Icon(icon, color: danger ? Colors.red : AppColors.accent(dark)),
        title: Text(title, style: TextStyle(color: danger ? Colors.red : AppColors.profileTextD(dark))),
        subtitle: Text(subtitle, style: TextStyle(color: AppColors.profileTextM(dark), fontSize: 12)),
        trailing: Icon(Icons.chevron_right, color: AppColors.profileTextM(dark)),
        onTap: () {},
      ),
    );
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(isDarkProvider);
    return ProfileSubPage(
      title: 'Settings',
      subtitle: 'App preferences',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.profileCard(dark),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [AppColors.shadow(dark)],
            ),
            child: SwitchListTile(
              title: Text('Dark Mode', style: TextStyle(color: AppColors.profileTextD(dark))),
              subtitle: Text('Switch to dark color theme', style: TextStyle(color: AppColors.profileTextM(dark))),
              value: dark,
              activeColor: AppColors.accent(dark),
              onChanged: (v) => ref.read(isDarkProvider.notifier).state = v,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.profileCard(dark),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              title: Text('Language', style: TextStyle(color: AppColors.profileTextD(dark))),
              subtitle: Text('English', style: TextStyle(color: AppColors.profileTextM(dark))),
              trailing: Icon(Icons.chevron_right, color: AppColors.profileTextM(dark)),
            ),
          ),
        ],
      ),
    );
  }
}

class LegalDocPage extends StatelessWidget {
  final String title;
  final String body;

  const LegalDocPage({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return ProfileSubPage(
      title: title,
      subtitle: 'Legal information',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(body, style: const TextStyle(height: 1.6)),
      ),
    );
  }
}
