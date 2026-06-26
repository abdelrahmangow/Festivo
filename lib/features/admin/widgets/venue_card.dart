import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/core/constants/app_colors.dart';
import 'package:festivo/features/customer/domain/customer_models.dart';
import 'package:festivo/features/customer/state/venue_providers.dart';

class VenueCard extends ConsumerStatefulWidget {
  final Venue venue;

  const VenueCard({super.key, required this.venue});

  @override
  ConsumerState<VenueCard> createState() => _VenueCardState();
}

class _VenueCardState extends ConsumerState<VenueCard> {
  bool _updating = false;

  Future<void> _setStatus(String status) async {
    setState(() => _updating = true);
    try {
      await ref.read(venueServiceProvider).updateApprovalStatus(
            venueId: widget.venue.id,
            status: status,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == Venue.statusApproved
                ? 'Venue approved.'
                : status == Venue.statusRejected
                    ? 'Venue rejected.'
                    : 'Venue status updated.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update venue status.')),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final venue = widget.venue;
    final status = venue.status;
    final isPending = status == Venue.statusPending;
    final isApproved = status == Venue.statusApproved;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.softRose.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  venue.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              _SmallBadge(
                label: venue.category,
                bg: AppColors.softRose.withOpacity(0.18),
                color: AppColors.deepRose,
              ),
              const SizedBox(width: 6),
              _SmallBadge(
                label: status,
                bg: isApproved
                    ? AppColors.actGreenBg
                    : isPending
                        ? const Color(0xFFFEF9C3)
                        : const Color(0xFFFEE2E2),
                color: isApproved
                    ? const Color(0xFF15803D)
                    : isPending
                        ? const Color(0xFFCA8A04)
                        : const Color(0xFFEF4444),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Owner: ${venue.ownerName}',
            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
          Text(
            venue.location,
            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: _updating ? '…' : '✓ Approve',
                    bg: const Color(0xFF22C55E),
                    onTap: _updating
                        ? () {}
                        : () => _setStatus(Venue.statusApproved),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: _updating ? '…' : '✗ Reject',
                    bg: const Color(0xFFEF4444),
                    onTap: _updating
                        ? () {}
                        : () => _setStatus(Venue.statusRejected),
                  ),
                ),
              ],
            ),
          ],
          if (!isPending)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                isApproved ? 'No action required' : 'Venue rejected',
                style: TextStyle(
                  fontSize: 12,
                  color: isApproved
                      ? AppColors.textLight
                      : const Color(0xFFEF4444),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color color;

  const _SmallBadge({
    required this.label,
    required this.bg,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color bg;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
