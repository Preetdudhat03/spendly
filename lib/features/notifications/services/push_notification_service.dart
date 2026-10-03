import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:spendly/core/services/hive_service.dart';
import 'package:spendly/features/notifications/models/notification_model.dart';
import 'package:spendly/features/notifications/repositories/notification_repository.dart';
import 'package:spendly/features/notifications/services/local_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('[PushNotificationService] Background message received: ${message.messageId} - ${message.notification?.title}');
}

class PushNotificationService {
  final NotificationRepository _repo;
  final LocalNotificationService _localService;

  bool _isInitialized = false;
  StreamSubscription? _tokenRefreshSubscription;
  StreamSubscription? _foregroundMessageSubscription;
  StreamSubscription? _messageOpenedSubscription;

  PushNotificationService(this._repo, this._localService);

  Future<void> initialize({
    Function(String? deepLink)? onNotificationOpen,
  }) async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Firebase Core safely
      await Firebase.initializeApp();
      debugPrint('[PushNotificationService] Firebase initialized');

      final messaging = FirebaseMessaging.instance;

      // 2. Request permission (iOS / Android 13+)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('[PushNotificationService] Notification authorization status: ${settings.authorizationStatus}');

      // 3. Register background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 4. Retrieve initial message if app opened from terminated state
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageTap(initialMessage, onNotificationOpen);
      }

      // 5. Listen to app opens from background state
      _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleMessageTap(message, onNotificationOpen);
      });

      // 6. Foreground message listener
      _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // 7. Token management
      await syncDeviceToken();

      _tokenRefreshSubscription = messaging.onTokenRefresh.listen((newToken) {
        _registerToken(newToken);
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('[PushNotificationService] Firebase messaging initialization note: $e');
    }
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _foregroundMessageSubscription?.cancel();
    _messageOpenedSubscription?.cancel();
  }

  Future<String> syncDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        final msg = 'FCM returned empty token. Please check Google Play Services / Firebase setup.';
        debugPrint('[PushNotificationService] $msg');
        return msg;
      }
      return await _registerToken(token);
    } catch (e) {
      final msg = 'Error fetching FCM token: $e';
      debugPrint('[PushNotificationService] $msg');
      return msg;
    }
  }

  Future<String> _registerToken(String token) async {
    try {
      final authUserId = _repo.currentAuthUserId;
      final activeUserId = authUserId ?? (HiveService.settings.get('active_user_id') as String?);
      if (activeUserId == null || activeUserId.isEmpty) {
        final msg = 'Cannot sync token: User is not authenticated. Please log in.';
        debugPrint('[PushNotificationService] $msg');
        return msg;
      }

      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : (defaultTargetPlatform == TargetPlatform.android ? 'android' : 'web');

      final result = await _repo.registerDeviceToken(
        userId: activeUserId,
        token: token,
        platform: platform,
      );

      final previewToken = token.length > 15 ? token.substring(0, 15) : token;
      debugPrint('[PushNotificationService] FCM token ($previewToken...) register result: $result');
      return result;
    } catch (e) {
      final msg = 'Error registering FCM token: $e';
      debugPrint('[PushNotificationService] $msg');
      return msg;
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      final data = message.data;
      final notification = message.notification;

      final title = notification?.title ?? data['title'] ?? 'Spendly Update';
      final body = notification?.body ?? data['body'] ?? '';
      final typeStr = data['type'] as String? ?? 'expense_added';
      final deepLink = data['deep_link'] as String?;
      final type = NotificationType.fromString(typeStr);

      final notifKey = data['notification_id'] as String? ?? data['notification_key'] as String? ?? message.messageId ?? message.hashCode.toString();
      final deterministicId = notifKey.hashCode;

      await _localService.showNotification(
        id: deterministicId,
        tag: notifKey,
        title: title,
        body: body,
        type: type,
        deepLink: deepLink,
        payload: data,
      );
    } catch (e) {
      debugPrint('[PushNotificationService] Error processing foreground FCM message: $e');
    }
  }

  void _handleMessageTap(RemoteMessage message, Function(String? deepLink)? onNotificationOpen) {
    try {
      final data = message.data;
      final deepLink = data['deep_link'] as String?;
      debugPrint('[PushNotificationService] Notification tapped from FCM: $deepLink');
      onNotificationOpen?.call(deepLink);
    } catch (e) {
      debugPrint('[PushNotificationService] Error handling message tap: $e');
    }
  }
}
