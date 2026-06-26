import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/app/providers/app_providers.dart';
import 'package:festivo/core/constants/app_colors.dart';
import 'package:festivo/features/customer/domain/customer_booking.dart';
import 'package:festivo/features/customer/domain/customer_models.dart';
import 'package:festivo/features/customer/screens/payment_screen.dart';
import 'package:festivo/features/customer/services/booking_service.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final Venue venue;

  const BookingScreen({super.key, required this.venue});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _bookingService = BookingService();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;
  String _selectedTime = '6:00 PM';
  int _guests = 50;
  String _selectedPkg = 'Standard';
  bool _isLoading = false;
  int _step = 0;

  static const _minGuests = 10;
  static const _maxGuests = 300;
  static const _times = BookingService.timeSlots;
  static const _packages = ['Standard', 'Premium', 'Luxury'];
  static const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );

  int get _pkgMultiplier =>
      _selectedPkg == 'Luxury' ? 2 : _selectedPkg == 'Premium' ? 1 : 0;

  int get _totalPrice =>
      widget.venue.price + (_pkgMultiplier * (widget.venue.price ~/ 2));

  @override
  void initState() {
    super.initState();
    if (!widget.venue.isApproved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This venue is not available for booking yet.'),
          ),
        );
        Navigator.pop(context);
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _changeGuests(int delta) {
    setState(() {
      _guests = (_guests + delta).clamp(_minGuests, _maxGuests);
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _ensureTimeAvailable(VenueSlotMap slots) {
    if (_selectedDate == null) return;
    if (_bookingService.isSlotBooked(slots, _selectedDate!, _selectedTime)) {
      for (final t in _times) {
        if (!_bookingService.isSlotBooked(slots, _selectedDate!, t)) {
          setState(() => _selectedTime = t);
          return;
        }
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      _showError('Please select an event date.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final available = await _bookingService.isSlotAvailable(
        venueId: widget.venue.id,
        bookingDate: _selectedDate!,
        bookingTime: _selectedTime,
      );
      if (!available) {
        _showError('This time slot is no longer available.');
        return;
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            venueId: widget.venue.id,
            venueName: widget.venue.name,
            ownerId: widget.venue.ownerId,
            totalAmount: _totalPrice,
            bookingDate: _selectedDate!,
            bookingTime: _selectedTime,
            userName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            guestCount: _guests,
            packageType: _selectedPkg,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _daysInMonth(DateTime m) => DateTime(m.year, m.month + 1, 0).day;

  int _firstWeekday(DateTime m) => DateTime(m.year, m.month, 1).weekday % 7;

  bool _isPastDay(int day) {
    final d = DateTime(_focusedMonth.year, _focusedMonth.month, day);
    final today = DateTime.now();
    return !d.isAfter(DateTime(today.year, today.month, today.day));
  }

  bool _isSelectableDay(int day, VenueSlotMap slots) {
    if (_isPastDay(day)) return false;
    final d = DateTime(_focusedMonth.year, _focusedMonth.month, day);
    return _bookingService.hasAvailableSlot(slots, d);
  }

  void _onSelectDay(int day, VenueSlotMap slots) {
    final d = DateTime(_focusedMonth.year, _focusedMonth.month, day);
    if (!_isSelectableDay(day, slots)) return;
    setState(() => _selectedDate = d);
    _ensureTimeAvailable(slots);
  }

  void _onNext(VenueSlotMap slots) {
    if (_selectedDate == null) {
      _showError('Please select an event date.');
      return;
    }
    if (_bookingService.isSlotBooked(slots, _selectedDate!, _selectedTime)) {
      _showError('This time slot is no longer available.');
      return;
    }
    setState(() => _step = 1);
  }

  @override
  Widget build(BuildContext context) {
    final dark = ref.watch(isDarkProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(dark),
      appBar: AppBar(
        backgroundColor: AppColors.bg(dark),
        elevation: 0,
        title: Text(
          'Book ${widget.venue.name}',
          style: TextStyle(color: AppColors.textD(dark), fontSize: 16),
        ),
        iconTheme: IconThemeData(color: AppColors.textD(dark)),
      ),
      body: StreamBuilder<VenueSlotMap>(
        stream: _bookingService.watchVenueSlots(widget.venue.id),
        builder: (context, snapshot) {
          final slots = snapshot.data ?? {};

          return Column(
            children: [
              _StepIndicator(step: _step, dark: dark),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _step == 0
                      ? _buildStepOne(dark, slots)
                      : _buildStepTwo(dark),
                ),
              ),
              _BottomBar(
                dark: dark,
                step: _step,
                total: _totalPrice,
                fmt: _fmt,
                loading: _isLoading,
                onBack: () => setState(() => _step = 0),
                onNext: () => _onNext(slots),
                onSubmit: _submit,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepOne(bool dark, VenueSlotMap slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textD(dark)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _legendDot(const Color(0xFF4CAF50), 'Available', dark),
            const SizedBox(width: 16),
            _legendDot(const Color(0xFFE53935), 'Fully booked', dark),
          ],
        ),
        const SizedBox(height: 12),
        _CalendarCard(
          dark: dark,
          focusedMonth: _focusedMonth,
          selectedDate: _selectedDate,
          weekdays: _weekdays,
          daysInMonth: _daysInMonth(_focusedMonth),
          firstWeekday: _firstWeekday(_focusedMonth),
          isPastDay: _isPastDay,
          isFullyBooked: (day) {
            final d = DateTime(_focusedMonth.year, _focusedMonth.month, day);
            return !_isPastDay(day) &&
                _bookingService.isDateFullyBooked(slots, d);
          },
          isAvailableDay: (day) => _isSelectableDay(day, slots),
          onPrev: () => setState(() {
            _focusedMonth =
                DateTime(_focusedMonth.year, _focusedMonth.month - 1);
          }),
          onNext: () => setState(() {
            _focusedMonth =
                DateTime(_focusedMonth.year, _focusedMonth.month + 1);
          }),
          onSelectDay: (day) => _onSelectDay(day, slots),
        ),
        const SizedBox(height: 20),
        Text(
          'Time Slot',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textD(dark)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _times.map((t) {
            final booked = _selectedDate != null &&
                _bookingService.isSlotBooked(slots, _selectedDate!, t);
            final sel = t == _selectedTime && !booked;
            final bg = booked
                ? const Color(0xFFFFEBEE)
                : sel
                    ? AppColors.accent(dark)
                    : const Color(0xFFE8F5E9);
            final fg = booked
                ? const Color(0xFFE53935)
                : sel
                    ? Colors.white
                    : const Color(0xFF2E7D32);
            return ChoiceChip(
              label: Text(t),
              selected: sel,
              onSelected: booked ? null : (_) => setState(() => _selectedTime = t),
              selectedColor: AppColors.accent(dark),
              backgroundColor: bg,
              labelStyle: TextStyle(color: fg, fontWeight: FontWeight.w600),
              side: BorderSide(
                color: booked ? const Color(0xFFE53935) : const Color(0xFF4CAF50),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text(
          'Guests',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textD(dark)),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => _changeGuests(-10),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '$_guests',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textD(dark),
              ),
            ),
            IconButton(
              onPressed: () => _changeGuests(10),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Package',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textD(dark)),
        ),
        const SizedBox(height: 10),
        ..._packages.map((p) {
          return RadioListTile<String>(
            title: Text(p, style: TextStyle(color: AppColors.textD(dark))),
            value: p,
            groupValue: _selectedPkg,
            activeColor: AppColors.accent(dark),
            onChanged: (v) => setState(() => _selectedPkg = v!),
          );
        }),
      ],
    );
  }

  Widget _legendDot(Color color, String label, bool dark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textM(dark))),
      ],
    );
  }

  Widget _buildStepTwo(bool dark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Details',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textD(dark)),
          ),
          const SizedBox(height: 12),
          _field(_nameCtrl, 'Full Name', dark, required: true),
          _field(_phoneCtrl, 'Phone', dark, required: true),
          _field(_emailCtrl, 'Email', dark, required: true, email: true),
          _field(_notesCtrl, 'Notes (optional)', dark, maxLines: 3),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card(dark),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border(dark)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textD(dark),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                  style: TextStyle(color: AppColors.textM(dark)),
                ),
                Text('Time: $_selectedTime', style: TextStyle(color: AppColors.textM(dark))),
                Text('Guests: $_guests', style: TextStyle(color: AppColors.textM(dark))),
                Text('Package: $_selectedPkg', style: TextStyle(color: AppColors.textM(dark))),
                const Divider(),
                Text(
                  'Total: ${_fmt(_totalPrice)} EGP',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gold,
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
    String label,
    bool dark, {
    bool required = false,
    bool email = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        style: TextStyle(color: AppColors.textD(dark)),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.input(dark),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) {
          if (!required) return null;
          if (v == null || v.trim().isEmpty) return '$label is required';
          if (email && !v.contains('@')) return 'Enter a valid email';
          return null;
        },
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;
  final bool dark;

  const _StepIndicator({required this.step, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _dot(1, step >= 0, dark),
          Expanded(
            child: Container(
              height: 2,
              color: step >= 1 ? AppColors.accent(dark) : AppColors.border(dark),
            ),
          ),
          _dot(2, step >= 1, dark),
        ],
      ),
    );
  }

  Widget _dot(int n, bool active, bool dark) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: active ? AppColors.accent(dark) : AppColors.border(dark),
      child: Text(
        '$n',
        style: TextStyle(
          color: active ? Colors.white : AppColors.textM(dark),
          fontSize: 12,
        ),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final bool dark;
  final DateTime focusedMonth;
  final DateTime? selectedDate;
  final List<String> weekdays;
  final int daysInMonth;
  final int firstWeekday;
  final bool Function(int day) isPastDay;
  final bool Function(int day) isFullyBooked;
  final bool Function(int day) isAvailableDay;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<int> onSelectDay;

  const _CalendarCard({
    required this.dark,
    required this.focusedMonth,
    required this.selectedDate,
    required this.weekdays,
    required this.daysInMonth,
    required this.firstWeekday,
    required this.isPastDay,
    required this.isFullyBooked,
    required this.isAvailableDay,
    required this.onPrev,
    required this.onNext,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    final monthLabel =
        '${_months[focusedMonth.month - 1]} ${focusedMonth.year}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card(dark),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [AppColors.shadow(dark)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
              Text(
                monthLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textD(dark),
                ),
              ),
              IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
            ],
          ),
          Row(
            children: weekdays
                .map(
                  (w) => Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: TextStyle(color: AppColors.textL(dark), fontSize: 12),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
            ),
            itemCount: firstWeekday + daysInMonth,
            itemBuilder: (_, i) {
              if (i < firstWeekday) return const SizedBox();
              final day = i - firstWeekday + 1;
              final past = isPastDay(day);
              final fullyBooked = isFullyBooked(day);
              final available = isAvailableDay(day);
              final selected = selectedDate != null &&
                  selectedDate!.year == focusedMonth.year &&
                  selectedDate!.month == focusedMonth.month &&
                  selectedDate!.day == day;

              Color? dayColor;
              if (selected) {
                dayColor = AppColors.accent(dark);
              } else if (past) {
                dayColor = null;
              } else if (fullyBooked) {
                dayColor = const Color(0xFFFFEBEE);
              } else if (available) {
                dayColor = const Color(0xFFE8F5E9);
              }

              final textColor = selected
                  ? Colors.white
                  : past
                      ? AppColors.textL(dark)
                      : fullyBooked
                          ? const Color(0xFFE53935)
                          : available
                              ? const Color(0xFF2E7D32)
                              : AppColors.textD(dark);

              return GestureDetector(
                onTap: available ? () => onSelectDay(day) : null,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: dayColor,
                    borderRadius: BorderRadius.circular(8),
                    border: !selected && !past && (fullyBooked || available)
                        ? Border.all(
                            color: fullyBooked
                                ? const Color(0xFFE53935)
                                : const Color(0xFF4CAF50),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
}

class _BottomBar extends StatelessWidget {
  final bool dark;
  final int step;
  final int total;
  final String Function(int) fmt;
  final bool loading;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const _BottomBar({
    required this.dark,
    required this.step,
    required this.total,
    required this.fmt,
    required this.loading,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(dark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (step == 1)
              TextButton(onPressed: onBack, child: const Text('Back')),
            Expanded(
              child: Text(
                '${fmt(total)} EGP',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              onPressed: loading ? null : (step == 0 ? onNext : onSubmit),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent(dark),
                foregroundColor: Colors.white,
              ),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(step == 0 ? 'Continue' : 'Proceed to Payment'),
            ),
          ],
        ),
      ),
    );
  }
}
