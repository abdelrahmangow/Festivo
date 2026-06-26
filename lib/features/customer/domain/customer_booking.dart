import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerBooking {
  final String id;
  final String userId;
  final String userName;
  final String phone;
  final String email;
  final String venueId;
  final String venueName;
  final int guestCount;
  final String packageType;
  final DateTime bookingDate;
  final String bookingTime;
  final String paymentMethod;
  final String? receiptUrl;
  final String paymentStatus;
  final String bookingStatus;
  final String ownerId;
  final int totalAmount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CustomerBooking({
    required this.id,
    required this.userId,
    required this.userName,
    required this.phone,
    required this.email,
    required this.venueId,
    required this.venueName,
    required this.guestCount,
    required this.packageType,
    required this.bookingDate,
    required this.bookingTime,
    required this.paymentMethod,
    this.receiptUrl,
    required this.paymentStatus,
    required this.bookingStatus,
    required this.ownerId,
    required this.totalAmount,
    required this.createdAt,
    this.updatedAt,
  });

  bool get canCancel =>
      bookingStatus == 'Pending' || bookingStatus == 'Confirmed';

  factory CustomerBooking.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final date = (data['bookingDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final created = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return CustomerBooking(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      venueId: data['venueId'] as String? ?? '',
      venueName: data['venueName'] as String? ?? '',
      guestCount: (data['guestCount'] as num?)?.toInt() ?? 0,
      packageType: data['packageType'] as String? ?? '',
      bookingDate: date,
      bookingTime: data['bookingTime'] as String? ?? '',
      paymentMethod: data['paymentMethod'] as String? ?? '',
      receiptUrl: data['receiptUrl'] as String?,
      paymentStatus: data['paymentStatus'] as String? ?? '',
      bookingStatus: data['bookingStatus'] as String? ?? 'Pending',
      ownerId: data['ownerId'] as String? ?? '',
      totalAmount: (data['totalAmount'] as num?)?.toInt() ?? 0,
      createdAt: created,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Maps each calendar day (yyyy-MM-dd) to booked time slots for a venue.
typedef VenueSlotMap = Map<String, Set<String>>;
