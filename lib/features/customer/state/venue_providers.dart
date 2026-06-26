import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/features/customer/domain/customer_models.dart';
import 'package:festivo/features/customer/services/venue_service.dart';

final venueServiceProvider = Provider<VenueService>((ref) => VenueService());

final approvedVenuesProvider = StreamProvider<List<Venue>>((ref) {
  return ref.watch(venueServiceProvider).watchApprovedVenues();
});

final adminVenuesProvider = StreamProvider<List<Venue>>((ref) {
  return ref.watch(venueServiceProvider).watchAllVenues();
});

final ownerVenuesProvider = StreamProvider<List<Venue>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(venueServiceProvider).watchOwnerVenues(uid);
});

final pendingVenuesProvider = StreamProvider<List<Venue>>((ref) {
  return ref.watch(venueServiceProvider).watchPendingVenues();
});

final venueByIdProvider =
    StreamProvider.autoDispose.family<Venue?, String>((ref, venueId) {
  if (venueId.isEmpty) return Stream.value(null);
  return ref.watch(venueServiceProvider).watchVenue(venueId);
});
