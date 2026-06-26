import 'package:cloud_firestore/cloud_firestore.dart';

class VenueReview {
  final String id;
  final String venueId;
  final String venueName;
  final String userId;
  final String userName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const VenueReview({
    required this.id,
    required this.venueId,
    required this.venueName,
    required this.userId,
    required this.userName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory VenueReview.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return VenueReview(
      id: doc.id,
      venueId: data['venueId'] as String? ?? '',
      venueName: data['venueName'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Customer',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      comment: data['comment'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'venueId': venueId,
        'venueName': venueName,
        'userId': userId,
        'userName': userName,
        'rating': rating,
        if (comment != null && comment!.trim().isNotEmpty) 'comment': comment!.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

  /// Computes average rating (out of 5) from a list of reviews.
  static double averageRating(List<VenueReview> reviews) {
    if (reviews.isEmpty) return 0;
    final sum = reviews.fold<int>(0, (total, r) => total + r.rating);
    return sum / reviews.length;
  }

  static String formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class DuplicateReviewException implements Exception {}

class ReviewValidationException implements Exception {
  final String message;
  ReviewValidationException(this.message);
}
