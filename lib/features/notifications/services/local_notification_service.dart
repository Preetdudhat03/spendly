import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:spendly/features/notifications/models/notification_model.dart';

typedef NotificationTapCallback = void Function(String? payload);

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  NotificationTapCallback? onNotificationTap;

  // Channel IDs
  static const String channelAlerts = 'spendly_alerts';
  static const String channelBudget = 'spendly_budget';
  static const String channelFamily = 'spendly_family';
  static const String channelReminders = 'spendly_reminders';
  static const String channelSystem = 'spendly_system';

  Future<void> initialize({NotificationTapCallback? onNotificationTap}) async {
    if (_isInitialized) return;
    this.onNotificationTap = onNotificationTap;

    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('[LocalNotificationService] Timezone init warning: $e');
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[LocalNotificationService] Notification tapped: ${response.payload}');
          this.onNotificationTap?.call(response.payload);
        },
      );

      // Create Android Notification Channels
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              channelAlerts,
              'Spendly Alerts',
              description: 'Expense updates and critical alerts',
              importance: Importance.high,
              enableVibration: true,
            ),
          );

          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              channelBudget,
              'Spendly Budget Alerts',
              description: 'Threshold warnings and budget status',
              importance: Importance.high,
              enableVibration: true,
            ),
          );

          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              channelFamily,
              'Spendly Family Activity',
              description: 'Family member joins, leaves, and activity',
              importance: Importance.defaultImportance,
            ),
          );

          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              channelReminders,
              'Spendly Reminders',
              description: 'Daily expense logging reminders',
              importance: Importance.defaultImportance,
            ),
          );

          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              channelSystem,
              'Spendly System',
              description: 'Sync status and background updates',
              importance: Importance.low,
            ),
          );
        }
      }

      _isInitialized = true;
      debugPrint('[LocalNotificationService] Initialized successfully');
    } catch (e) {
      debugPrint('[LocalNotificationService] Initialization error: $e');
    }
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return true;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidPlugin?.requestNotificationsPermission();
        debugPrint('[LocalNotificationService] Android notification permission: $granted');
        return granted ?? false;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('[LocalNotificationService] iOS notification permission: $granted');
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('[LocalNotificationService] Permission request failed: $e');
    }
    return false;
  }

  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return true;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await androidPlugin?.areNotificationsEnabled() ?? false;
      }
    } catch (e) {
      debugPrint('[LocalNotificationService] Error checking permissions: $e');
    }
    return true;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required NotificationType type,
    String? deepLink,
    Map<String, dynamic>? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    String channelId;
    String channelName;
    Importance importance;
    Priority priority;

    switch (type.category) {
      case NotificationCategory.expense:
        channelId = channelAlerts;
        channelName = 'Spendly Alerts';
        importance = Importance.high;
        priority = Priority.high;
        break;
      case NotificationCategory.budget:
        channelId = channelBudget;
        channelName = 'Spendly Budget Alerts';
        importance = Importance.high;
        priority = Priority.high;
        break;
      case NotificationCategory.family:
        channelId = channelFamily;
        channelName = 'Spendly Family Activity';
        importance = Importance.defaultImportance;
        priority = Priority.defaultPriority;
        break;
      case NotificationCategory.reminder:
        channelId = channelReminders;
        channelName = 'Spendly Reminders';
        importance = Importance.defaultImportance;
        priority = Priority.defaultPriority;
        break;
      case NotificationCategory.insight:
        channelId = channelAlerts;
        channelName = 'Spendly Alerts';
        importance = Importance.defaultImportance;
        priority = Priority.defaultPriority;
        break;
      case NotificationCategory.system:
        channelId = channelSystem;
        channelName = 'Spendly System';
        importance = Importance.low;
        priority = Priority.low;
        break;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: importance,
      priority: priority,
      icon: '@mipmap/launcher_icon',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payloadMap = {
      'type': type.value,
      'deep_link': deepLink,
      ...?payload,
    };

    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: jsonEncode(payloadMap),
      );
      debugPrint('[LocalNotificationService] Showed notification: $title');
    } catch (e) {
      debugPrint('[LocalNotificationService] Failed to show notification: $e');
    }
  }

  Future<void> scheduleDailyReminder({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      await _plugin.cancel(id: id); // Cancel previous reminder with this ID

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        channelReminders,
        'Spendly Reminders',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/launcher_icon',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: jsonEncode({
          'type': NotificationType.expenseReminder.value,
          'deep_link': '/add',
        }),
      );

      debugPrint('[LocalNotificationService] Daily reminder scheduled at $hour:$minute');
    } catch (e) {
      debugPrint('[LocalNotificationService] Error scheduling daily reminder: $e');
    }
  }

  Future<void> cancelReminder(int id) async {
    try {
      await _plugin.cancel(id: id);
      debugPrint('[LocalNotificationService] Cancelled reminder id: $id');
    } catch (e) {
      debugPrint('[LocalNotificationService] Error cancelling reminder: $e');
    }
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
      debugPrint('[LocalNotificationService] Cancelled all notifications');
    } catch (e) {
      debugPrint('[LocalNotificationService] Error cancelling all: $e');
    }
  }
}
