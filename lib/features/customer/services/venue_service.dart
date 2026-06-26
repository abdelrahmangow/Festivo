import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:festivo/features/customer/domain/customer_models.dart';

class VenueService {
  VenueService({FirebaseFirestore? firestore})
      : _venues = (firestore ?? FirebaseFirestore.instance).collection('venues');

  final CollectionReference<Map<String, dynamic>> _venues;

  Stream<List<Venue>> watchApprovedVenues() {
    return _venues
        .where('status', isEqualTo: Venue.statusApproved)
        .snapshots()
        .map(_mapAndSort);
  }

  Stream<List<Venue>> watchOwnerVenues(String ownerId) {
    return _venues
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map(_mapAndSort);
  }

  Stream<List<Venue>> watchAllVenues() {
    return _venues.snapshots().map(_mapAndSort);
  }

  Stream<List<Venue>> watchPendingVenues() {
    return _venues
        .where('status', isEqualTo: Venue.statusPending)
        .snapshots()
        .map(_mapAndSort);
  }

  List<Venue> _mapAndSort(QuerySnapshot<Map<String, dynamic>> snap) {
    final list = snap.docs.map(Venue.fromDoc).toList();
    list.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return list;
  }

  Future<Venue?> getVenue(String venueId) async {
    final doc = await _venues.doc(venueId).get();
    if (!doc.exists) return null;
    return Venue.fromDoc(doc);
  }

  Stream<Venue?> watchVenue(String venueId) {
    return _venues.doc(venueId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Venue.fromDoc(doc);
    });
  }

  Future<String> createVenue({
    required String name,
    required String location,
    required String category,
    required int price,
    required int capacity,
    String description = '',
    List<String> amenities = const [],
    List<String> imageUrls = const [],
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not signed in');

    final ownerName = await _resolveOwnerName(user.uid, user.displayName);

    final doc = await _venues.add({
      'ownerId': user.uid,
      'ownerName': ownerName,
      'name': name,
      'location': location,
      'category': category,
      'emoji': emojiForCategory(category),
      'price': price,
      'rating': 0,
      'reviews': 0,
      'capacity': capacity,
      'description': description,
      'amenities': amenities,
      'imageUrls': imageUrls,
      'status': Venue.statusPending,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateVenue({
    required String venueId,
    required String ownerId,
    required String name,
    required String location,
    required String category,
    required int price,
    required int capacity,
    String description = '',
    List<String> amenities = const [],
    List<String>? imageUrls,
  }) async {
    final doc = await _venues.doc(venueId).get();
    if (!doc.exists) throw StateError('Venue not found');
    final data = doc.data()!;
    if (data['ownerId'] != ownerId) throw StateError('Not authorized');

    await _venues.doc(venueId).update({
      'name': name,
      'location': location,
      'category': category,
      'emoji': emojiForCategory(category),
      'price': price,
      'capacity': capacity,
      'description': description,
      'amenities': amenities,
      if (imageUrls != null) 'imageUrls': imageUrls,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteVenue({
    required String venueId,
    required String ownerId,
  }) async {
    final doc = await _venues.doc(venueId).get();
    if (!doc.exists) return;
    if (doc.data()?['ownerId'] != ownerId) throw StateError('Not authorized');
    await _venues.doc(venueId).delete();
  }

  Future<void> updateApprovalStatus({
    required String venueId,
    required String status,
  }) async {
    if (status != Venue.statusApproved &&
        status != Venue.statusRejected &&
        status != Venue.statusPending) {
      throw ArgumentError('Invalid status: $status');
    }
    await _venues.doc(venueId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> _resolveOwnerName(String uid, String? displayName) async {
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final name = userDoc.data()?['name'] as String?;
      if (name != null && name.trim().isNotEmpty) return name.trim();
    } catch (_) {}
    return 'Venue Owner';
  }
}
