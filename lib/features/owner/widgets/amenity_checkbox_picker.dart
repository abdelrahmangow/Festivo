import 'package:flutter/material.dart';

import 'package:festivo/core/domain/venue_amenities.dart';
import 'package:festivo/features/owner/theme/owner_colors.dart';
import 'package:festivo/features/owner/widgets/owner_widgets.dart';

/// Checkbox list for selecting venue amenities (owner add / edit).
class AmenityCheckboxPicker extends StatelessWidget {
  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onChanged;
  final bool enabled;

  const AmenityCheckboxPicker({
    super.key,
    required this.selectedIds,
    required this.onChanged,
    this.enabled = true,
  });

  void _toggle(String id, bool? checked) {
    if (!enabled) return;
    final next = Set<String>.from(selectedIds);
    if (checked == true) {
      next.add(id);
    } else {
      next.remove(id);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amenities',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: OwnerColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Select all amenities available at your venue',
          style: TextStyle(fontSize: 13, color: OwnerColors.textGrey),
        ),
        const SizedBox(height: 12),
        OwnerCard(
          child: Column(
            children: [
              for (var i = 0; i < kVenueAmenities.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _AmenityTile(
                  amenity: kVenueAmenities[i],
                  checked: selectedIds.contains(kVenueAmenities[i].id),
                  enabled: enabled,
                  onChanged: (v) => _toggle(kVenueAmenities[i].id, v),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AmenityTile extends StatelessWidget {
  final VenueAmenity amenity;
  final bool checked;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  const _AmenityTile({
    required this.amenity,
    required this.checked,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: checked ? OwnerColors.pinkBg.withValues(alpha: 0.5) : Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => onChanged(!checked) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              Checkbox(
                value: checked,
                onChanged: enabled ? onChanged : null,
                activeColor: OwnerColors.pink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              Text(amenity.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  amenity.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: enabled ? OwnerColors.textDark : OwnerColors.textGrey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
