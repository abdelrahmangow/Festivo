import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/app/providers/app_providers.dart';
import 'package:festivo/core/constants/app_colors.dart';
import 'package:festivo/features/customer/state/customer_home_controller.dart';
import 'package:festivo/features/customer/state/customer_home_state.dart';
import 'package:festivo/features/customer/state/customer_user_providers.dart';
import 'package:festivo/features/customer/state/venue_providers.dart';

import '../widgets/category_row.dart';
import '../widgets/filter_panel.dart';
import '../widgets/home_header.dart';
import '../widgets/toast.dart';
import '../widgets/venue_list.dart';

// ─────────────────────────────────────────────
// Home Screen — venue discovery
// ─────────────────────────────────────────────
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fade  = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _slide = Tween(begin: const Offset(0, -.04), end: Offset.zero).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _openFilter(BuildContext ctx, bool isDark, CustomerHomeState s) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: FilterPanel(
          isDark: isDark,
          selectedCat: s.selectedCategory,
          priceMin: s.priceMin,
          priceMax: s.priceMax,
          onApply: (cat, mn, mx) {
            ref.read(customerHomeControllerProvider.notifier).setCategory(cat);
            ref.read(customerHomeControllerProvider.notifier).setPriceRange(mn, mx);
            showToast(ctx, '✅ Filters applied!', isDark);
          },
          onReset: () => ref.read(customerHomeControllerProvider.notifier).resetFilters(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(isDarkProvider);
    final state = ref.watch(customerHomeControllerProvider);
    final firstName = ref.watch(customerFirstNameProvider).value ?? 'User';
    final venuesAsync = ref.watch(approvedVenuesProvider);
    SystemChrome.setSystemUIOverlayStyle(
      d ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );
    return Scaffold(
      backgroundColor: AppColors.bg(d),
      body: Column(
        children: [
          FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: HomeHeader(
                isDark: d,
                searchCtrl: _searchCtrl,
                displayName: firstName,
                onSearch: (q) => ref
                    .read(customerHomeControllerProvider.notifier)
                    .setSearchQuery(q),
                onFilterTap: () => _openFilter(context, d, state),
              ),
            ),
          ),
          CategoryRow(isDark: d, selected: state.selectedCategory),
          Expanded(
            child: venuesAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: AppColors.accent(d)),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Could not load venues',
                  style: TextStyle(color: AppColors.textM(d)),
                ),
              ),
              data: (venues) {
                if (venues.isEmpty) {
                  return Center(
                    child: Text(
                      'No venues available yet.\nCheck back after owners submit venues.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textM(d)),
                    ),
                  );
                }
                return VenueList(
                  isDark: d,
                  venues: state.filteredVenues(venues),
                  favorites: state.favorites,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
