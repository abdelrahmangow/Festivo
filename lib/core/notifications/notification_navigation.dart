import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/core/notifications/notification_types.dart';
import 'package:festivo/features/admin/screens/admin_dashboard_screen.dart';
import 'package:festivo/features/admin/state/admin_providers.dart';
import 'package:festivo/features/customer/screens/customer_shell.dart';
import 'package:festivo/features/customer/screens/venue_details_screen.dart';
import 'package:festivo/features/customer/services/venue_service.dart';
import 'package:festivo/features/owner/screens/owner_booking_details_screen.dart';
import 'package:festivo/features/owner/screens/owner_shell.dart';

/// Global navigator key used for notification deep-linking.
final rootNavigatorKey = GlobalKey<NavigatorState>();

class NotificationNavigation {
  NotificationNavigation._();

  static Map<String, String>? _pending;

  static void handle(Map<String, String> data) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      _pending = Map<String, String>.from(data);
      debugPrint(
        '[FestivoFCM] Navigation deferred — navigator not ready '
        '(type=${data['type']})',
      );
      return;
    }

    _pending = null;
    _navigate(context, data);
  }

  static void processPending() {
    if (_pending == null) return;
    final data = _pending!;
    _pending = null;
    handle(data);
  }

  static void _navigate(BuildContext context, Map<String, String> data) {
    final container = ProviderScope.containerOf(context, listen: false);
    final type = data['type'] ?? '';
    final targetRole = data['targetRole'] ?? '';
    final bookingId = data['bookingId'] ?? '';
    final venueId = data['venueId'] ?? '';

    debugPrint(
      '[FestivoFCM] Navigating for type=$type role=$targetRole',
    );

    switch (targetRole) {
      case 'customer':
        _navigateCustomer(context, container, type, venueId);
        break;
      case 'venue_owner':
        _navigateOwner(context, container, type, bookingId);
        break;
      case 'admin':
        _navigateAdmin(container, type);
        break;
      default:
        debugPrint('[FestivoFCM] Unknown targetRole=$targetRole');
        break;
    }
  }

  static void _navigateCustomer(
    BuildContext context,
    ProviderContainer container,
    String type,
    String venueId,
  ) {
    container.read(customerTabIndexProvider.notifier).state = 2;

    switch (type) {
      case NotificationTypes.bookingSubmitted:
      case NotificationTypes.bookingApproved:
      case NotificationTypes.bookingRejected:
      case NotificationTypes.bookingReminder:
        if (venueId.isNotEmpty) {
          unawaited(_openVenueDetails(context, venueId));
        }
        break;
      default:
        break;
    }
  }

  static void _navigateOwner(
    BuildContext context,
    ProviderContainer container,
    String type,
    String bookingId,
  ) {
    switch (type) {
      case NotificationTypes.bookingNewRequest:
      case NotificationTypes.bookingCancelled:
        container.read(ownerTabIndexProvider.notifier).state = 1;
        if (bookingId.isNotEmpty) {
          OwnerBookingDetailsScreen.open(context, bookingId: bookingId);
        }
        break;
      case NotificationTypes.reviewSubmitted:
      case NotificationTypes.venueApproved:
      case NotificationTypes.venueRejected:
        container.read(ownerTabIndexProvider.notifier).state = 0;
        break;
      default:
        container.read(ownerTabIndexProvider.notifier).state = 1;
        break;
    }
  }

  static void _navigateAdmin(ProviderContainer container, String type) {
    if (type == NotificationTypes.venueSubmitted) {
      container.read(adminTabProvider.notifier).state = AdminTab.venues;
    }
  }

  static Future<void> _openVenueDetails(
    BuildContext context,
    String venueId,
  ) async {
    final venue = await VenueService().getVenue(venueId);
    if (venue == null || !context.mounted) {
      debugPrint('[FestivoFCM] Venue $venueId not found for navigation');
      return;
    }
    VenueDetailsScreen.open(context, venue);
  }
}
