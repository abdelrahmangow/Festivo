import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/core/navigation/post_auth_navigation.dart';
import 'package:festivo/features/auth/services/auth_service.dart';
import 'package:festivo/features/customer/domain/customer_booking.dart';
import 'package:festivo/features/customer/domain/customer_models.dart';
import 'package:festivo/features/customer/services/venue_service.dart';
import 'package:festivo/features/customer/state/venue_providers.dart';
import 'package:festivo/features/owner/screens/owner_edit_venue_screen.dart';
import 'package:festivo/features/owner/screens/owner_venue_detail_screen.dart';
import 'package:festivo/features/owner/state/owner_providers.dart';
import 'package:festivo/features/owner/theme/owner_colors.dart';
import 'package:festivo/features/owner/widgets/owner_widgets.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  final VoidCallback? onAddTap;

  const OwnerDashboardScreen({super.key, this.onAddTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(ownerVenuesProvider);
    final bookingsAsync = ref.watch(ownerBookingsProvider);

    return Scaffold(
      backgroundColor: OwnerColors.pinkBg,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: OwnerColors.grad),
            padding: const EdgeInsets.fromLTRB(16, 52, 16, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Venue Owner',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage your venues and bookings',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                OwnerHdrPill(text: '+ Add\nVenue', onTap: onAddTap ?? () {}),
                const SizedBox(width: 8),
                OwnerHdrPill(
                  icon: Icons.logout,
                  text: 'Out',
                  onTap: () async {
                    await AuthService.instance.signOut();
                    if (!context.mounted) return;
                    navigateToLogin(context);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: venuesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: OwnerColors.pink),
              ),
              error: (e, _) => Center(
                child: Text('Could not load venues', style: TextStyle(color: OwnerColors.textGrey)),
              ),
              data: (venues) {
                final bookings = bookingsAsync.value ?? const <CustomerBooking>[];
                final confirmedRevenue = bookings
                    .where((b) =>
                        b.bookingStatus == 'Confirmed' ||
                        b.bookingStatus == 'Completed')
                    .fold<int>(0, (sum, b) => sum + b.totalAmount);
                final activeCount =
                    venues.where((v) => v.isApproved).length;
                final totalBookings = bookings
                    .where((b) => b.bookingStatus != 'Cancelled')
                    .length;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OwnerStatCard(
                              isPrimary: true,
                              icon: const Icon(
                                Icons.desktop_windows_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                              label: 'Total Venues',
                              value: '${venues.length}',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OwnerStatCard(
                              isGold: true,
                              icon: const Text(
                                'EGP',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: OwnerColors.gold,
                                ),
                              ),
                              label: 'Revenue',
                              value: '${(confirmedRevenue / 1000).toStringAsFixed(0)}K EGP',
                              valueColor: OwnerColors.gold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OwnerStatCard(
                              icon: const Icon(
                                Icons.calendar_today_outlined,
                                color: OwnerColors.blue,
                                size: 20,
                              ),
                              iconBg: OwnerColors.blueBg,
                              label: 'Bookings',
                              value: '$totalBookings',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OwnerStatCard(
                              icon: const Icon(
                                Icons.access_time,
                                color: OwnerColors.green,
                                size: 20,
                              ),
                              iconBg: OwnerColors.greenBg,
                              label: 'Approved',
                              value: '$activeCount',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'My Venues',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: OwnerColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (venues.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                              'No venues yet. Tap Add to create one.',
                              style: TextStyle(color: OwnerColors.textGrey),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ...venues.map(
                          (v) => _VenueCard(
                            venue: v,
                            onView: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OwnerVenueDetailScreen(venue: v),
                              ),
                            ),
                            onEdit: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OwnerEditVenueScreen(venue: v),
                              ),
                            ),
                            onDelete: () => _confirmDelete(context, ref, v),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Venue venue) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: OwnerColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Delete ${venue.name}?', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: OwnerColors.red),
                    onPressed: () async {
                      try {
                        await ref.read(venueServiceProvider).deleteVenue(
                              venueId: venue.id,
                              ownerId: uid,
                            );
                        if (!context.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Venue deleted.')),
                        );
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not delete venue.')),
                        );
                      }
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  final Venue venue;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VenueCard({
    required this.venue,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return OwnerCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: OwnerColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _VenueStatusBadge(status: venue.status),
                  ],
                ),
              ),
              OwnerIconBtn(
                icon: Icons.visibility_outlined,
                bg: OwnerColors.blueBg,
                fg: OwnerColors.blueIcon,
                onTap: onView,
              ),
              const SizedBox(width: 6),
              OwnerIconBtn(
                icon: Icons.edit_outlined,
                bg: OwnerColors.goldBg,
                fg: OwnerColors.gold,
                onTap: onEdit,
              ),
              const SizedBox(width: 6),
              OwnerIconBtn(
                icon: Icons.delete_outline,
                bg: OwnerColors.redBg,
                fg: OwnerColors.red,
                onTap: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Meta(label: 'Location', value: venue.location)),
              Expanded(
                child: _Meta(
                  label: 'Price',
                  value: '${venue.price} EGP',
                  valueColor: OwnerColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _Meta(label: 'Capacity', value: '${venue.capacity} guests')),
              Expanded(child: _Meta(label: 'Category', value: venue.category)),
            ],
          ),
          if (venue.isPending) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: OwnerColors.yellowBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Awaiting admin approval before customers can book.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: OwnerColors.yellow,
                ),
              ),
            ),
          ],
          if (venue.isRejected) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: OwnerColors.redBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Rejected by admin. Edit and contact support if needed.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: OwnerColors.red,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VenueStatusBadge extends StatelessWidget {
  final String status;

  const _VenueStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case Venue.statusApproved:
        return OwnerBadge.active();
      case Venue.statusRejected:
        return OwnerBadge.cancelled();
      default:
        return OwnerBadge.pending();
    }
  }
}

class _Meta extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Meta({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: OwnerColors.textGrey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? OwnerColors.textDark,
          ),
        ),
      ],
    );
  }
}
