import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/app/providers/app_providers.dart';
import 'package:festivo/core/constants/app_colors.dart';
import 'package:festivo/core/notifications/notification_navigation.dart';
import 'package:festivo/core/notifications/notification_types.dart';
import 'package:festivo/features/customer/screens/customer_profile_subpages.dart';
import 'package:festivo/features/customer/screens/venue_details_screen.dart';
import 'package:festivo/features/customer/state/venue_providers.dart';
import 'package:festivo/features/notifications/models/app_notification.dart';
import 'package:festivo/features/notifications/services/notification_service.dart';
import 'package:festivo/features/notifications/state/notification_providers.dart';
import 'package:festivo/features/owner/screens/owner_booking_details_screen.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool? _notificationsEnabled;
  NotificationPermissionStatus? _permissionStatus;
  bool _updatingPreference = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final enabled = doc.data()?['notificationsEnabled'] as bool? ?? true;
      if (!mounted) return;
      setState(() {
        _notificationsEnabled = enabled;
        _permissionStatus = enabled
            ? NotificationPermissionStatus.granted
            : NotificationPermissionStatus.denied;
      });
    } catch (error) {
      NotificationService.log('Failed to load notification prefs: $error');
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _updatingPreference = true);

    try {
      if (enabled) {
        final result =
            await ref.read(notificationServiceProvider).registerForUser(uid);
        if (!mounted) return;
        setState(() {
          _permissionStatus = result.permission;
          _notificationsEnabled = result.success;
        });
        if (!result.success) {
          _showPermissionDeniedSnackBar();
        }
      } else {
        await ref
            .read(notificationHistoryServiceProvider)
            .setNotificationsEnabled(userId: uid, enabled: false);
        if (!mounted) return;
        setState(() => _notificationsEnabled = false);
      }
    } finally {
      if (mounted) setState(() => _updatingPreference = false);
    }
  }

  void _showPermissionDeniedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Notifications are disabled in system settings. Enable them to receive alerts.',
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _openNotification(AppNotification notification) async {
    if (!notification.read) {
      await ref
          .read(notificationHistoryServiceProvider)
          .markAsRead(notification.id);
    }

    if (!mounted) return;
    NotificationNavigation.handle(notification.data);

    final type = notification.type;
    final bookingId = notification.data['bookingId'] ?? '';
    final venueId = notification.data['venueId'] ?? '';

    if (type == NotificationTypes.bookingNewRequest ||
        type == NotificationTypes.bookingCancelled) {
      if (bookingId.isNotEmpty) {
        OwnerBookingDetailsScreen.open(context, bookingId: bookingId);
      }
      return;
    }

    if (venueId.isNotEmpty &&
        (type == NotificationTypes.bookingSubmitted ||
            type == NotificationTypes.bookingApproved ||
            type == NotificationTypes.bookingRejected ||
            type == NotificationTypes.bookingReminder)) {
      final venue = await ref.read(venueServiceProvider).getVenue(venueId);
      if (venue != null && mounted) {
        VenueDetailsScreen.open(context, venue);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final dark = ref.watch(isDarkProvider);
    final notificationsAsync = ref.watch(userNotificationsProvider(uid));

    return ProfileSubPage(
      title: 'Notifications',
      subtitle: 'Manage your alerts',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_permissionStatus == NotificationPermissionStatus.denied)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8A87C)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.notifications_off_outlined,
                        color: Color(0xFFE8A87C)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Push notifications are off. Enable them in your device settings to stay updated.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            _sectionLabel('PREFERENCES', dark),
            const SizedBox(height: 10),
            _card(
              dark,
              child: SwitchListTile(
                title: Text(
                  'Push Notifications',
                  style: TextStyle(color: AppColors.profileTextD(dark)),
                ),
                subtitle: Text(
                  'Receive booking updates and reminders',
                  style: TextStyle(
                    color: AppColors.profileTextM(dark),
                    fontSize: 12,
                  ),
                ),
                value: _notificationsEnabled ?? true,
                onChanged: _updatingPreference ? null : _toggleNotifications,
                activeColor: AppColors.accent(dark),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _sectionLabel('RECENT', dark)),
                TextButton(
                  onPressed: uid.isEmpty
                      ? null
                      : () => ref
                          .read(notificationHistoryServiceProvider)
                          .markAllAsRead(uid),
                  child: Text(
                    'Mark all read',
                    style: TextStyle(color: AppColors.accent(dark)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            notificationsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => Text(
                'Could not load notifications.',
                style: TextStyle(color: AppColors.profileTextM(dark)),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return _card(
                    dark,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No notifications yet.',
                          style: TextStyle(
                            color: AppColors.profileTextM(dark),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: items
                      .map((n) => _notifCard(n, dark, () => _openNotification(n)))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, bool dark) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.profileTextM(dark),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _card(bool dark, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.profileCard(dark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppColors.shadow(dark)],
      ),
      child: child,
    );
  }

  Widget _notifCard(
    AppNotification notification,
    bool dark,
    VoidCallback onTap,
  ) {
    final visual = _visualForType(notification.type);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.profileCard(dark),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [AppColors.shadow(dark)],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: visual.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(visual.icon, color: visual.iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      color: AppColors.profileTextD(dark),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    notification.body,
                    style: TextStyle(
                      color: AppColors.profileTextM(dark),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _formatTime(notification.createdAt),
                    style: TextStyle(
                      color: AppColors.profileTextM(dark),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.read)
              const CircleAvatar(
                radius: 5,
                backgroundColor: Color(0xFFE8A87C),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  _NotifVisual _visualForType(String type) {
    switch (type) {
      case NotificationTypes.bookingApproved:
      case NotificationTypes.venueApproved:
        return const _NotifVisual(
          Icons.check_circle_rounded,
          Color(0xFFD4F0DF),
          Color(0xFF4CAF50),
        );
      case NotificationTypes.bookingRejected:
      case NotificationTypes.venueRejected:
      case NotificationTypes.bookingCancelled:
        return const _NotifVisual(
          Icons.cancel_rounded,
          Color(0xFFFFE0E0),
          Color(0xFFE57373),
        );
      case NotificationTypes.bookingReminder:
        return const _NotifVisual(
          Icons.alarm_rounded,
          Color(0xFFFFF3CD),
          Color(0xFFE8A87C),
        );
      case NotificationTypes.reviewSubmitted:
        return const _NotifVisual(
          Icons.star_rounded,
          Color(0xFFFFF8E1),
          Color(0xFFFFB300),
        );
      case NotificationTypes.venueSubmitted:
        return const _NotifVisual(
          Icons.pending_actions_rounded,
          Color(0xFFDDE8FF),
          Color(0xFF7B9FD4),
        );
      default:
        return const _NotifVisual(
          Icons.notifications_rounded,
          Color(0xFFDDE8FF),
          Color(0xFF7B9FD4),
        );
    }
  }
}

class _NotifVisual {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _NotifVisual(this.icon, this.iconBg, this.iconColor);
}
