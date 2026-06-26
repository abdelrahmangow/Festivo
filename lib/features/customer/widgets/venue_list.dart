import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/core/constants/app_colors.dart';
import 'package:festivo/features/customer/domain/customer_models.dart';
import 'package:festivo/features/customer/screens/venue_details_screen.dart';
import 'package:festivo/features/customer/state/customer_home_controller.dart';
import 'toast.dart';

class VenueList extends ConsumerWidget {
  final bool isDark;
  final List<Venue> venues;
  final Set<String> favorites;

  const VenueList({
    super.key,
    required this.isDark,
    required this.venues,
    required this.favorites,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = isDark;

    if (venues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'No venues match your search.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textD(d),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different filters.',
              style: TextStyle(fontSize: 13, color: AppColors.textM(d)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: venues.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Featured Venues',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textD(d),
                  ),
                ),
                Text(
                  '${venues.length} venue${venues.length != 1 ? "s" : ""} found',
                  style: TextStyle(fontSize: 13, color: AppColors.textL(d)),
                ),
              ],
            ),
          );
        }
        final v = venues[i - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: VenueCard(
            venue: v,
            isDark: d,
            isFav: favorites.contains(v.id),
            onToggleFav: () {
              final willAdd = !favorites.contains(v.id);
              ref
                  .read(customerHomeControllerProvider.notifier)
                  .toggleFavorite(v.id);
              showToast(
                ctx,
                willAdd ? '❤️ Added to favorites!' : 'Removed from favorites',
                d,
              );
            },
            onView: () => VenueDetailsScreen.open(ctx, v),
          ),
        );
      },
    );
  }
}

class VenueCard extends StatelessWidget {
  final Venue venue;
  final bool isDark, isFav;
  final VoidCallback onToggleFav, onView;

  const VenueCard({
    super.key,
    required this.venue,
    required this.isDark,
    required this.isFav,
    required this.onToggleFav,
    required this.onView,
  });

  String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );

  @override
  Widget build(BuildContext context) {
    final d = isDark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.card(d),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppColors.shadow(d)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 140,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (venue.imageUrls.isNotEmpty)
                  Image.network(
                    venue.imageUrls.first,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, _, _) => _emojiBackground(venue.emoji),
                  )
                else
                  _emojiBackground(venue.emoji),
                Positioned(
                  top: 10,
                  right: 10,
                  child: FavButton(isFav: isFav, onTap: onToggleFav),
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent(d),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      venue.category,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venue.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textD(d),
                  ),
                ),
                const SizedBox(height: 5),
                Row(children: [
                  Icon(Icons.location_on_outlined,
                      size: 13, color: AppColors.textL(d)),
                  const SizedBox(width: 3),
                  Text(venue.location,
                      style:
                          TextStyle(fontSize: 12, color: AppColors.textM(d))),
                ]),
                const SizedBox(height: 7),
                Row(children: [
                  const Text('⭐', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 3),
                  Text('${venue.rating} (${venue.reviews})',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.textM(d))),
                  const SizedBox(width: 12),
                  const Text('👥', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text('${venue.capacity} guests',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.textM(d))),
                ]),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Starting from',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textL(d))),
                        Text(
                          '${_fmt(venue.price)} EGP',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textD(d),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: onView,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColors.accent(d),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent(d).withOpacity(.30),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Text(
                          'View',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emojiBackground(String emoji) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD0D8E8), Color(0xFFB8C4D8)],
        ),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 60))),
    );
  }
}

class FavButton extends StatefulWidget {
  final bool isFav;
  final VoidCallback onTap;
  const FavButton({super.key, required this.isFav, required this.onTap});

  @override
  State<FavButton> createState() => _FavButtonState();
}

class _FavButtonState extends State<FavButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTap();
        _ctrl.forward(from: 0);
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.1),
                blurRadius: 8,
              )
            ],
          ),
          child: Center(
            child: Icon(
              widget.isFav ? Icons.favorite : Icons.favorite_border,
              color: widget.isFav
                  ? const Color(0xFFE55353)
                  : Colors.grey.shade400,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

