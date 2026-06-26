import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:festivo/features/customer/domain/venue_review.dart';

class ReviewService {
  ReviewService({FirebaseFirestore? firestore})
      : _reviews = (firestore ?? FirebaseFirestore.instance).collection('reviews'),
        _venues = (firestore ?? FirebaseFirestore.instance).collection('venues');

  final CollectionReference<Map<String, dynamic>> _reviews;
  final CollectionReference<Map<String, dynamic>> _venues;

  Stream<List<VenueReview>> watchAllReviews() {
    return _reviews.snapshots().map((snap) {
      final list = snap.docs.map(VenueReview.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<VenueReview>> watchVenueReviews(String venueId) {
    return _reviews.where('venueId', isEqualTo: venueId).snapshots().map((snap) {
      final list = snap.docs.map(VenueReview.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<bool> hasUserReviewed({
    required String venueId,
    required String userId,
  }) async {
    if (venueId.isEmpty || userId.isEmpty) return false;
    final snap = await _reviews.where('venueId', isEqualTo: venueId).get();
    return snap.docs.any((doc) => doc.data()['userId'] == userId);
  }

  Future<String> createReview({
    required String venueId,
    required String venueName,
    required int rating,
    String? comment,
  }) async {
    if (rating < 1 || rating > 5) {
      throw ReviewValidationException('Rating must be between 1 and 5.');
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not signed in');

    final alreadyReviewed = await hasUserReviewed(venueId: venueId, userId: user.uid);
    if (alreadyReviewed) throw DuplicateReviewException();

    final userName = await _resolveUserName(user.uid, user.displayName);

    final review = VenueReview(
      id: '',
      venueId: venueId,
      venueName: venueName,
      userId: user.uid,
      userName: userName,
      rating: rating,
      comment: comment?.trim().isNotEmpty == true ? comment!.trim() : null,
      createdAt: DateTime.now(),
    );

    final doc = await _reviews.add(review.toMap());
    await _syncVenueAggregates(venueId);
    return doc.id;
  }

  Future<void> _syncVenueAggregates(String venueId) async {
    final snap = await _reviews.where('venueId', isEqualTo: venueId).get();
    final reviews = snap.docs.map(VenueReview.fromDoc).toList();
    final count = reviews.length;
    final average = VenueReview.averageRating(reviews);

    await _venues.doc(venueId).update({
      'rating': double.parse(average.toStringAsFixed(1)),
      'reviews': count,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> _resolveUserName(String uid, String? displayName) async {
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final name = userDoc.data()?['name'] as String?;
      if (name != null && name.trim().isNotEmpty) return name.trim();
    } catch (_) {}
    return 'Customer';
  }
}
