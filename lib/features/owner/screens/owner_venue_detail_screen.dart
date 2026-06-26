import 'package:flutter/material.dart';

import 'package:festivo/features/customer/domain/customer_models.dart';
import 'package:festivo/features/customer/widgets/venue_image_carousel.dart';
import 'package:festivo/features/owner/theme/owner_colors.dart';
import 'package:festivo/features/owner/widgets/owner_widgets.dart';

class OwnerVenueDetailScreen extends StatelessWidget {
  final Venue venue;

  const OwnerVenueDetailScreen({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(venue.name),
        backgroundColor: OwnerColors.pink,
        foregroundColor: Colors.white,
      ),
      backgroundColor: OwnerColors.pinkBg,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: VenueImageCarousel(
              imageUrls: venue.imageUrls,
              fallbackEmoji: venue.emoji,
              height: 200,
            ),
          ),
          const SizedBox(height: 16),
          OwnerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statusBadge(venue.status),
                const SizedBox(height: 12),
                _row('Category', venue.category),
                _row('Location', venue.location),
                _row('Price', '${venue.price} EGP'),
                _row('Capacity', '${venue.capacity} guests'),
                _row('Photos', '${venue.imageUrls.length}'),
                if (venue.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    venue.description,
                    style: const TextStyle(color: OwnerColors.textMid, height: 1.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    switch (status) {
      case Venue.statusApproved:
        return OwnerBadge.active();
      case Venue.statusRejected:
        return OwnerBadge.cancelled();
      default:
        return OwnerBadge.pending();
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: OwnerColors.textGrey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: OwnerColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
