import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/app/providers/app_providers.dart';
import 'package:festivo/core/constants/app_colors.dart';
import 'package:festivo/core/navigation/post_auth_navigation.dart';
import 'package:festivo/features/auth/services/auth_service.dart';
import 'package:festivo/features/notifications/screens/notifications_screen.dart';
import 'package:festivo/features/customer/screens/customer_profile_subpages.dart';
import 'package:festivo/features/customer/screens/edit_profile_screen.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  String _name = 'User';
  String _email = '';
  String _phone = '';
  String _location = 'Cairo, Egypt';
  String? _photoUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (!mounted) return;
      setState(() {
        _name = (data?['name'] as String?)?.trim().isNotEmpty == true
            ? (data!['name'] as String)
            : 'User';
        _email = (data?['email'] as String?) ?? user.email ?? '';
        _phone = (data?['phone'] as String?) ?? '';
        _location = (data?['location'] as String?) ?? 'Cairo, Egypt';
        _photoUrl = data?['photoUrl'] as String?;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditProfile() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (saved == true && mounted) {
      await _loadProfile();
    }
  }

  Future<void> _logout() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await AuthService.instance.signOut();
    } else {
      await FirebaseAuth.instance.signOut();
    }
    if (!mounted) return;
    navigateToLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    final dark = ref.watch(isDarkProvider);
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.accent(dark)),
      );
    }

    final initial = _name.isNotEmpty ? _name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppColors.profileBg(dark),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accent(dark), AppColors.accent2(dark)],
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              bottom: 20,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      (_photoUrl != null && _photoUrl!.isNotEmpty)
                      ? NetworkImage(_photoUrl!)
                      : null,
                  child: (_photoUrl == null || _photoUrl!.isEmpty)
                      ? Text(
                          initial,
                          style: TextStyle(
                            color: AppColors.accent(dark),
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _email,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Customer Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _openEditProfile,
                  child: const Text(
                    'Edit',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                children: [
                  _MenuTile(
                    dark: dark,
                    title: 'Edit Profile',
                    subtitle: 'Update personal information',
                    icon: Icons.person_outline_rounded,
                    onTap: _openEditProfile,
                  ),
                  _MenuTile(
                    dark: dark,
                    title: 'Notifications',
                    subtitle: 'Manage alerts and preferences',
                    icon: Icons.notifications_none_rounded,
                    onTap: () => _pushPage(const NotificationsScreen()),
                  ),
                  _MenuTile(
                    dark: dark,
                    title: 'Payment Methods',
                    subtitle: 'Cash, Vodafone Cash, InstaPay',
                    icon: Icons.credit_card_rounded,
                    onTap: () => _pushPage(const PaymentMethodsPage()),
                  ),
                  _MenuTile(
                    dark: dark,
                    title: 'Privacy & Security',
                    subtitle: 'Password and account controls',
                    icon: Icons.shield_outlined,
                    onTap: () => _pushPage(const PrivacySecurityPage()),
                  ),
                  _MenuTile(
                    dark: dark,
                    title: 'Settings',
                    subtitle: 'Theme and app preferences',
                    icon: Icons.tune_rounded,
                    onTap: () => _pushPage(const SettingsPage()),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _logout,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.profileCard(dark),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.profileBorder(dark)),
                        boxShadow: [AppColors.shadow(dark)],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: dark ? Colors.redAccent : AppColors.profileRed,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Log Out',
                            style: TextStyle(
                              color: dark ? Colors.redAccent : AppColors.profileRed,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pushPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

class _MenuTile extends StatelessWidget {
  final bool dark;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuTile({
    required this.dark,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.profileCard(dark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppColors.shadow(dark)],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.accent(dark)),
        title: Text(title, style: TextStyle(color: AppColors.profileTextD(dark))),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppColors.profileTextM(dark)),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: AppColors.profileTextM(dark),
        ),
      ),
    );
  }
}
