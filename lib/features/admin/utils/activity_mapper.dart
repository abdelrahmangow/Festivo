import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../../customer/domain/customer_booking.dart';
import '../../customer/domain/customer_models.dart';
import '../../customer/domain/venue_review.dart';
import '../models/activity_model.dart';
import 'relative_time.dart';

class _TimedActivity {
  final DateTime occurredAt;
  final ActivityModel activity;

  const _TimedActivity({
    required this.occurredAt,
    required this.activity,
  });
}

List<ActivityModel> buildRecentActivities({
  required List<UserModel> users,
  required List<Venue> venues,
  required List<CustomerBooking> bookings,
  required List<VenueReview> reviews,
  int limit = 20,
}) {
  final events = <_TimedActivity>[];

  for (final user in users) {
    final createdAt = user.createdAt;
    if (createdAt == null || user.name.isEmpty) continue;
    events.add(
      _TimedActivity(
        occurredAt: createdAt,
        activity: ActivityModel(
          title: 'New user registered',
          subtitle: '${user.name} · ${formatRelativeTime(createdAt)}',
          icon: Icons.person_outline_rounded,
          iconColor: AppColors.borderBlue,
          iconBg: AppColors.actBlueBg,
        ),
      ),
    );
  }

  for (final venue in venues) {
    final createdAt = venue.createdAt;
    if (createdAt != null) {
      events.add(
        _TimedActivity(
          occurredAt: createdAt,
          activity: ActivityModel(
            title: venue.isPending
                ? 'Venue pending verification'
                : 'New venue submitted',
            subtitle: '${venue.name} · ${formatRelativeTime(createdAt)}',
            icon: venue.isPending
                ? Icons.timer_outlined
                : Icons.storefront_outlined,
            iconColor:
                venue.isPending ? AppColors.borderOrange : AppColors.borderGold,
            iconBg: AppColors.actYellowBg,
          ),
        ),
      );
    }

    final updatedAt = venue.updatedAt;
    if (updatedAt != null && _isStatusChangeEvent(createdAt, updatedAt)) {
      if (venue.isApproved) {
        events.add(
          _TimedActivity(
            occurredAt: updatedAt,
            activity: ActivityModel(
              title: 'New venue approved',
              subtitle: '${venue.name} · ${formatRelativeTime(updatedAt)}',
              icon: Icons.check_rounded,
              iconColor: AppColors.borderGreen,
              iconBg: AppColors.actGreenBg,
            ),
          ),
        );
      } else if (venue.isRejected) {
        events.add(
          _TimedActivity(
            occurredAt: updatedAt,
            activity: ActivityModel(
              title: 'Venue rejected',
              subtitle: '${venue.name} · ${formatRelativeTime(updatedAt)}',
              icon: Icons.close_rounded,
              iconColor: AppColors.softRose,
              iconBg: AppColors.softRose.withOpacity(0.12),
            ),
          ),
        );
      }
    }
  }

  for (final booking in bookings) {
    events.add(
      _TimedActivity(
        occurredAt: booking.createdAt,
        activity: ActivityModel(
          title: 'New booking created',
          subtitle:
              '${booking.venueName} · ${formatRelativeTime(booking.createdAt)}',
          icon: Icons.calendar_month_rounded,
          iconColor: AppColors.borderGold,
          iconBg: AppColors.actYellowBg,
        ),
      ),
    );

    if (booking.bookingStatus == 'Cancelled') {
      final cancelledAt = booking.updatedAt ?? booking.createdAt;
      events.add(
        _TimedActivity(
          occurredAt: cancelledAt,
          activity: ActivityModel(
            title: 'Booking cancelled',
            subtitle:
                '${booking.venueName} · ${formatRelativeTime(cancelledAt)}',
            icon: Icons.event_busy_outlined,
            iconColor: AppColors.softRose,
            iconBg: AppColors.softRose.withOpacity(0.12),
          ),
        ),
      );
    }
  }

  for (final review in reviews) {
    events.add(
      _TimedActivity(
        occurredAt: review.createdAt,
        activity: ActivityModel(
          title: 'New review submitted',
          subtitle:
              '${review.userName} · ${review.venueName} · ${formatRelativeTime(review.createdAt)}',
          icon: Icons.star_outline_rounded,
          iconColor: AppColors.borderGold,
          iconBg: AppColors.actYellowBg,
        ),
      ),
    );
  }

  events.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  final seen = <String>{};
  final unique = <ActivityModel>[];
  for (final event in events) {
    final key =
        '${event.activity.title}|${event.activity.subtitle}|${event.occurredAt.millisecondsSinceEpoch}';
    if (seen.add(key)) {
      unique.add(event.activity);
    }
    if (unique.length >= limit) break;
  }

  return unique;
}

bool _isStatusChangeEvent(DateTime? createdAt, DateTime updatedAt) {
  if (createdAt == null) return true;
  return updatedAt.difference(createdAt).inMinutes >= 1;
}
