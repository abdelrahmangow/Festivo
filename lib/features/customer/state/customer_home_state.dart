import '../domain/customer_models.dart';

class CustomerHomeState {
  final String selectedCategory;
  final int priceMin;
  final int priceMax;
  final String searchQuery;
  final Set<String> favorites;

  const CustomerHomeState({
    required this.selectedCategory,
    required this.priceMin,
    required this.priceMax,
    required this.searchQuery,
    required this.favorites,
  });

  factory CustomerHomeState.initial() => const CustomerHomeState(
        selectedCategory: 'All',
        priceMin: 0,
        priceMax: 999999,
        searchQuery: '',
        favorites: <String>{},
      );

  CustomerHomeState copyWith({
    String? selectedCategory,
    int? priceMin,
    int? priceMax,
    String? searchQuery,
    Set<String>? favorites,
  }) {
    return CustomerHomeState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      searchQuery: searchQuery ?? this.searchQuery,
      favorites: favorites ?? this.favorites,
    );
  }

  List<Venue> filteredVenues(List<Venue> venues) => filterVenues(
        venues,
        selectedCategory: selectedCategory,
        priceMin: priceMin,
        priceMax: priceMax,
        searchQuery: searchQuery,
      );
}

