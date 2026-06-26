import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/features/customer/domain/customer_booking.dart';
import 'package:festivo/features/customer/services/booking_service.dart';

final bookingServiceProvider = Provider<BookingService>((ref) => BookingService());

final ownerBookingsProvider = StreamProvider<List<CustomerBooking>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(bookingServiceProvider).watchOwnerBookings(uid);
});

final bookingByIdProvider =
    FutureProvider.autoDispose.family<CustomerBooking?, String>((ref, bookingId) {
  if (bookingId.isEmpty) return Future.value(null);
  return ref.watch(bookingServiceProvider).getBooking(bookingId);
});
