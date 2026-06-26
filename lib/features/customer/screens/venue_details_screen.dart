import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/app/providers/app_providers.dart';
import 'package:festivo/core/constants/app_colors.dart';
import 'package:festivo/features/customer/domain/customer_models.dart';
import 'package:festivo/features/customer/screens/booking_screen.dart';
import 'package:festivo/features/customer/screens/venue_reviews_screen.dart';
import 'package:festivo/features/customer/state/customer_home_controller.dart';
import 'package:festivo/features/customer/state/venue_providers.dart';
import 'package:festivo/features/customer/widgets/amenity_grid.dart';
import 'package:festivo/features/customer/widgets/venue_image_carousel.dart';
import 'package:festivo/features/customer/widgets/toast.dart';

class VenueDetailsScreen extends ConsumerWidget {
  final Venue venue;

  const VenueDetailsScreen({super.key, required this.venue});

  static void open(BuildContext context, Venue venue) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VenueDetailsScreen(venue: venue)),
    );
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(isDarkProvider);
    final liveVenue = ref.watch(venueByIdProvider(venue.id)).value ?? venue;
    final ratingLabel = liveVenue.reviews == 0
        ? '0'
        : liveVenue.rating.toStringAsFixed(1);
    final favorites = ref.watch(customerHomeControllerProvider).favorites;
    final isFav = favorites.contains(venue.id);

    SystemChrome.setSystemUIOverlayStyle(
      dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    return Scaffold(
      backgroundColor: AppColors.bg(dark),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  dark: dark,
                  venue: venue,
                  isFav: isFav,
                  onBack: () => Navigator.pop(context),
                  onToggleFav: () {
                    ref
                        .read(customerHomeControllerProvider.notifier)
                        .toggleFavorite(venue.id);
                    showToast(
                      context,
                      isFav ? 'Removed from favorites' : '❤️ Added to favorites!',
                      dark,
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          venue.name,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textD(dark),
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent(dark).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          venue.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.gold,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            venue.location,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.textM(dark),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            color: AppColors.textM(dark),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Capacity: up to ${venue.capacity} guests',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.textM(dark),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: GestureDetector(
                    onTap: () => VenueReviewsScreen.open(context, venue),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: dark ? AppColors.dGlight : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border(dark)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow(dark).color.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: AppColors.gold, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            ratingLabel,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textD(dark),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${liveVenue.reviews} reviews)',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textL(dark),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right, size: 18, color: AppColors.textL(dark)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(color: AppColors.border(dark)),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textD(dark),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        venue.description,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textM(dark),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                if (venue.amenities.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amenities',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textD(dark),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AmenityGrid(amenityIds: venue.amenities, dark: dark),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.paddingOf(context).bottom + 16,
              ),
              decoration: BoxDecoration(
                color: AppColors.bg(dark),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Starting from', style: TextStyle(fontSize: 12, color: AppColors.textL(dark))),
                      Text(
                        '${_fmt(venue.price)} EGP',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingScreen(venue: venue),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent(dark),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Book Now',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool dark;
  final Venue venue;
  final bool isFav;
  final VoidCallback onBack;
  final VoidCallback onToggleFav;

  const _Header({
    required this.dark,
    required this.venue,
    required this.isFav,
    required this.onBack,
    required this.onToggleFav,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        VenueImageCarousel(
          imageUrls: venue.imageUrls,
          fallbackEmoji: venue.emoji,
          height: 260,
          dark: dark,
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 8,
          left: 16,
          child: _CircleBtn(icon: Icons.arrow_back_ios_new, onTap: onBack, dark: dark),
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 8,
          right: 16,
          child: _CircleBtn(
            icon: isFav ? Icons.favorite : Icons.favorite_border,
            onTap: onToggleFav,
            dark: dark,
            filled: isFav,
          ),
        ),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool dark;
  final bool filled;

  const _CircleBtn({
    required this.icon,
    required this.onTap,
    required this.dark,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: dark ? AppColors.dWhite.withOpacity(0.9) : Colors.white.withOpacity(0.95),
          shape: BoxShape.circle,
          boxShadow: [AppColors.shadow(dark)],
        ),
        child: Icon(
          icon,
          size: 18,
          color: filled ? AppColors.accent(dark) : AppColors.textD(dark),
        ),
      ),
    );
  }
}
