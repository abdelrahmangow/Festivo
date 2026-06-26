import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'customer_home_state.dart';

class CustomerHomeController extends Notifier<CustomerHomeState> {
  @override
  CustomerHomeState build() => CustomerHomeState.initial();

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setPriceRange(int min, int max) {
    state = state.copyWith(priceMin: min, priceMax: max);
  }

  void resetFilters() {
    state = state.copyWith(selectedCategory: 'All', priceMin: 0, priceMax: 999999);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleFavorite(String venueId) {
    final next = {...state.favorites};
    if (next.contains(venueId)) {
      next.remove(venueId);
    } else {
      next.add(venueId);
    }
    state = state.copyWith(favorites: next);
  }
}

final customerHomeControllerProvider =
    NotifierProvider<CustomerHomeController, CustomerHomeState>(
  CustomerHomeController.new,
);

