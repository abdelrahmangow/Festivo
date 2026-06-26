import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:festivo/features/customer/domain/customer_booking.dart';

class SlotUnavailableException implements Exception {}

class BookingService {
  BookingService({FirebaseFirestore? firestore})
      : _bookings = (firestore ?? FirebaseFirestore.instance).collection('bookings');

  final CollectionReference<Map<String, dynamic>> _bookings;

  static const timeSlots = [
    '10:00 AM',
    '12:00 PM',
    '2:00 PM',
    '4:00 PM',
    '6:00 PM',
    '8:00 PM',
  ];

  static String dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  VenueSlotMap _slotsFromSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    final map = <String, Set<String>>{};
    for (final doc in snap.docs) {
      final status = doc.data()['bookingStatus'] as String? ?? '';
      if (status == 'Cancelled') continue;
      final ts = doc.data()['bookingDate'] as Timestamp?;
      final time = doc.data()['bookingTime'] as String?;
      if (ts == null || time == null) continue;
      final key = dateKey(ts.toDate());
      map.putIfAbsent(key, () => {}).add(time);
    }
    return map;
  }

  Stream<VenueSlotMap> watchVenueSlots(String venueId) {
    return _bookings
        .where('venueId', isEqualTo: venueId)
        .snapshots()
        .map(_slotsFromSnapshot);
  }

  Stream<List<CustomerBooking>> watchUserBookings(String userId) {
    return _bookings.where('userId', isEqualTo: userId).snapshots().map((snap) {
      final list = snap.docs.map(CustomerBooking.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<CustomerBooking>> watchAllBookings() {
    return _bookings.snapshots().map((snap) {
      final list = snap.docs.map(CustomerBooking.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<CustomerBooking>> watchOwnerBookings(String ownerId) {
    return _bookings.where('ownerId', isEqualTo: ownerId).snapshots().map((snap) {
      final list = snap.docs.map(CustomerBooking.fromDoc).toList();
      list.sort((a, b) {
        if (a.bookingStatus == 'Pending' && b.bookingStatus != 'Pending') {
          return -1;
        }
        if (b.bookingStatus == 'Pending' && a.bookingStatus != 'Pending') {
          return 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    });
  }

  Set<String> slotsForDate(VenueSlotMap map, DateTime date) =>
      map[dateKey(date)] ?? {};

  bool isSlotBooked(VenueSlotMap map, DateTime date, String time) =>
      slotsForDate(map, date).contains(time);

  bool isDateFullyBooked(VenueSlotMap map, DateTime date) =>
      slotsForDate(map, date).length >= timeSlots.length;

  bool hasAvailableSlot(VenueSlotMap map, DateTime date) =>
      !isDateFullyBooked(map, date);

  Future<bool> isSlotAvailable({
    required String venueId,
    required DateTime bookingDate,
    required String bookingTime,
  }) async {
    final snap = await _bookings.where('venueId', isEqualTo: venueId).get();
    final map = _slotsFromSnapshot(snap);
    return !isSlotBooked(map, bookingDate, bookingTime);
  }

  Future<String> createBooking({
    required String venueId,
    required String venueName,
    required String ownerId,
    required String userName,
    required String phone,
    required String email,
    required int guestCount,
    required String packageType,
    required DateTime bookingDate,
    required String bookingTime,
    required String paymentMethod,
    String? receiptUrl,
    required String paymentStatus,
    required int totalAmount,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not signed in');

    final available = await isSlotAvailable(
      venueId: venueId,
      bookingDate: bookingDate,
      bookingTime: bookingTime,
    );
    if (!available) throw SlotUnavailableException();

    final doc = await _bookings.add({
      'userId': user.uid,
      'userName': userName,
      'phone': phone,
      'email': email,
      'venueId': venueId,
      'venueName': venueName,
      'ownerId': ownerId,
      'guestCount': guestCount,
      'packageType': packageType,
      'bookingDate': Timestamp.fromDate(startOfDay(bookingDate)),
      'bookingTime': bookingTime,
      'paymentMethod': paymentMethod,
      'receiptUrl': receiptUrl,
      'paymentStatus': paymentStatus,
      'bookingStatus': 'Pending',
      'totalAmount': totalAmount,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> cancelBooking(String bookingId) async {
    final doc = await _bookings.doc(bookingId).get();
    if (!doc.exists) return;
    final status = doc.data()?['bookingStatus'] as String? ?? '';
    if (status == 'Completed' || status == 'Cancelled') {
      throw StateError('Booking cannot be cancelled');
    }
    await _bookings.doc(bookingId).update({
      'bookingStatus': 'Cancelled',
      'cancelledBy': 'customer',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required String ownerId,
    required String status,
  }) async {
    final doc = await _bookings.doc(bookingId).get();
    if (!doc.exists) throw StateError('Booking not found');
    final data = doc.data()!;
    if (data['ownerId'] != ownerId) throw StateError('Not authorized');

    final current = data['bookingStatus'] as String? ?? '';
    if (current != 'Pending') {
      throw StateError('Only pending bookings can be updated');
    }
    if (status != 'Confirmed' && status != 'Cancelled') {
      throw ArgumentError('Invalid status: $status');
    }
    await _bookings.doc(bookingId).update({
      'bookingStatus': status,
      if (status == 'Cancelled') 'cancelledBy': 'owner',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<CustomerBooking?> getBooking(String bookingId) async {
    if (bookingId.isEmpty) return null;
    final doc = await _bookings.doc(bookingId).get();
    if (!doc.exists) return null;
    return CustomerBooking.fromDoc(doc);
  }
}
