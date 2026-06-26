import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/core/constants/app_strings.dart';
import 'package:festivo/features/customer/domain/customer_booking.dart';
import 'package:festivo/features/owner/screens/owner_booking_details_screen.dart';
import 'package:festivo/features/owner/screens/owner_customer_information_screen.dart';
import 'package:festivo/features/owner/state/owner_providers.dart';
import 'package:festivo/features/owner/theme/owner_colors.dart';
import 'package:festivo/features/owner/widgets/owner_widgets.dart';

class OwnerBookingsScreen extends ConsumerWidget {
  const OwnerBookingsScreen({super.key});

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(CustomerBooking booking) {
    final d = booking.bookingDate;
    final weekday =
        const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
    return '$weekday, ${_months[d.month - 1]} ${d.day}, ${d.year} • ${booking.bookingTime}';
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    CustomerBooking booking,
    String status,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await ref.read(bookingServiceProvider).updateBookingStatus(
            bookingId: booking.id,
            ownerId: uid,
            status: status,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'Confirmed'
                ? 'Booking confirmed.'
                : 'Booking rejected.',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update booking.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(ownerBookingsProvider);

    return Scaffold(
      backgroundColor: OwnerColors.pinkBg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: OwnerColors.grad),
            padding: const EdgeInsets.fromLTRB(16, 52, 16, 20),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Requests',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Review and respond to customer booking requests',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: bookingsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: OwnerColors.pink),
              ),
              error: (_, __) => const Center(
                child: Text(
                  'Could not load bookings',
                  style: TextStyle(color: OwnerColors.textGrey),
                ),
              ),
              data: (bookings) {
                if (bookings.isEmpty) {
                  return const Center(
                    child: Text(
                      'No booking requests yet.',
                      style: TextStyle(color: OwnerColors.textGrey),
                    ),
                  );
                }

                final pending =
                    bookings.where((b) => b.bookingStatus == 'Pending').toList();
                final others =
                    bookings.where((b) => b.bookingStatus != 'Pending').toList();

                return ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    if (pending.isNotEmpty) ...[
                      const Text(
                        'Pending Requests',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: OwnerColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...pending.map(
                        (b) => _BookingCard(
                          booking: b,
                          dateLabel: _formatDate(b),
                          showActions: true,
                          onApprove: () =>
                              _updateStatus(context, ref, b, 'Confirmed'),
                          onReject: () =>
                              _updateStatus(context, ref, b, 'Cancelled'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (others.isNotEmpty) ...[
                      const Text(
                        'All Bookings',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: OwnerColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...others.map(
                        (b) => _BookingCard(
                          booking: b,
                          dateLabel: _formatDate(b),
                          showActions: false,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final CustomerBooking booking;
  final String dateLabel;
  final bool showActions;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _BookingCard({
    required this.booking,
    required this.dateLabel,
    required this.showActions,
    this.onApprove,
    this.onReject,
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
                child: Text(
                  booking.venueName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: OwnerColors.textDark,
                  ),
                ),
              ),
              _statusBadge(booking.bookingStatus),
            ],
          ),
          const SizedBox(height: 8),
          Text(booking.userName, style: const TextStyle(color: OwnerColors.textMid)),
          Text(
            booking.phone,
            style: const TextStyle(fontSize: 12, color: OwnerColors.textGrey),
          ),
          Text(
            dateLabel,
            style: const TextStyle(fontSize: 12, color: OwnerColors.textGrey),
          ),
          const SizedBox(height: 8),
          Text(
            '${booking.totalAmount} EGP · ${booking.guestCount} guests · ${booking.packageType}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: OwnerColors.gold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => OwnerBookingDetailsScreen.open(
                context,
                bookingId: booking.id,
              ),
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: const Text(AppStrings.viewBookingDetails),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: OwnerColors.textDark,
                side: const BorderSide(color: OwnerColors.pinkBorder),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => OwnerCustomerInformationScreen.open(
                context,
                userId: booking.userId,
                venueName: booking.venueName,
              ),
              icon: const Icon(Icons.person_outline_rounded, size: 18),
              label: const Text(AppStrings.viewCustomerInfo),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: OwnerColors.textDark,
                side: const BorderSide(color: OwnerColors.pinkBorder),
              ),
            ),
          ),
          if (showActions) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OwnerColors.pink,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onApprove,
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    switch (status) {
      case 'Confirmed':
        return OwnerBadge.confirmed();
      case 'Pending':
        return OwnerBadge.pending();
      case 'Completed':
        return OwnerBadge.completed();
      case 'Cancelled':
        return OwnerBadge.cancelled();
      default:
        return OwnerBadge.pending();
    }
  }
}
