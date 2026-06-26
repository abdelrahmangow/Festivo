import 'package:festivo/features/notifications/services/notification_service.dart';

/// Initializes FCM and registers the device token for [userId].
Future<NotificationRegistrationResult> bootstrapNotifications(String userId) async {
  if (userId.isEmpty) {
    NotificationService.log('bootstrap skipped — empty userId');
    return const NotificationRegistrationResult(
      success: false,
      permission: NotificationPermissionStatus.denied,
      error: 'Empty user id',
    );
  }

  final service = NotificationService.instance;
  final result = await service.registerForUser(userId);
  if (result.success) {
    NotificationService.log('bootstrap succeeded for user=$userId');
  } else {
    NotificationService.log(
      'bootstrap failed for user=$userId: ${result.error}',
    );
  }
  return result;
}
