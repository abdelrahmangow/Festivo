import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../models/admin_dashboard_snapshot.dart';
import '../models/stat_model.dart';
import '../state/admin_dashboard_providers.dart';
import '../state/admin_users_providers.dart';
import '../utils/relative_time.dart';
import '../widgets/stat_card.dart';
import '../widgets/activity_card.dart';
import 'package:festivo/features/customer/state/venue_providers.dart';
import '../widgets/venue_card.dart';
import '../state/admin_providers.dart';

// ─────────────────────────────────────────────
// Admin tab enum
// ─────────────────────────────────────────────
enum AdminTab { overview, users, venues }

// ─────────────────────────────────────────────
// Admin Dashboard Screen
// ─────────────────────────────────────────────
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(adminTabProvider);
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _AdminHeader(onLogOut: () => _handleLogOut(context)),
            _AdminTabBar(
              activeTab: activeTab,
              onTabChanged: (t) {
                ref.read(adminTabProvider.notifier).state = t;
              },
            ),
            Expanded(
              child: activeTab == AdminTab.overview
                  ? const _OverviewTab()
                  : activeTab == AdminTab.users
                      ? const _UsersTab()
                      : const _VenuesTab(),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await AuthService.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.softRose),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────
class _AdminHeader extends StatelessWidget {
  final VoidCallback onLogOut;
  const _AdminHeader({required this.onLogOut});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.softRose, AppColors.deepRose],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Platform management',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          _LogOutButton(onPressed: onLogOut),
          const SizedBox(width: 8),
          _NotificationsButton(),
        ],
      ),
    );
  }
}

class _LogOutButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _LogOutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.35)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.logout_rounded, size: 15, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'Log Out',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsButton extends StatelessWidget {
  const _NotificationsButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.35)),
        ),
        child: const Icon(Icons.notifications_none_rounded,
            size: 18, color: Colors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tab Bar
// ─────────────────────────────────────────────
class _AdminTabBar extends StatelessWidget {
  final AdminTab activeTab;
  final ValueChanged<AdminTab> onTabChanged;

  const _AdminTabBar({required this.activeTab, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _TabItem(
            label: 'Overview',
            isActive: activeTab == AdminTab.overview,
            onTap: () => onTabChanged(AdminTab.overview),
          ),
          _TabItem(
            label: 'Users',
            isActive: activeTab == AdminTab.users,
            onTap: () => onTabChanged(AdminTab.users),
          ),
          _TabItem(
            label: 'Venues',
            isActive: activeTab == AdminTab.venues,
            onTap: () => onTabChanged(AdminTab.venues),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? AppColors.softRose
                      : AppColors.textLight,
                ),
              ),
            ),
            Container(
              height: 2.5,
              color:
                  isActive ? AppColors.softRose : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Overview Tab
// ─────────────────────────────────────────────
class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(adminDashboardProvider);

    return dashboardAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppColors.softRose),
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.softRose, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Could not load dashboard data',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textLight),
              ),
            ],
          ),
        ),
      ),
      data: (snapshot) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatsGrid(stats: snapshot.stats),
              const SizedBox(height: 14),
              _RevenueCard(revenue: snapshot.stats.platformRevenue),
              const SizedBox(height: 22),
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              if (snapshot.activities.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'No recent activity yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textLight),
                  ),
                )
              else
                ...snapshot.activities.map(
                  (activity) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ActivityCard(item: activity),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

List<StatModel> _buildStatCards({
  required int totalUsers,
  required int totalVenues,
  required int pendingVenues,
  required int totalBookings,
}) {
  return [
    StatModel(
      label: 'Total Users',
      value: '$totalUsers',
      icon: Icons.group,
      iconColor: AppColors.borderBlue,
      borderColor: AppColors.borderBlue,
    ),
    StatModel(
      label: 'Total Venues',
      value: '$totalVenues',
      icon: Icons.account_balance,
      iconColor: AppColors.borderGreen,
      borderColor: AppColors.borderGreen,
    ),
    StatModel(
      label: 'Pending Venues',
      value: '$pendingVenues',
      icon: Icons.hourglass_top_rounded,
      iconColor: AppColors.borderOrange,
      borderColor: AppColors.borderOrange,
    ),
    StatModel(
      label: 'Total Bookings',
      value: '$totalBookings',
      icon: Icons.calendar_month_rounded,
      iconColor: AppColors.borderGold,
      borderColor: AppColors.borderGold,
    ),
  ];
}

class _StatsGrid extends StatelessWidget {
  final AdminDashboardStats stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cards = _buildStatCards(
      totalUsers: stats.totalUsers,
      totalVenues: stats.totalVenues,
      pendingVenues: stats.pendingVenues,
      totalBookings: stats.totalBookings,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (_, i) => StatCard(data: cards[i]),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final int revenue;

  const _RevenueCard({required this.revenue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.softRose, AppColors.deepRose],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.softRose.withOpacity(0.30),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Platform Revenue',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatEgpAmount(revenue),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'From confirmed & completed bookings',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'EGP',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Users Tab
// ─────────────────────────────────────────────
class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(
        child: Text('Could not load users. Please try again.'),
      ),
      data: (users) {
        if (users.isEmpty) {
          return const Center(child: Text('No users registered yet.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _UserCard(user: users[i]),
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final isOwner = user.role.toLowerCase() == 'venue_owner';
    final isSuspended = user.isSuspended;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.softRose.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: isOwner
                ? AppColors.gold.withOpacity(0.18)
                : AppColors.softRose.withOpacity(0.25),
            child: Text(
              user.initial,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: isOwner ? AppColors.gold : AppColors.deepRose,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
                if (user.phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.phone,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    _SmallBadge(
                      label: user.roleLabel,
                      bg: isOwner
                          ? AppColors.gold.withOpacity(0.15)
                          : AppColors.softRose.withOpacity(0.18),
                      color: isOwner ? AppColors.gold : AppColors.deepRose,
                    ),
                    const SizedBox(width: 6),
                    _SmallBadge(
                      label: user.statusLabel,
                      bg: isSuspended
                          ? const Color(0xFFFEE2E2)
                          : AppColors.actGreenBg,
                      color: isSuspended
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF15803D),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _SuspendButton(user: user),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color color;

  const _SmallBadge({
    required this.label,
    required this.bg,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _SuspendButton extends ConsumerStatefulWidget {
  final UserModel user;
  const _SuspendButton({required this.user});

  @override
  ConsumerState<_SuspendButton> createState() => _SuspendButtonState();
}

class _SuspendButtonState extends ConsumerState<_SuspendButton> {
  bool _updating = false;

  Future<void> _confirmSuspend() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Suspend User'),
        content: Text(
          'Are you sure you want to suspend ${widget.user.name}? '
          'They will be signed out immediately and unable to use the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.softRose),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _setSuspended(true);
  }

  Future<void> _setSuspended(bool suspend) async {
    setState(() => _updating = true);
    try {
      if (suspend) {
        await AuthService.instance.suspendUser(widget.user.uid);
      } else {
        await AuthService.instance.reactivateUser(widget.user.uid);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            suspend
                ? '${widget.user.name} has been suspended.'
                : '${widget.user.name} has been reactivated.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update user status.')),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suspended = widget.user.isSuspended;

    if (_updating) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return GestureDetector(
      onTap: suspended ? () => _setSuspended(false) : _confirmSuspend,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(
            color: suspended ? AppColors.borderGreen : AppColors.softRose,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          suspended ? 'Unsuspend' : 'Suspend',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: suspended ? AppColors.borderGreen : AppColors.softRose,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Venues Tab
// ─────────────────────────────────────────────
class _VenuesTab extends ConsumerWidget {
  const _VenuesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(adminVenuesProvider);

    return venuesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Could not load venues')),
      data: (venues) {
        if (venues.isEmpty) {
          return const Center(child: Text('No venues submitted yet.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: venues.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => VenueCard(venue: venues[i]),
        );
      },
    );
  }
}
