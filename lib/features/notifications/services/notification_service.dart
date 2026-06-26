import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:festivo/core/notifications/notification_navigation.dart';
import 'package:festivo/firebase/firebase_options.dart';

/// Top-level background handler — must initialize Firebase in this isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  NotificationService.log(
    'Background message received '
    '(id=${message.messageId}, type=${message.data['type']})',
  );
}

class NotificationRegistrationResult {
  final bool success;
  final String? token;
  final String? error;
  final NotificationPermissionStatus permission;

  const NotificationRegistrationResult({
    required this.success,
    required this.permission,
    this.token,
    this.error,
  });
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _logTag = '[FestivoFCM]';

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'festivo_default',
    'Festivo Notifications',
    description: 'Booking updates, venue alerts, and reminders',
    importance: Importance.high,
  );

  bool _initialized = false;
  bool _backgroundHandlerRegistered = false;
  String? _registeredUserId;
  Map<String, String>? _pendingInitialMessageData;

  static void log(String message) {
    debugPrint('$_logTag $message');
  }

  /// Registers the background handler. Must run before [runApp].
  void registerBackgroundHandler() {
    if (_backgroundHandlerRegistered) return;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _backgroundHandlerRegistered = true;
    log('Background message handler registered');
  }

  Future<void> initialize() async {
    if (_initialized) return;

    registerBackgroundHandler();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_androidChannel);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpened);
    _messaging.onTokenRefresh.listen(_onTokenRefresh);

    _initialized = true;
    log('NotificationService initialized');
  }

  Future<NotificationPermissionStatus> requestPermission() async {
    if (kIsWeb) {
      log('Push notifications are not configured for web');
      return NotificationPermissionStatus.denied;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted =
          await androidPlugin?.requestNotificationsPermission() ?? true;
      log('Android POST_NOTIFICATIONS granted=$granted');
      if (granted == false) {
        return NotificationPermissionStatus.denied;
      }
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    log('FCM permission status=${settings.authorizationStatus.name}');

    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
      case AuthorizationStatus.provisional:
        return NotificationPermissionStatus.granted;
      case AuthorizationStatus.denied:
        return NotificationPermissionStatus.denied;
      case AuthorizationStatus.notDetermined:
        return NotificationPermissionStatus.notDetermined;
    }
  }

  Future<NotificationRegistrationResult> registerForUser(String userId) async {
    if (userId.isEmpty) {
      return const NotificationRegistrationResult(
        success: false,
        permission: NotificationPermissionStatus.denied,
        error: 'Empty user id',
      );
    }

    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      log('Push notifications are not supported on this platform');
      return const NotificationRegistrationResult(
        success: false,
        permission: NotificationPermissionStatus.denied,
        error: 'Unsupported platform',
      );
    }

    await initialize();
    _registeredUserId = userId;
    log('Registering FCM token for user=$userId');

    try {
      final permission = await requestPermission();
      if (permission == NotificationPermissionStatus.denied) {
        await _saveToken(userId: userId, token: null, enabled: false);
        return NotificationRegistrationResult(
          success: false,
          permission: permission,
          error: 'Notification permission denied',
        );
      }

      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        log('FCM getToken returned null/empty');
        return NotificationRegistrationResult(
          success: false,
          permission: permission,
          error: 'FCM token unavailable',
        );
      }

      await _saveToken(userId: userId, token: token, enabled: true);
      log('FCM token saved (${token.substring(0, 12)}...)');

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        log('App opened from terminated state via notification');
        _queueInitialMessage(initialMessage.data);
      }

      return NotificationRegistrationResult(
        success: true,
        permission: permission,
        token: token,
      );
    } catch (error, stackTrace) {
      log('registerForUser failed: $error\n$stackTrace');
      return NotificationRegistrationResult(
        success: false,
        permission: NotificationPermissionStatus.denied,
        error: error.toString(),
      );
    }
  }

  /// Processes deferred notification actions once the navigator is ready.
  void processPendingActions() {
    if (_pendingInitialMessageData != null) {
      final data = _pendingInitialMessageData!;
      _pendingInitialMessageData = null;
      log('Processing deferred initial notification tap');
      _handleNotificationTap(data);
    }
    NotificationNavigation.processPending();
  }

  Future<void> clearRegistration(String userId) async {
    if (userId.isEmpty) return;
    log('Clearing FCM registration for user=$userId');

    try {
      await _messaging.deleteToken();
    } catch (error) {
      log('deleteToken failed: $error');
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'notificationsEnabled': false,
      }, SetOptions(merge: true));
    } catch (error) {
      log('Failed to clear token in Firestore: $error');
    }

    if (_registeredUserId == userId) {
      _registeredUserId = null;
    }
  }

  Future<void> _onTokenRefresh(String token) async {
    final userId = _registeredUserId;
    if (userId == null || userId.isEmpty) {
      log('Token refreshed but no registered user');
      return;
    }
    log('FCM token refreshed (${token.substring(0, 12)}...)');
    await _saveToken(userId: userId, token: token, enabled: true);
  }

  Future<void> _saveToken({
    required String userId,
    required String? token,
    required bool enabled,
  }) async {
    final updates = <String, dynamic>{
      'notificationsEnabled': enabled,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    };
    if (token != null && token.isNotEmpty) {
      updates['fcmToken'] = token;
    } else {
      updates['fcmToken'] = FieldValue.delete();
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set(updates, SetOptions(merge: true));

    if (token != null && token.isNotEmpty) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final saved = doc.data()?['fcmToken'] as String?;
      if (saved != token) {
        throw StateError('FCM token verification failed after Firestore write');
      }
      log('FCM token verified in Firestore for user=$userId');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    log('Foreground message (type=${message.data['type']})');
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'];
    final body = notification?.body ?? message.data['body'];
    if (title == null || body == null) {
      log('Foreground message missing title/body — skipped local display');
      return;
    }

    unawaited(
      _localNotifications.show(
        message.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: _encodePayload(message.data),
      ),
    );
  }

  void _onNotificationOpened(RemoteMessage message) {
    log('Notification opened (type=${message.data['type']})');
    _handleNotificationTap(message.data);
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    log('Local notification tapped');
    _handleNotificationTap(_decodePayload(payload));
  }

  void _queueInitialMessage(Map<String, dynamic> data) {
    final stringData = <String, String>{};
    data.forEach((key, value) {
      stringData['$key'] = '$value';
    });
    _pendingInitialMessageData = stringData;
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final stringData = <String, String>{};
    data.forEach((key, value) {
      stringData['$key'] = '$value';
    });
    NotificationNavigation.handle(stringData);
  }

  String _encodePayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  Map<String, String> _decodePayload(String payload) {
    final result = <String, String>{};
    for (final part in payload.split('&')) {
      final index = part.indexOf('=');
      if (index <= 0) continue;
      result[part.substring(0, index)] = part.substring(index + 1);
    }
    return result;
  }
}

enum NotificationPermissionStatus { granted, denied, notDetermined }
