import 'package:flutter/material.dart';

import 'package:festivo/features/owner/theme/owner_colors.dart';

class OwnerCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;

  const OwnerCard({super.key, required this.child, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OwnerColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: OwnerColors.shadow,
      ),
      child: child,
    );
  }
}

class OwnerBadge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const OwnerBadge._({required this.text, required this.bg, required this.fg});

  factory OwnerBadge.active() => const OwnerBadge._(
        text: 'Active',
        bg: OwnerColors.greenBg,
        fg: OwnerColors.greenText,
      );

  factory OwnerBadge.pending() => const OwnerBadge._(
        text: 'Pending',
        bg: OwnerColors.yellowBg,
        fg: OwnerColors.yellow,
      );

  factory OwnerBadge.confirmed() => const OwnerBadge._(
        text: 'Confirmed',
        bg: OwnerColors.greenBg,
        fg: OwnerColors.greenText,
      );

  factory OwnerBadge.completed() => const OwnerBadge._(
        text: 'Completed',
        bg: Color(0xFFF3F4F6),
        fg: OwnerColors.textMid,
      );

  factory OwnerBadge.cancelled() => const OwnerBadge._(
        text: 'Cancelled',
        bg: OwnerColors.redBg,
        fg: OwnerColors.red,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class OwnerStatCard extends StatelessWidget {
  final Widget icon;
  final String label;
  final String value;
  final bool isPrimary;
  final bool isGold;
  final Color? iconBg;
  final Color? valueColor;

  const OwnerStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isPrimary = false,
    this.isGold = false,
    this.iconBg,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: isPrimary ? OwnerColors.grad : null,
        color: isPrimary ? null : OwnerColors.white,
        borderRadius: BorderRadius.circular(14),
        border: isGold ? Border.all(color: OwnerColors.gold, width: 1.5) : null,
        boxShadow: OwnerColors.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isPrimary ? Colors.white.withOpacity(0.2) : (iconBg ?? OwnerColors.goldBg),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(child: icon),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isPrimary ? Colors.white.withOpacity(0.7) : OwnerColors.textGrey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isPrimary ? OwnerColors.white : (valueColor ?? OwnerColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}

class OwnerHdrPill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onTap;

  const OwnerHdrPill({super.key, required this.text, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OwnerIconBtn extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const OwnerIconBtn({
    super.key,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 16, color: fg),
      ),
    );
  }
}
