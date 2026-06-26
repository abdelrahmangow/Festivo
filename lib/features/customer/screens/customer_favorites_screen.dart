import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/app/providers/app_providers.dart';
import 'package:festivo/core/constants/app_colors.dart';
import 'package:festivo/features/customer/screens/venue_details_screen.dart';
import 'package:festivo/features/customer/state/customer_home_controller.dart';
import 'package:festivo/features/customer/state/venue_providers.dart';
import 'package:festivo/features/customer/widgets/toast.dart';
import 'package:festivo/features/customer/widgets/venue_list.dart';

class CustomerFavoritesScreen extends ConsumerWidget {
  const CustomerFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(isDarkProvider);
    final state = ref.watch(customerHomeControllerProvider);
    final venuesAsync = ref.watch(approvedVenuesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(dark),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [AppColors.shadow(dark)],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        'assets/logo.jpeg',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) =>
                            const Center(child: Text('🎉', style: TextStyle(fontSize: 20))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Favorites',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textD(dark),
                        ),
                      ),
                      Text(
                        'Your saved venues',
                        style: TextStyle(fontSize: 14, color: AppColors.textM(dark)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: venuesAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: AppColors.accent(dark)),
                ),
                error: (_, __) => Center(
                  child: Text(
                    'Could not load favorites',
                    style: TextStyle(color: AppColors.textM(dark)),
                  ),
                ),
                data: (venues) {
                  final favorites = venues
                      .where((v) => state.favorites.contains(v.id))
                      .toList();

                  if (favorites.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 80,
                            color: dark ? Colors.white24 : Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No favorites yet',
                            style: TextStyle(
                              color: AppColors.textD(dark),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: favorites.length,
                    padding: const EdgeInsets.only(bottom: 20),
                    itemBuilder: (context, i) {
                      final venue = favorites[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: VenueCard(
                          venue: venue,
                          isDark: dark,
                          isFav: true,
                          onToggleFav: () {
                            ref
                                .read(customerHomeControllerProvider.notifier)
                                .toggleFavorite(venue.id);
                            showToast(context, 'Removed from favorites', dark);
                          },
                          onView: () => VenueDetailsScreen.open(context, venue),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
