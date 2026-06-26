/// Predefined venue amenities with stable IDs for storage in Firestore.
class VenueAmenity {
  final String id;
  final String emoji;
  final String label;

  const VenueAmenity({
    required this.id,
    required this.emoji,
    required this.label,
  });

  String get displayLabel => '$emoji $label';
}

const kVenueAmenities = <VenueAmenity>[
  VenueAmenity(id: 'parking', emoji: '🚗', label: 'Parking'),
  VenueAmenity(id: 'wifi', emoji: '📶', label: 'Wi-Fi'),
  VenueAmenity(id: 'accessibility', emoji: '♿', label: 'Accessibility'),
  VenueAmenity(id: 'air_conditioning', emoji: '❄️', label: 'Air Conditioning'),
  VenueAmenity(id: 'stage', emoji: '🎭', label: 'Stage'),
  VenueAmenity(id: 'sound_system', emoji: '🔊', label: 'Sound System'),
  VenueAmenity(id: 'projector', emoji: '📽️', label: 'Projector / Screen'),
  VenueAmenity(id: 'catering', emoji: '🍽️', label: 'Catering'),
  VenueAmenity(id: 'bar_service', emoji: '🍸', label: 'Bar Service'),
  VenueAmenity(id: 'kitchen_access', emoji: '👨‍🍳', label: 'Kitchen Access'),
  VenueAmenity(id: 'outdoor_area', emoji: '🌳', label: 'Outdoor Area'),
  VenueAmenity(id: 'pool', emoji: '🏊', label: 'Pool'),
  VenueAmenity(id: 'accommodation', emoji: '🏨', label: 'Accommodation'),
  VenueAmenity(id: 'decoration', emoji: '🎀', label: 'Decoration Service'),
  VenueAmenity(id: 'security', emoji: '🛡️', label: 'Security'),
];

VenueAmenity? venueAmenityById(String id) {
  for (final a in kVenueAmenities) {
    if (a.id == id) return a;
  }
  return null;
}

/// Resolves stored amenity IDs to full [VenueAmenity] objects (unknown IDs skipped).
List<VenueAmenity> resolveVenueAmenities(List<String> ids) {
  final result = <VenueAmenity>[];
  for (final id in ids) {
    final amenity = venueAmenityById(id);
    if (amenity != null) result.add(amenity);
  }
  return result;
}

/// Parses legacy `"emoji label"` strings or IDs into resolved amenities.
List<VenueAmenity> resolveVenueAmenitiesFromStorage(List<String> stored) {
  final result = <VenueAmenity>[];
  for (final entry in stored) {
    final byId = venueAmenityById(entry);
    if (byId != null) {
      result.add(byId);
      continue;
    }
    for (final a in kVenueAmenities) {
      if (entry == a.displayLabel || entry.endsWith(' ${a.label}')) {
        result.add(a);
        break;
      }
    }
  }
  return result;
}
