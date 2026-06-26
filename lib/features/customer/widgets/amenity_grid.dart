import 'package:flutter/material.dart';

import 'package:festivo/core/constants/app_colors.dart';
import 'package:festivo/core/domain/venue_amenities.dart';

/// Displays selected venue amenities with emoji and label (customer venue details).
class AmenityGrid extends StatelessWidget {
  final List<String> amenityIds;
  final bool dark;

  const AmenityGrid({
    super.key,
    required this.amenityIds,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final amenities = resolveVenueAmenitiesFromStorage(amenityIds);
    if (amenities.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: amenities.map((a) => _AmenityChip(amenity: a, dark: dark)).toList(),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final VenueAmenity amenity;
  final bool dark;

  const _AmenityChip({required this.amenity, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.sizeOf(context).width - 50) / 2,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card(dark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(dark)),
        boxShadow: [AppColors.shadow(dark)],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.input(dark),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(amenity.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              amenity.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textD(dark),
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
