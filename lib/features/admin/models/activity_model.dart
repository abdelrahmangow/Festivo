import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// Data model for a recent-activity item shown in admin overview
// ─────────────────────────────────────────────
class ActivityModel {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const ActivityModel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}
