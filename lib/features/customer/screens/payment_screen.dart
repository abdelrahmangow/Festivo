import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:festivo/app/providers/app_providers.dart';
import 'package:festivo/core/constants/app_colors.dart';
import 'package:festivo/features/customer/domain/payment_methods.dart';
import 'package:festivo/features/customer/screens/customer_shell.dart';
import 'package:festivo/features/customer/services/booking_service.dart';
import 'package:festivo/features/customer/services/cloudinary_service.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String venueId;
  final String venueName;
  final String ownerId;
  final int totalAmount;
  final DateTime bookingDate;
  final String bookingTime;
  final String userName;
  final String phone;
  final String email;
  final int guestCount;
  final String packageType;

  const PaymentScreen({
    super.key,
    required this.venueId,
    required this.venueName,
    required this.ownerId,
    required this.totalAmount,
    required this.bookingDate,
    required this.bookingTime,
    required this.userName,
    required this.phone,
    required this.email,
    required this.guestCount,
    required this.packageType,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _bookingService = BookingService();
  int _selectedMethod = 0;
  File? _receiptFile;
  bool _isConfirming = false;

  String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );

  String get _dateLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final d = widget.bookingDate;
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  PaymentMethodOption get _currentMethod => kPaymentMethods[_selectedMethod];

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (file != null) {
      setState(() => _receiptFile = File(file.path));
    }
  }

  Future<void> _confirm() async {
    if (_currentMethod.requiresReceipt && _receiptFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your payment receipt.')),
      );
      return;
    }

    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to complete your booking.')),
      );
      return;
    }

    setState(() => _isConfirming = true);

    try {
      String? receiptUrl;
      if (_currentMethod.requiresReceipt && _receiptFile != null) {
        receiptUrl = await CloudinaryService.uploadReceipt(_receiptFile!);
      }

      final available = await _bookingService.isSlotAvailable(
        venueId: widget.venueId,
        bookingDate: widget.bookingDate,
        bookingTime: widget.bookingTime,
      );
      if (!available) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This time slot is no longer available.')),
        );
        return;
      }

      final paymentStatus = _currentMethod.requiresReceipt
          ? 'Pending Verification'
          : 'Pending';

      await _bookingService.createBooking(
        venueId: widget.venueId,
        venueName: widget.venueName,
        ownerId: widget.ownerId,
        userName: widget.userName,
        phone: widget.phone,
        email: widget.email,
        guestCount: widget.guestCount,
        packageType: widget.packageType,
        bookingDate: widget.bookingDate,
        bookingTime: widget.bookingTime,
        paymentMethod: _currentMethod.title,
        receiptUrl: receiptUrl,
        paymentStatus: paymentStatus,
        totalAmount: widget.totalAmount,
      );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Booking Confirmed!'),
          content: Text(
            'Your booking at ${widget.venueName} on $_dateLabel at ${widget.bookingTime} '
            'has been confirmed.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const CustomerShell()),
                  (route) => false,
                );
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } on SlotUnavailableException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This time slot is no longer available.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not complete booking. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = ref.watch(isDarkProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(dark),
      appBar: AppBar(
        backgroundColor: AppColors.bg(dark),
        elevation: 0,
        title: Text('Payment', style: TextStyle(color: AppColors.textD(dark))),
        iconTheme: IconThemeData(color: AppColors.textD(dark)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accent(dark), AppColors.accent2(dark)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.venueName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$_dateLabel · ${widget.bookingTime}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_fmt(widget.totalAmount)} EGP',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Payment Method',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textD(dark),
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(kPaymentMethods.length, (i) {
              final m = kPaymentMethods[i];
              final sel = _selectedMethod == i;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedMethod = i;
                  if (!m.requiresReceipt) _receiptFile = null;
                }),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card(dark),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel ? AppColors.accent(dark) : AppColors.border(dark),
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: m.iconBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(m.icon, color: m.iconColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textD(dark),
                              ),
                            ),
                            Text(
                              m.subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textM(dark),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        sel ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: sel ? AppColors.accent(dark) : AppColors.textL(dark),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (_currentMethod.requiresReceipt) ...[
              const SizedBox(height: 16),
              Text(
                'Payment Receipt',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textD(dark),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _pickReceipt,
                icon: const Icon(Icons.upload_file),
                label: Text(
                  _receiptFile == null ? 'Upload Receipt' : 'Replace Receipt',
                ),
              ),
              if (_receiptFile != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _receiptFile!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isConfirming ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent(dark),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isConfirming
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Confirm Booking',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
