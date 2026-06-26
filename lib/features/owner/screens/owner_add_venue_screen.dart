import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/features/customer/services/cloudinary_service.dart';
import 'package:festivo/features/customer/state/venue_providers.dart';
import 'package:festivo/features/owner/theme/owner_colors.dart';
import 'package:festivo/features/owner/widgets/amenity_checkbox_picker.dart';
import 'package:festivo/features/owner/widgets/venue_images_picker.dart';

class OwnerAddVenueScreen extends ConsumerStatefulWidget {
  final VoidCallback? onDone;

  const OwnerAddVenueScreen({super.key, this.onDone});

  @override
  ConsumerState<OwnerAddVenueScreen> createState() => _OwnerAddVenueScreenState();
}

class _OwnerAddVenueScreenState extends ConsumerState<OwnerAddVenueScreen> {
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String _category = 'Wedding';
  bool _submitting = false;
  final List<File> _pickedImages = [];
  Set<String> _selectedAmenities = {};

  static const _maxImages = 8;
  static const _categories = [
    'Wedding',
    'Party',
    'Corporate',
    'Birthday',
    'Graduation',
  ];

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
      currentCount: _pickedImages.length,
      maxImages: _maxImages,
    );
    if (added.isEmpty) return;
    setState(() => _pickedImages.addAll(added));
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final location = _locationCtrl.text.trim();
    final price = int.tryParse(_priceCtrl.text.trim()) ?? 0;
    final capacity = int.tryParse(_capacityCtrl.text.trim()) ?? 0;
    final description = _descriptionCtrl.text.trim();

    if (name.isEmpty || location.isEmpty || price <= 0 || capacity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields correctly.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      List<String> imageUrls = [];
      if (_pickedImages.isNotEmpty) {
        imageUrls = await CloudinaryService.uploadImages(_pickedImages);
      }

      await ref.read(venueServiceProvider).createVenue(
            name: name,
            location: location,
            category: _category,
            price: price,
            capacity: capacity,
            description: description,
            amenities: _selectedAmenities.toList(),
            imageUrls: imageUrls,
          );

      _nameCtrl.clear();
      _locationCtrl.clear();
      _priceCtrl.clear();
      _capacityCtrl.clear();
      _descriptionCtrl.clear();
      _pickedImages.clear();
      setState(() => _selectedAmenities = {});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Venue submitted for admin approval. It will appear to customers once approved.',
          ),
        ),
      );
      widget.onDone?.call();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not create venue. Check your connection and try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwnerColors.pinkBg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: OwnerColors.grad),
            padding: const EdgeInsets.fromLTRB(16, 52, 16, 20),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Venue',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  'New venues start as Pending until admin approval.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                VenueImagesPicker(
                  pickedFiles: _pickedImages,
                  onPickImages: _submitting ? () {} : _pickImages,
                  onRemovePicked: _submitting
                      ? (_) {}
                      : (i) => setState(() => _pickedImages.removeAt(i)),
                  maxImages: _maxImages,
                  enabled: !_submitting,
                ),
                const SizedBox(height: 16),
                _field(_nameCtrl, 'Venue Name *'),
                _field(_locationCtrl, 'Location *'),
                _field(_priceCtrl, 'Price (EGP) *', keyboard: TextInputType.number),
                _field(_capacityCtrl, 'Capacity *', keyboard: TextInputType.number),
                _field(_descriptionCtrl, 'Description', maxLines: 3),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    filled: true,
                    fillColor: OwnerColors.white,
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: _submitting ? null : (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: 20),
                AmenityCheckboxPicker(
                  selectedIds: _selectedAmenities,
                  enabled: !_submitting,
                  onChanged: (ids) => setState(() => _selectedAmenities = ids),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OwnerColors.pink,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Submit for Approval',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
        enabled: !_submitting,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: OwnerColors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
