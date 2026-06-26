import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import 'package:festivo/core/utils/egypt_phone_validator.dart';
import 'package:festivo/features/auth/models/user_model.dart';
import 'package:festivo/features/auth/services/auth_service.dart';
import 'package:festivo/features/customer/state/customer_user_providers.dart';
import 'package:festivo/features/owner/theme/owner_colors.dart';

class OwnerEditProfileScreen extends ConsumerStatefulWidget {
  const OwnerEditProfileScreen({super.key});

  @override
  ConsumerState<OwnerEditProfileScreen> createState() => _OwnerEditProfileScreenState();
}

class _OwnerEditProfileScreenState extends ConsumerState<OwnerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _locLoading = false;
  String? _photoUrl;
  File? _pickedImage;
  String _initial = 'V';
  UserModel? _original;
  double? _pendingLatitude;
  double? _pendingLongitude;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  String _phoneForDisplay(String? stored) {
    if (stored == null || stored.isEmpty) return '';
    if (stored.startsWith('+20')) return stored.substring(3);
    if (stored.startsWith('20') && stored.length >= 12) return stored.substring(2);
    return stored;
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final profile = await AuthService.instance.fetchUserProfile();
      if (!mounted) return;
      if (profile == null) {
        setState(() => _loading = false);
        return;
      }
      final name = profile.name.trim().isNotEmpty ? profile.name.trim() : 'Venue Owner';
      setState(() {
        _original = profile;
        _nameCtrl.text = name;
        _emailCtrl.text = profile.email.isNotEmpty ? profile.email : (user.email ?? '');
        _phoneCtrl.text = _phoneForDisplay(profile.phone);
        _locationCtrl.text = profile.location?.trim().isNotEmpty == true
            ? profile.location!.trim()
            : 'Cairo, Egypt';
        _photoUrl = profile.photoUrl;
        _initial = name.isNotEmpty ? name[0].toUpperCase() : 'V';
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load profile.')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    if (_saving) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null && mounted) {
      setState(() => _pickedImage = File(file.path));
    }
  }

  Future<String?> _uploadPhoto(String uid) async {
    if (_pickedImage == null) return _photoUrl;
    final ref = FirebaseStorage.instance.ref().child('profile_photos/$uid.jpg');
    await ref.putFile(_pickedImage!);
    return ref.getDownloadURL();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locLoading = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final place = placemarks.isNotEmpty ? placemarks.first : null;
      final label = place != null
          ? [place.locality, place.administrativeArea, place.country]
              .where((e) => e != null && e.isNotEmpty)
              .join(', ')
          : '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      if (!mounted) return;
      setState(() {
        _locationCtrl.text = label;
        _pendingLatitude = pos.latitude;
        _pendingLongitude = pos.longitude;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not fetch location.')),
      );
    } finally {
      if (mounted) setState(() => _locLoading = false);
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    return validateEgyptPhone(value ?? '');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _original == null) return;

    setState(() => _saving = true);
    try {
      final name = _nameCtrl.text.trim();
      final email = _emailCtrl.text.trim();
      final phone = formatEgyptPhoneForStorage(_phoneCtrl.text);
      final location = _locationCtrl.text.trim();
      final photoUrl = await _uploadPhoto(user.uid);

      final updates = <String, dynamic>{};
      if (name != _original!.name) updates['name'] = name;
      if (email != _original!.email) updates['email'] = email;
      if (phone != _original!.phone) updates['phone'] = phone;
      if (location != (_original!.location ?? '')) updates['location'] = location;
      if (_pendingLatitude != null && _pendingLatitude != _original!.latitude) {
        updates['latitude'] = _pendingLatitude;
      }
      if (_pendingLongitude != null && _pendingLongitude != _original!.longitude) {
        updates['longitude'] = _pendingLongitude;
      }
      if (photoUrl != null && photoUrl != _original!.photoUrl) {
        updates['photoUrl'] = photoUrl;
      }

      if (updates.isEmpty) {
        if (!mounted) return;
        Navigator.pop(context, false);
        return;
      }

      await AuthService.instance.updateUserProfile(uid: user.uid, updates: updates);

      ref.invalidate(userByIdProvider(user.uid));

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save profile.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: OwnerColors.pinkBg,
        body: Center(child: CircularProgressIndicator(color: OwnerColors.pink)),
      );
    }

    return Scaffold(
      backgroundColor: OwnerColors.pinkBg,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: OwnerColors.pink,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: OwnerColors.pinkBorder,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : (_photoUrl != null && _photoUrl!.isNotEmpty)
                              ? NetworkImage(_photoUrl!) as ImageProvider
                              : null,
                      child: (_pickedImage == null &&
                              (_photoUrl == null || _photoUrl!.isEmpty))
                          ? Text(
                              _initial,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: OwnerColors.pink,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: OwnerColors.pink,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _field(
                controller: _nameCtrl,
                label: 'Full Name *',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              _field(
                controller: _emailCtrl,
                label: 'Email *',
                keyboard: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              _field(
                controller: _phoneCtrl,
                label: 'Phone *',
                keyboard: TextInputType.phone,
                prefixText: '🇪🇬 +20 ',
                validator: _validatePhone,
              ),
              _field(
                controller: _locationCtrl,
                label: 'Location',
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _locLoading || _saving ? null : _useCurrentLocation,
                style: OutlinedButton.styleFrom(
                  foregroundColor: OwnerColors.pink,
                  side: const BorderSide(color: OwnerColors.pink),
                ),
                icon: _locLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: const Text('Use current location'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OwnerColors.pink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboard,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: !_saving,
        keyboardType: keyboard,
        validator: validator,
        style: const TextStyle(color: OwnerColors.textDark),
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefixText,
          filled: true,
          fillColor: OwnerColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: OwnerColors.pinkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: OwnerColors.pinkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: OwnerColors.pink, width: 2),
          ),
        ),
      ),
    );
  }
}
