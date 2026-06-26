/// Central notification type constants — must match Cloud Functions payloads.
class NotificationTypes {
  NotificationTypes._();

  static const bookingSubmitted = 'booking_submitted';
  static const bookingNewRequest = 'booking_new_request';
  static const bookingApproved = 'booking_approved';
  static const bookingRejected = 'booking_rejected';
  static const bookingCancelled = 'booking_cancelled';
  static const bookingReminder = 'booking_reminder';
  static const reviewSubmitted = 'review_submitted';
  static const venueApproved = 'venue_approved';
  static const venueRejected = 'venue_rejected';
  static const venueSubmitted = 'venue_submitted';
}
