import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import 'package:festivo/app/providers/app_providers.dart';
import 'package:festivo/core/constants/app_colors.dart';
import 'package:festivo/core/utils/egypt_phone_validator.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _locLoading = false;
  String _phoneError = '';
  String? _photoUrl;
  File? _pickedImage;
  String _initial = 'U';

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

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (!mounted) return;
      final name = (data?['name'] as String?)?.trim() ?? '';
      setState(() {
        _nameCtrl.text = name.isNotEmpty ? name : 'User';
        _emailCtrl.text = (data?['email'] as String?) ?? user.email ?? '';
        _phoneCtrl.text = (data?['phone'] as String?) ?? '';
        _locationCtrl.text = (data?['location'] as String?) ?? 'Cairo, Egypt';
        _photoUrl = data?['photoUrl'] as String?;
        _initial = _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : 'U';
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) {
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
      setState(() => _locationCtrl.text = label);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'location': label,
        }, SetOptions(merge: true));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not fetch location.')),
      );
    } finally {
      if (mounted) setState(() => _locLoading = false);
    }
  }

  Future<void> _save() async {
    final phoneErr = validateEgyptPhone(_phoneCtrl.text);
    setState(() => _phoneError = phoneErr ?? '');
    if (phoneErr != null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final photoUrl = await _uploadPhoto(user.uid);
      final phone = formatEgyptPhoneForStorage(_phoneCtrl.text);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': phone,
        'location': _locationCtrl.text.trim(),
        if (photoUrl != null) 'photoUrl': photoUrl,
      }, SetOptions(merge: true));
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
    final dark = ref.watch(isDarkProvider);

    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.profileBg(dark),
        body: Center(child: CircularProgressIndicator(color: AppColors.accent(dark))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.profileBg(dark),
      appBar: AppBar(
        backgroundColor: AppColors.profileBg(dark),
        elevation: 0,
        title: Text('Edit Profile', style: TextStyle(color: AppColors.profileTextD(dark))),
        iconTheme: IconThemeData(color: AppColors.profileTextD(dark)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.profilePinkFill,
                    backgroundImage: _pickedImage != null
                        ? FileImage(_pickedImage!)
                        : (_photoUrl != null && _photoUrl!.isNotEmpty)
                            ? NetworkImage(_photoUrl!) as ImageProvider
                            : null,
                    child: (_pickedImage == null && (_photoUrl == null || _photoUrl!.isEmpty))
                        ? Text(_initial, style: TextStyle(fontSize: 36, color: AppColors.accent(dark)))
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.accent(dark),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _field(_nameCtrl, 'Full Name', dark),
            _field(_emailCtrl, 'Email', dark, keyboard: TextInputType.emailAddress),
            _phoneField(dark),
            _field(_locationCtrl, 'Location', dark),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _locLoading ? null : _useCurrentLocation,
              icon: _locLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
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
                  backgroundColor: AppColors.accent(dark),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, bool dark, {TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        style: TextStyle(color: AppColors.profileTextD(dark)),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.profileCard(dark),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.profileBorder(dark)),
          ),
        ),
      ),
    );
  }

  Widget _phoneField(bool dark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: AppColors.profileTextD(dark)),
            decoration: InputDecoration(
              labelText: 'Phone',
              prefixText: '🇪🇬 +20 ',
              filled: true,
              fillColor: AppColors.profileCard(dark),
              errorText: _phoneError.isEmpty ? null : _phoneError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.profileBorder(dark)),
              ),
            ),
            onChanged: (_) {
              if (_phoneError.isNotEmpty) {
                setState(() => _phoneError = '');
              }
            },
          ),
        ],
      ),
    );
  }
}
