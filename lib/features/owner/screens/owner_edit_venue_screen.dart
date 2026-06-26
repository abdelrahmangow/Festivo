import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/features/customer/domain/customer_models.dart';
import 'package:festivo/features/customer/services/cloudinary_service.dart';
import 'package:festivo/features/customer/state/venue_providers.dart';
import 'package:festivo/features/owner/theme/owner_colors.dart';
import 'package:festivo/features/owner/widgets/amenity_checkbox_picker.dart';
import 'package:festivo/features/owner/widgets/venue_images_picker.dart';

class OwnerEditVenueScreen extends ConsumerStatefulWidget {
  final Venue venue;

  const OwnerEditVenueScreen({super.key, required this.venue});

  @override
  ConsumerState<OwnerEditVenueScreen> createState() => _OwnerEditVenueScreenState();
}

class _OwnerEditVenueScreenState extends ConsumerState<OwnerEditVenueScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _capacityCtrl;
  late final TextEditingController _descriptionCtrl;
  late String _category;
  late List<String> _existingImageUrls;
  late Set<String> _selectedAmenities;
  final List<File> _newImages = [];
  bool _saving = false;

  static const _maxImages = 8;
  static const _categories = [
    'Wedding',
    'Party',
    'Corporate',
    'Birthday',
    'Graduation',
  ];

  @override
  void initState() {
    super.initState();
    final v = widget.venue;
    _nameCtrl = TextEditingController(text: v.name);
    _locationCtrl = TextEditingController(text: v.location);
    _priceCtrl = TextEditingController(text: '${v.price}');
    _capacityCtrl = TextEditingController(text: '${v.capacity}');
    _descriptionCtrl = TextEditingController(text: v.description);
    _category = v.category;
    _existingImageUrls = List.of(v.imageUrls);
    _selectedAmenities = Set<String>.from(v.amenities);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _priceCtrl.dispose();
    _capacityCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final added = await pickVenueImages(
      currentCount: _existingImageUrls.length + _newImages.length,
      maxImages: _maxImages,
    );
    if (added.isEmpty) return;
    setState(() => _newImages.addAll(added));
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final price = int.tryParse(_priceCtrl.text.trim());
    final capacity = int.tryParse(_capacityCtrl.text.trim());
    if (_nameCtrl.text.trim().isEmpty ||
        _locationCtrl.text.trim().isEmpty ||
        price == null ||
        price <= 0 ||
        capacity == null ||
        capacity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields correctly.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final uploaded = _newImages.isNotEmpty
          ? await CloudinaryService.uploadImages(_newImages)
          : <String>[];
      final imageUrls = [..._existingImageUrls, ...uploaded];

      await ref.read(venueServiceProvider).updateVenue(
            venueId: widget.venue.id,
            ownerId: uid,
            name: _nameCtrl.text.trim(),
            location: _locationCtrl.text.trim(),
            category: _category,
            price: price,
            capacity: capacity,
            description: _descriptionCtrl.text.trim(),
            amenities: _selectedAmenities.toList(),
            imageUrls: imageUrls,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venue updated.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update venue.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Venue'),
        backgroundColor: OwnerColors.pink,
        foregroundColor: Colors.white,
      ),
      backgroundColor: OwnerColors.pinkBg,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          VenueImagesPicker(
            pickedFiles: _newImages,
            existingUrls: _existingImageUrls,
            onPickImages: _saving ? () {} : _pickImages,
            onRemovePicked: _saving ? (_) {} : (i) => setState(() => _newImages.removeAt(i)),
            onRemoveExisting: _saving
                ? null
                : (i) => setState(() => _existingImageUrls.removeAt(i)),
            maxImages: _maxImages,
            enabled: !_saving,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            enabled: !_saving,
            decoration: const InputDecoration(labelText: 'Name *', filled: true),
          ),
          TextField(
            controller: _locationCtrl,
            enabled: !_saving,
            decoration: const InputDecoration(labelText: 'Location *', filled: true),
          ),
          TextField(
            controller: _priceCtrl,
            enabled: !_saving,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Price *', filled: true),
          ),
          TextField(
            controller: _capacityCtrl,
            enabled: !_saving,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Capacity *', filled: true),
          ),
          TextField(
            controller: _descriptionCtrl,
            enabled: !_saving,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description', filled: true),
          ),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: _saving ? null : (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 16),
          AmenityCheckboxPicker(
            selectedIds: _selectedAmenities,
            enabled: !_saving,
            onChanged: (ids) => setState(() => _selectedAmenities = ids),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: OwnerColors.pink,
              foregroundColor: Colors.white,
            ),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
