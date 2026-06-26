import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// Data model for a stat card shown in the admin overview
// ─────────────────────────────────────────────
class StatModel {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color borderColor;

  const StatModel({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.borderColor,
  });
}
