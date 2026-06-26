import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/core/constants/app_strings.dart';
import 'package:festivo/features/customer/domain/customer_booking.dart';
import 'package:festivo/features/owner/state/owner_providers.dart';
import 'package:festivo/features/owner/theme/owner_colors.dart';
import 'package:festivo/features/owner/widgets/owner_widgets.dart';

class OwnerBookingDetailsScreen extends ConsumerWidget {
  final String bookingId;

  const OwnerBookingDetailsScreen({super.key, required this.bookingId});

  static void open(BuildContext context, {required String bookingId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerBookingDetailsScreen(bookingId: bookingId),
      ),
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(CustomerBooking booking) {
    final d = booking.bookingDate;
    final weekday =
        const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
    return '$weekday, ${_months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatCreatedAt(DateTime date) {
    return '${_months[date.month - 1]} ${date.day}, ${date.year} '
        'at ${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingByIdProvider(bookingId));

    return Scaffold(
      backgroundColor: OwnerColors.pinkBg,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.bookingDetails, style: TextStyle(fontSize: 18)),
            Text(
              AppStrings.bookingDetailsSub,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: OwnerColors.pink,
        foregroundColor: Colors.white,
      ),
      body: bookingAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: OwnerColors.pink),
        ),
        error: (_, __) => _ErrorState(
          message: AppStrings.couldNotLoadBooking,
          onRetry: () => ref.invalidate(bookingByIdProvider(bookingId)),
        ),
        data: (booking) {
          if (booking == null) {
            return _ErrorState(
              message: AppStrings.bookingNotFound,
              onRetry: () => ref.invalidate(bookingByIdProvider(bookingId)),
            );
          }
          return _BookingBody(
            booking: booking,
            dateLabel: _formatDate(booking),
            createdLabel: _formatCreatedAt(booking.createdAt),
          );
        },
      ),
    );
  }
}

class _BookingBody extends StatelessWidget {
  final CustomerBooking booking;
  final String dateLabel;
  final String createdLabel;

  const _BookingBody({
    required this.booking,
    required this.dateLabel,
    required this.createdLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OwnerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.venueName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: OwnerColors.textDark,
                      ),
                    ),
                  ),
                  _statusBadge(booking.bookingStatus),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow(Icons.person_outline_rounded, 'Customer', booking.userName),
              _detailRow(Icons.event_outlined, 'Date', dateLabel),
              _detailRow(Icons.access_time_outlined, 'Time', booking.bookingTime),
              _detailRow(Icons.people_outline_rounded, 'Guests', '${booking.guestCount}'),
              _detailRow(Icons.inventory_2_outlined, 'Package', booking.packageType),
              _detailRow(Icons.payments_outlined, 'Payment Method', booking.paymentMethod),
              _detailRow(Icons.receipt_long_outlined, 'Payment Status', booking.paymentStatus),
              _detailRow(Icons.paid_outlined, 'Total Amount', '${booking.totalAmount} EGP'),
              _detailRow(Icons.schedule_outlined, 'Booked On', createdLabel),
              if (booking.receiptUrl != null && booking.receiptUrl!.isNotEmpty)
                _detailRow(Icons.attach_file_outlined, 'Receipt', 'Uploaded'),
            ],
          ),
        ),
      ],
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

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: OwnerColors.pinkBorder,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: OwnerColors.pink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: OwnerColors.textGrey)),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : AppStrings.notAvailable,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: value.isNotEmpty ? OwnerColors.textDark : OwnerColors.textGrey,
                    fontStyle: value.isEmpty ? FontStyle.italic : FontStyle.normal,
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
