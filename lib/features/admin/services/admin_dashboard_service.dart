import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';
import '../../customer/domain/customer_booking.dart';
import '../../customer/domain/customer_models.dart';
import '../../customer/domain/venue_review.dart';
import '../../customer/services/booking_service.dart';
import '../../customer/services/review_service.dart';
import '../../customer/services/venue_service.dart';
import '../models/admin_dashboard_snapshot.dart';
import '../utils/activity_mapper.dart';

class AdminDashboardService {
  AdminDashboardService({
    AuthService? authService,
    VenueService? venueService,
    BookingService? bookingService,
    ReviewService? reviewService,
    FirebaseFirestore? firestore,
  })  : _authService = authService ?? AuthService.instance,
        _venueService = venueService ?? VenueService(firestore: firestore),
        _bookingService = bookingService ?? BookingService(firestore: firestore),
        _reviewService = reviewService ?? ReviewService(firestore: firestore);

  final AuthService _authService;
  final VenueService _venueService;
  final BookingService _bookingService;
  final ReviewService _reviewService;

  Stream<AdminDashboardSnapshot> watchDashboard() {
    return _combineLatest(
      _authService.watchAllUsers(),
      _venueService.watchAllVenues(),
      _bookingService.watchAllBookings(),
      _reviewService.watchAllReviews(),
      _buildSnapshot,
    );
  }

  AdminDashboardSnapshot _buildSnapshot(
    List<UserModel> users,
    List<Venue> venues,
    List<CustomerBooking> bookings,
    List<VenueReview> reviews,
  ) {
    final pendingVenues = venues.where((v) => v.isPending).length;
    final platformRevenue = bookings
        .where((b) =>
            b.bookingStatus == 'Confirmed' || b.bookingStatus == 'Completed')
        .fold<int>(0, (total, b) => total + b.totalAmount);

    return AdminDashboardSnapshot(
      stats: AdminDashboardStats(
        totalUsers: users.length,
        totalVenues: venues.length,
        pendingVenues: pendingVenues,
        totalBookings: bookings.length,
        platformRevenue: platformRevenue,
      ),
      activities: buildRecentActivities(
        users: users,
        venues: venues,
        bookings: bookings,
        reviews: reviews,
      ),
    );
  }

  Stream<T> _combineLatest<T, A, B, C, D>(
    Stream<A> streamA,
    Stream<B> streamB,
    Stream<C> streamC,
    Stream<D> streamD,
    T Function(A, B, C, D) combiner,
  ) {
    late StreamSubscription<A> subA;
    late StreamSubscription<B> subB;
    late StreamSubscription<C> subC;
    late StreamSubscription<D> subD;

    A? valueA;
    B? valueB;
    C? valueC;
    D? valueD;

    final controller = StreamController<T>();

    void emitIfReady() {
      if (valueA == null || valueB == null || valueC == null || valueD == null) {
        return;
      }
      controller.add(combiner(valueA as A, valueB as B, valueC as C, valueD as D));
    }

    controller.onListen = () {
      subA = streamA.listen(
        (value) {
          valueA = value;
          emitIfReady();
        },
        onError: controller.addError,
      );
      subB = streamB.listen(
        (value) {
          valueB = value;
          emitIfReady();
        },
        onError: controller.addError,
      );
      subC = streamC.listen(
        (value) {
          valueC = value;
          emitIfReady();
        },
        onError: controller.addError,
      );
      subD = streamD.listen(
        (value) {
          valueD = value;
          emitIfReady();
        },
        onError: controller.addError,
      );
    };

    controller.onCancel = () async {
      await subA.cancel();
      await subB.cancel();
      await subC.cancel();
      await subD.cancel();
    };

    return controller.stream;
  }
}
