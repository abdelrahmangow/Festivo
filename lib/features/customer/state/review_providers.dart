import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/features/customer/domain/venue_review.dart';
import 'package:festivo/features/customer/services/review_service.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) => ReviewService());

final venueReviewsProvider =
    StreamProvider.autoDispose.family<List<VenueReview>, String>((ref, venueId) {
  if (venueId.isEmpty) return Stream.value(const []);
  return ref.watch(reviewServiceProvider).watchVenueReviews(venueId);
});
