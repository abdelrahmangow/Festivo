import 'package:flutter/material.dart';

class PaymentMethodOption {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  const PaymentMethodOption({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  bool get requiresReceipt => title == 'Vodafone Cash' || title == 'InstaPay';
}

const kPaymentMethods = [
  PaymentMethodOption(
    icon: Icons.payments_rounded,
    iconBg: Color(0xFFD4F0DF),
    iconColor: Color(0xFF4CAF50),
    title: 'Cash',
    subtitle: 'Pay on arrival at the venue',
  ),
  PaymentMethodOption(
    icon: Icons.dialpad_rounded,
    iconBg: Color(0xFFDDE0FF),
    iconColor: Color(0xFF7B9FD4),
    title: 'Vodafone Cash',
    subtitle: 'Pay via Vodafone Cash wallet',
  ),
  PaymentMethodOption(
    icon: Icons.bolt_rounded,
    iconBg: Color(0xFFFFF3CD),
    iconColor: Color(0xFFE8A87C),
    title: 'InstaPay',
    subtitle: 'Instant bank transfer via InstaPay',
  ),
];
