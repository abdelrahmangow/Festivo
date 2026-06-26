import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String label;
  final String emoji;
  const Category({required this.label, required this.emoji});
}

/// Firestore-backed venue document mapped for customer, owner, and admin flows.
class Venue {
  final String id;
  final String ownerId;
  final String ownerName;
  final String name;
  final String location;
  final String category;
  final String emoji;
  final int price;
  final double rating;
  final int reviews;
  final int capacity;
  final String description;
  final List<String> amenities;
  final List<String> imageUrls;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Venue({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.name,
    required this.location,
    required this.category,
    required this.emoji,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.capacity,
    required this.description,
    this.amenities = const [],
    this.imageUrls = const [],
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  static const statusPending = 'Pending';
  static const statusApproved = 'Approved';
  static const statusRejected = 'Rejected';

  bool get isApproved => status == statusApproved;
  bool get isPending => status == statusPending;
  bool get isRejected => status == statusRejected;

  factory Venue.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final amenitiesRaw = data['amenities'];
    final imagesRaw = data['imageUrls'];
    return Venue(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? '',
      name: data['name'] as String? ?? '',
      location: data['location'] as String? ?? '',
      category: data['category'] as String? ?? '',
      emoji: data['emoji'] as String? ?? '🏛️',
      price: (data['price'] as num?)?.toInt() ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      reviews: (data['reviews'] as num?)?.toInt() ?? 0,
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      description: data['description'] as String? ?? '',
      amenities: amenitiesRaw is List
          ? amenitiesRaw.map((e) => e.toString()).toList()
          : const [],
      imageUrls: imagesRaw is List
          ? imagesRaw.map((e) => e.toString()).where((u) => u.isNotEmpty).toList()
          : const [],
      status: data['status'] as String? ?? statusPending,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Venue copyWith({
    String? name,
    String? location,
    String? category,
    String? emoji,
    int? price,
    int? capacity,
    String? description,
    List<String>? amenities,
    List<String>? imageUrls,
    String? status,
  }) {
    return Venue(
      id: id,
      ownerId: ownerId,
      ownerName: ownerName,
      name: name ?? this.name,
      location: location ?? this.location,
      category: category ?? this.category,
      emoji: emoji ?? this.emoji,
      price: price ?? this.price,
      rating: rating,
      reviews: reviews,
      capacity: capacity ?? this.capacity,
      description: description ?? this.description,
      amenities: amenities ?? this.amenities,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: this.updatedAt,
    );
  }
}

const kCategories = <Category>[
  Category(label: 'All', emoji: '🌟'),
  Category(label: 'Wedding', emoji: '💍'),
  Category(label: 'Party', emoji: '🎉'),
  Category(label: 'Graduation', emoji: '🎓'),
  Category(label: 'Corporate', emoji: '🏢'),
  Category(label: 'Birthday', emoji: '🎂'),
];

String emojiForCategory(String category) {
  switch (category) {
    case 'Wedding':
      return '💍';
    case 'Party':
      return '🎉';
    case 'Graduation':
      return '🎓';
    case 'Corporate':
      return '🏢';
    case 'Birthday':
      return '🎂';
    default:
      return '🏛️';
  }
}

List<Venue> filterVenues(
  List<Venue> venues, {
  required String selectedCategory,
  required int priceMin,
  required int priceMax,
  required String searchQuery,
}) {
  final q = searchQuery.trim().toLowerCase();
  return venues.where((v) {
    final matchCategory =
        selectedCategory == 'All' || v.category == selectedCategory;
    final matchPrice = v.price >= priceMin && v.price <= priceMax;
    final matchQuery = q.isEmpty ||
        v.name.toLowerCase().contains(q) ||
        v.location.toLowerCase().contains(q);
    return matchCategory && matchPrice && matchQuery;
  }).toList();
}
