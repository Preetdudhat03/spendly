import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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

  Future<bool> unregisterDeviceToken([String? userId]) async {
    try {
      final currentUid = userId ?? _repo.currentAuthUserId;
      if (currentUid == null || currentUid.isEmpty) {
        debugPrint('[NOTIFICATION] No authenticated user to unregister device token for');
        return false;
      }
      debugPrint('[PushNotificationService] Unregistering device token for user: $currentUid');

      // 1. Unregister active tokens for this user in Supabase
      final success = await _repo.unregisterDeviceToken(userId: currentUid);

      // 2. Invalidate the FCM token on Google Firebase servers so that Google rejects
      // any messages directed to this old installation token
      try {
        await FirebaseMessaging.instance.deleteToken();
        debugPrint('[PushNotificationService] FCM token deleted from Firebase client');
      } catch (fcmErr) {
        debugPrint('[PushNotificationService] Note: deleteToken error (may be offline/unsupported): $fcmErr');
      }

      return success;
    } catch (e) {
      debugPrint('[NOTIFICATION] Error in PushNotificationService.unregisterDeviceToken: $e');
      return false;
    }
  }

  Future<String> syncDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        final msg = 'FCM returned empty token. Please check Google Play Services / Firebase setup.';
        debugPrint('[NOTIFICATION] $msg');
        return msg;
      }
      return await _registerToken(token);
    } catch (e) {
      final msg = 'Error fetching FCM token: $e';
      debugPrint('[NOTIFICATION] $msg');
      return msg;
    }
  }

  Future<String> _registerToken(String token) async {
    try {
      final authUserId = _repo.currentAuthUserId;
      if (authUserId == null || authUserId.isEmpty) {
        final msg = 'Cannot sync token: User is not authenticated. Please log in.';
        debugPrint('[NOTIFICATION] $msg');
        return msg;
      }

      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : (defaultTargetPlatform == TargetPlatform.android ? 'android' : 'web');

      final result = await _repo.registerDeviceToken(
        userId: authUserId,
        token: token,
        platform: platform,
      );

      final previewToken = token.length > 8 ? '${token.substring(0, 8)}...' : token;
      debugPrint('[NOTIFICATION] FCM token ($previewToken) register result: $result');
      return result;
    } catch (e) {
      final msg = 'Error registering FCM token: $e';
      debugPrint('[NOTIFICATION] $msg');
      return msg;
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      final data = message.data;
      final notification = message.notification;

      final currentUid = _repo.currentAuthUserId;

      // Isolation Guard: Drop notifications targeted to another user
      final recipientId = data['user_id'] as String?;
      if (recipientId != null && recipientId.isNotEmpty && currentUid != null && recipientId != currentUid) {
        debugPrint('[NOTIFICATION] Dropping push message: targeted to $recipientId, but current user is $currentUid');
        return;
      }

      // Self-echo Guard: Drop push notification created by current user
      final creatorId = data['created_by'] as String?;
      if (creatorId != null && creatorId.isNotEmpty && creatorId == currentUid) {
        debugPrint('[NOTIFICATION] Dropping push message: echo of self-created event ($creatorId)');
        return;
      }

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
      debugPrint('[NOTIFICATION] Error processing foreground FCM message: $e');
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
