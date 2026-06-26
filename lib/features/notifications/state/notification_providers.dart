import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/features/notifications/models/app_notification.dart';
import 'package:festivo/features/notifications/services/notification_history_service.dart';
import 'package:festivo/features/notifications/services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (_) => NotificationService.instance,
);

final notificationHistoryServiceProvider = Provider<NotificationHistoryService>(
  (_) => NotificationHistoryService(),
);

final userNotificationsProvider =
    StreamProvider.autoDispose.family<List<AppNotification>, String>(
  (ref, userId) {
    if (userId.isEmpty) {
      return const Stream.empty();
    }
    return ref.watch(notificationHistoryServiceProvider).watchUserNotifications(userId);
  },
);

final unreadNotificationCountProvider =
    Provider.autoDispose.family<int, String>((ref, userId) {
  final notifications = ref.watch(userNotificationsProvider(userId));
  return notifications.maybeWhen(
    data: (items) => items.where((n) => !n.read).length,
    orElse: () => 0,
  );
});
