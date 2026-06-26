import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/app/providers/app_providers.dart';
import 'package:festivo/core/constants/app_colors.dart';
import 'package:festivo/core/constants/app_strings.dart';
import 'package:festivo/features/customer/domain/customer_booking.dart';
import 'package:festivo/features/customer/screens/owner_information_screen.dart';
import 'package:festivo/features/customer/screens/venue_details_screen.dart';
import 'package:festivo/features/customer/services/booking_service.dart';
import 'package:festivo/features/customer/state/venue_providers.dart';

class CustomerBookingsScreen extends ConsumerStatefulWidget {
  const CustomerBookingsScreen({super.key});

  @override
  ConsumerState<CustomerBookingsScreen> createState() =>
      _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends ConsumerState<CustomerBookingsScreen> {
  final _bookingService = BookingService();
  String? _cancellingId;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(CustomerBooking b) {
    final d = b.bookingDate;
    final weekday = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
    return '$weekday, ${_months[d.month - 1]} ${d.day}, ${d.year} • ${b.bookingTime}';
  }

  Future<void> _cancelBooking(CustomerBooking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: Text(
          'Cancel your booking at ${booking.venueName} on ${_formatDate(booking)}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancellingId = booking.id);
    try {
      await _bookingService.cancelBooking(booking.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not cancel this booking.')),
      );
    } finally {
      if (mounted) setState(() => _cancellingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = ref.watch(isDarkProvider);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.bg(dark),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [AppColors.shadow(dark)],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        'assets/logo.jpeg',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Center(
                          child: Text('🎉', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.myBookings,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textD(dark),
                        ),
                      ),
                      Text(
                        AppStrings.manageReserv,
                        style: TextStyle(fontSize: 14, color: AppColors.textM(dark)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: user == null
                  ? Center(
                      child: Text(
                        'Sign in to view your bookings.',
                        style: TextStyle(color: AppColors.textM(dark)),
                      ),
                    )
                  : StreamBuilder<List<CustomerBooking>>(
                      stream: _bookingService.watchUserBookings(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(color: AppColors.accent(dark)),
                          );
                        }
                        final bookings = snapshot.data ?? [];
                        if (bookings.isEmpty) {
                          return Center(
                            child: Text(
                              'No bookings yet.',
                              style: TextStyle(color: AppColors.textM(dark)),
                            ),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: bookings.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 16),
                          itemBuilder: (_, i) {
                            final b = bookings[i];
                            return _BookingCard(
                              booking: b,
                              dateLabel: _formatDate(b),
                              dark: dark,
                              isCancelling: _cancellingId == b.id,
                              onCancel: b.canCancel ? () => _cancelBooking(b) : null,
                            );
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends ConsumerStatefulWidget {
  final CustomerBooking booking;
  final String dateLabel;
  final bool dark;
  final bool isCancelling;
  final VoidCallback? onCancel;

  const _BookingCard({
    required this.booking,
    required this.dateLabel,
    required this.dark,
    required this.isCancelling,
    this.onCancel,
  });

  @override
  ConsumerState<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends ConsumerState<_BookingCard> {
  bool _loadingVenue = false;

  Future<void> _openVenueDetails() async {
    if (_loadingVenue) return;
    setState(() => _loadingVenue = true);
    try {
      final venue = await ref
          .read(venueServiceProvider)
          .getVenue(widget.booking.venueId);
      if (!mounted) return;
      if (venue == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.venueNotFound)),
        );
        return;
      }
      VenueDetailsScreen.open(context, venue);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.couldNotLoadVenue)),
      );
    } finally {
      if (mounted) setState(() => _loadingVenue = false);
    }
  }

  void _openOwnerInfo() {
    OwnerInformationScreen.open(
      context,
      ownerId: widget.booking.ownerId,
      venueName: widget.booking.venueName,
    );
  }

  bool get _isConfirmed => widget.booking.bookingStatus == 'Confirmed';

  Color get _statusBg {
    if (widget.booking.bookingStatus == 'Cancelled') {
      return const Color(0xFFFFEBEE);
    }
    return _isConfirmed ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1);
  }

  Color get _statusFg {
    if (widget.booking.bookingStatus == 'Cancelled') {
      return const Color(0xFFC62828);
    }
    return _isConfirmed ? const Color(0xFF2E7D32) : const Color(0xFFF57F17);
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final dark = widget.dark;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(dark),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [AppColors.shadow(dark)],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  booking.venueName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textD(dark),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  booking.bookingStatus,
                  style: TextStyle(
                    color: _statusFg,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.softRose,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              booking.packageType,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Guests: ${booking.guestCount}',
            style: TextStyle(color: AppColors.textM(dark)),
          ),
          const SizedBox(height: 10),
          Text(widget.dateLabel, style: TextStyle(color: AppColors.textM(dark))),
          const SizedBox(height: 6),
          Text(
            'Payment: ${booking.paymentMethod} · ${booking.paymentStatus}',
            style: TextStyle(color: AppColors.textM(dark), fontSize: 13),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loadingVenue ? null : _openVenueDetails,
              icon: _loadingVenue
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent(dark),
                      ),
                    )
                  : Icon(Icons.storefront_outlined, size: 18, color: AppColors.accent(dark)),
              label: Text(
                AppStrings.viewVenueDetails,
                style: TextStyle(color: AppColors.textD(dark)),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: AppColors.gborder),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openOwnerInfo,
              icon: Icon(Icons.person_outline_rounded, size: 18, color: AppColors.accent(dark)),
              label: Text(
                AppStrings.viewOwnerInfo,
                style: TextStyle(color: AppColors.textD(dark)),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: AppColors.gborder),
              ),
            ),
          ),
          if (widget.onCancel != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: widget.isCancelling ? null : widget.onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                ),
                child: widget.isCancelling
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Cancel Booking'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
