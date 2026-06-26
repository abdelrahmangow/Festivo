import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:festivo/features/notifications/models/app_notification.dart';

class NotificationHistoryService {
  NotificationHistoryService({FirebaseFirestore? firestore})
      : _notifications = (firestore ?? FirebaseFirestore.instance)
            .collection('notifications');

  final CollectionReference<Map<String, dynamic>> _notifications;

  Stream<List<AppNotification>> watchUserNotifications(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs.map(AppNotification.fromDoc).toList(),
        );
  }

  Future<void> markAsRead(String notificationId) async {
    if (notificationId.isEmpty) return;
    await _notifications.doc(notificationId).update({'read': true});
  }

  Future<void> markAllAsRead(String userId) async {
    if (userId.isEmpty) return;
    final snap = await _notifications
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    if (snap.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> setNotificationsEnabled({
    required String userId,
    required bool enabled,
  }) async {
    if (userId.isEmpty) return;
    await FirebaseFirestore.instance.collection('users').doc(userId).set(
      {'notificationsEnabled': enabled},
      SetOptions(merge: true),
    );
  }
}
