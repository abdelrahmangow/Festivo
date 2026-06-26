import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:festivo/core/navigation/post_auth_navigation.dart';
import 'package:festivo/features/auth/models/user_model.dart';
import 'package:festivo/features/auth/services/auth_service.dart';
import 'package:festivo/features/notifications/screens/notifications_screen.dart';
import 'package:festivo/features/owner/screens/owner_edit_profile_screen.dart';
import 'package:festivo/features/owner/theme/owner_colors.dart';
import 'package:festivo/features/owner/widgets/owner_widgets.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  UserModel? _profile;
  bool _loading = true;

  String get _name {
    final name = _profile?.name.trim();
    return (name != null && name.isNotEmpty) ? name : 'Venue Owner';
  }

  String get _email => _profile?.email ?? FirebaseAuth.instance.currentUser?.email ?? '';

  String? get _phone {
    final phone = _profile?.phone;
    if (phone == null || phone.trim().isEmpty) return null;
    return phone;
  }

  String? get _location {
    final location = _profile?.location;
    if (location == null || location.trim().isEmpty) return null;
    return location;
  }

  String? get _photoUrl => _profile?.photoUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final profile = await AuthService.instance.fetchUserProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditProfile() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const OwnerEditProfileScreen()),
    );
    if (saved == true && mounted) {
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: OwnerColors.pinkBg,
        body: Center(child: CircularProgressIndicator(color: OwnerColors.pink)),
      );
    }

    final initial = _name.isNotEmpty ? _name[0].toUpperCase() : 'V';

    return Scaffold(
      backgroundColor: OwnerColors.pinkBg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: OwnerColors.grad),
            padding: const EdgeInsets.fromLTRB(16, 52, 16, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    const Spacer(),
                    TextButton(
                      onPressed: _openEditProfile,
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: (_photoUrl != null && _photoUrl!.isNotEmpty)
                      ? NetworkImage(_photoUrl!)
                      : null,
                  child: (_photoUrl == null || _photoUrl!.isEmpty)
                      ? Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: OwnerColors.pink,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  _name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _email,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (_phone != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _phone!,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
                if (_location != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _location!,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Venue Owner',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                OwnerCard(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline, color: OwnerColors.pink),
                    title: const Text('Edit Profile'),
                    subtitle: const Text('Update your personal information'),
                    trailing: const Icon(Icons.chevron_right, color: OwnerColors.textGrey),
                    onTap: _openEditProfile,
                  ),
                ),
                const SizedBox(height: 10),
                OwnerCard(
                  child: ListTile(
                    leading: const Icon(Icons.notifications_none_rounded, color: OwnerColors.pink),
                    title: const Text('Notifications'),
                    subtitle: const Text('Booking requests and venue updates'),
                    trailing: const Icon(Icons.chevron_right, color: OwnerColors.textGrey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                OwnerCard(
                  child: ListTile(
                    leading: const Icon(Icons.help_outline, color: OwnerColors.pink),
                    title: const Text('Help & Support'),
                    subtitle: const Text('Contact Festivo support'),
                    onTap: () {},
                  ),
                ),
                const SizedBox(height: 10),
                OwnerCard(
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: OwnerColors.red),
                    title: const Text('Log Out', style: TextStyle(color: OwnerColors.red)),
                    onTap: () async {
                      await AuthService.instance.signOut();
                      if (!context.mounted) return;
                      navigateToLogin(context);
                    },
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
