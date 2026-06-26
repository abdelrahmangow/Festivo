import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/app/providers/app_providers.dart';
import 'package:festivo/core/constants/app_colors.dart';
import 'package:festivo/features/customer/domain/customer_models.dart';
import 'package:festivo/features/customer/domain/venue_review.dart';
import 'package:festivo/features/customer/services/review_service.dart';
import 'package:festivo/features/customer/state/review_providers.dart';

class VenueReviewsScreen extends ConsumerWidget {
  final Venue venue;

  const VenueReviewsScreen({super.key, required this.venue});

  static void open(BuildContext context, Venue venue) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VenueReviewsScreen(venue: venue)),
    );
  }

  void _openWriteReviewSheet(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to leave a review.')),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WriteReviewSheet(venue: venue),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(isDarkProvider);
    final reviewsAsync = ref.watch(venueReviewsProvider(venue.id));

    return Scaffold(
      backgroundColor: AppColors.bg(dark),
      appBar: AppBar(
        backgroundColor: AppColors.bg(dark),
        elevation: 0,
        title: Text('Reviews', style: TextStyle(color: AppColors.textD(dark))),
        iconTheme: IconThemeData(color: AppColors.textD(dark)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openWriteReviewSheet(context, ref),
        backgroundColor: AppColors.accent(dark),
        icon: const Icon(Icons.rate_review_outlined, color: Colors.white),
        label: const Text(
          'Write Review',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: reviewsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.accent(dark)),
        ),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.textL(dark)),
                const SizedBox(height: 12),
                Text(
                  'Could not load reviews.',
                  style: TextStyle(color: AppColors.textM(dark)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(venueReviewsProvider(venue.id)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent(dark),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (reviews) {
          final average = VenueReview.averageRating(reviews);
          final count = reviews.length;
          final averageLabel = count == 0 ? '0' : average.toStringAsFixed(1);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              _SummaryCard(
                dark: dark,
                average: average,
                averageLabel: averageLabel,
                count: count,
              ),
              const SizedBox(height: 16),
              if (reviews.isEmpty)
                _EmptyReviews(dark: dark)
              else
                ...reviews.map((r) => _ReviewCard(dark: dark, review: r)),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final bool dark;
  final double average;
  final String averageLabel;
  final int count;

  const _SummaryCard({
    required this.dark,
    required this.average,
    required this.averageLabel,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card(dark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppColors.shadow(dark)],
      ),
      child: Row(
        children: [
          Text(
            averageLabel,
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: AppColors.textD(dark),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '/ 5',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textL(dark),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StarRow(rating: average, size: 20),
                const SizedBox(height: 4),
                Text(
                  count == 1 ? '1 review' : '$count reviews',
                  style: TextStyle(color: AppColors.textM(dark)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final double rating;
  final double size;

  const _StarRow({required this.rating, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final starValue = i + 1;
        IconData icon;
        if (rating >= starValue) {
          icon = Icons.star;
        } else if (rating >= starValue - 0.5) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }
        return Icon(icon, color: AppColors.gold, size: size);
      }),
    );
  }
}

class _EmptyReviews extends StatelessWidget {
  final bool dark;

  const _EmptyReviews({required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.card(dark),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [AppColors.shadow(dark)],
      ),
      child: Column(
        children: [
          Icon(Icons.reviews_outlined, size: 48, color: AppColors.textL(dark)),
          const SizedBox(height: 12),
          Text(
            'No reviews yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textD(dark),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Be the first to share your experience!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textM(dark)),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final bool dark;
  final VenueReview review;

  const _ReviewCard({required this.dark, required this.review});

  @override
  Widget build(BuildContext context) {
    final initial = review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'C';
    final hasComment = review.comment != null && review.comment!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(dark),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [AppColors.shadow(dark)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.accent(dark).withOpacity(0.2),
                child: Text(
                  initial,
                  style: TextStyle(
                    color: AppColors.accent(dark),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textD(dark),
                      ),
                    ),
                    Text(
                      VenueReview.formatDate(review.createdAt),
                      style: TextStyle(fontSize: 12, color: AppColors.textL(dark)),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    review.rating.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.star, color: AppColors.gold, size: 16),
                ],
              ),
            ],
          ),
          if (hasComment) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: TextStyle(color: AppColors.textM(dark), height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _WriteReviewSheet extends ConsumerStatefulWidget {
  final Venue venue;

  const _WriteReviewSheet({required this.venue});

  @override
  ConsumerState<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<_WriteReviewSheet> {
  final _commentCtrl = TextEditingController();
  int _rating = 0;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1) {
      setState(() => _error = 'Please select a star rating.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(reviewServiceProvider).createReview(
            venueId: widget.venue.id,
            venueName: widget.venue.name,
            rating: _rating,
            comment: _commentCtrl.text,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully.')),
      );
    } on DuplicateReviewException {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'You have already reviewed this venue.';
      });
    } on ReviewValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Could not submit review. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = ref.watch(isDarkProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card(dark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border(dark),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Write a Review',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textD(dark),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.venue.name,
              style: TextStyle(color: AppColors.textM(dark)),
            ),
            const SizedBox(height: 20),
            Text(
              'Your rating *',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textD(dark),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return IconButton(
                  onPressed: _submitting
                      ? null
                      : () => setState(() {
                            _rating = star;
                            _error = null;
                          }),
                  icon: Icon(
                    star <= _rating ? Icons.star : Icons.star_border,
                    color: AppColors.gold,
                    size: 36,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _commentCtrl,
              enabled: !_submitting,
              maxLines: 4,
              style: TextStyle(color: AppColors.textD(dark)),
              decoration: InputDecoration(
                labelText: 'Comment (optional)',
                alignLabelWithHint: true,
                filled: true,
                fillColor: AppColors.bg(dark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border(dark)),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(color: dark ? Colors.redAccent : Colors.red[700]),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent(dark),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Review',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
