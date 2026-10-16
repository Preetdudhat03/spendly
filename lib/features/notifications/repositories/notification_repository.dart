import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spendly/core/services/hive_service.dart';
import 'package:spendly/features/notifications/models/notification_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

class NotificationRepository {
  final SupabaseClient? _clientOverride;

  NotificationRepository({SupabaseClient? client}) : _clientOverride = client;

  SupabaseClient? get _client {
    if (_clientOverride != null) return _clientOverride;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // --- Local Hive Access ---

  List<SpendlyNotification> getLocalNotifications(String familyId, [String? userId]) {
    try {
      final box = HiveService.notifications;
      final list = <SpendlyNotification>[];

      for (var raw in box.values) {
        if (raw is Map) {
          final item = SpendlyNotification.fromJson(Map<String, dynamic>.from(raw));
          if (item.familyId == familyId && (item.userId == null || item.userId == userId)) {
            // Do not show self-created expense actions to the author
            if (userId != null && item.createdBy == userId && item.type.category == NotificationCategory.expense) {
              continue;
            }
            list.add(item);
          }
        }
      }

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      debugPrint('[NotificationRepository] Error getting local notifications: $e');
      return [];
    }
  }

  int getLocalUnreadCount(String familyId, [String? userId]) {
    try {
      final list = getLocalNotifications(familyId, userId);
      return list.where((n) => !n.isRead).length;
    } catch (e) {
      return 0;
    }
  }

  bool hasLocalNotificationKey(String familyId, String notificationKey) {
    try {
      final box = HiveService.notifications;
      for (var key in box.keys) {
        final raw = box.get(key);
        if (raw is Map) {
          final existing = SpendlyNotification.fromJson(Map<String, dynamic>.from(raw));
          if (existing.familyId == familyId &&
              existing.notificationKey == notificationKey) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasNotificationKey(String familyId, String notificationKey) async {
    if (hasLocalNotificationKey(familyId, notificationKey)) {
      return true;
    }

    final client = _client;
    if (client != null && client.auth.currentUser != null) {
      try {
        final response = await client
            .from('notifications')
            .select('id')
            .eq('family_id', familyId)
            .eq('notification_key', notificationKey)
            .limit(1)
            .maybeSingle();
        return response != null;
      } catch (e) {
        debugPrint('[NotificationRepository] Remote key check error: $e');
      }
    }

    return false;
  }

  Future<bool> saveLocalNotification(SpendlyNotification notification) async {
    try {
      final box = HiveService.notifications;
      // Idempotency check: if notificationKey is present, check if already stored
      if (notification.notificationKey != null && notification.notificationKey!.isNotEmpty) {
        if (hasLocalNotificationKey(notification.familyId, notification.notificationKey!)) {
          debugPrint('[NotificationRepository] Duplicate local notification ignored: ${notification.notificationKey}');
          return false;
        }
      }

      await box.put(notification.id, notification.toJson());
      return true;
    } catch (e) {
      debugPrint('[NotificationRepository] Error saving local notification: $e');
      return false;
    }
  }

  // --- Supabase Remote Operations ---

  Future<List<SpendlyNotification>> fetchRemoteNotifications({
    required String familyId,
    String? userId,
    int limit = 40,
    int offset = 0,
  }) async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) {
      return getLocalNotifications(familyId, userId);
    }

    try {
      var query = client
          .from('notifications')
          .select()
          .eq('family_id', familyId);

      if (userId != null && userId.isNotEmpty) {
        query = query.or('user_id.is.null,user_id.eq.$userId');
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final List<SpendlyNotification> remoteList = [];
      final box = HiveService.notifications;
      final Map<String, dynamic> localUpdates = {};

      for (var json in response) {
        final notification = SpendlyNotification.fromJson(json);
        // Do not add self-created expense actions to the author's list
        if (userId != null && notification.createdBy == userId && notification.type.category == NotificationCategory.expense) {
          continue;
        }
        remoteList.add(notification);
        localUpdates[notification.id] = notification.toJson();
      }

      // Sync into Hive cache
      if (localUpdates.isNotEmpty) {
        await box.putAll(localUpdates);
      }

      return remoteList;
    } catch (e) {
      debugPrint('[NotificationRepository] Remote fetch failed (using local cache): $e');
      return getLocalNotifications(familyId, userId);
    }
  }

  Future<SpendlyNotification?> createNotification(SpendlyNotification notification) async {
    // 0. Idempotency check: if notificationKey is present, check if already stored anywhere
    if (notification.notificationKey != null && notification.notificationKey!.isNotEmpty) {
      final exists = await hasNotificationKey(notification.familyId, notification.notificationKey!);
      if (exists) {
        debugPrint('[NotificationRepository] Duplicate notification key ignored: ${notification.notificationKey}');
        return null;
      }
    }

    // 1. If not authored by current user (or personal reminder), save locally
    final client = _client;
    final currentUserId = client?.auth.currentUser?.id;
    if (notification.createdBy == null || notification.createdBy != currentUserId || notification.type.category != NotificationCategory.expense) {
      await saveLocalNotification(notification);
    }

    // 2. If authenticated online, sync to Supabase for other family members
    if (client != null && client.auth.currentUser != null) {
      try {
        final payload = notification.toJson();
        final response = await client
            .from('notifications')
            .upsert(
              payload,
              onConflict: 'id',
            )
            .select()
            .maybeSingle();

        if (response != null) {
          final saved = SpendlyNotification.fromJson(response);
          debugPrint('[NotificationRepository] Successfully inserted remote notification: ${saved.title}');
          return saved;
        }
      } catch (e) {
        debugPrint('[NotificationRepository] Remote insert error: $e');
      }
    }

    return notification;
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      // 1. Local update
      final box = HiveService.notifications;
      final raw = box.get(notificationId);
      if (raw is Map) {
        final n = SpendlyNotification.fromJson(Map<String, dynamic>.from(raw));
        final updated = n.copyWith(isRead: true, readAt: DateTime.now());
        await box.put(notificationId, updated.toJson());
      }

      // 2. Remote update
      final client = _client;
      if (client != null && client.auth.currentUser != null && !notificationId.startsWith('local_')) {
        await client
            .from('notifications')
            .update({
              'is_read': true,
              'read_at': DateTime.now().toIso8601String(),
            })
            .eq('id', notificationId);
      }
    } catch (e) {
      debugPrint('[NotificationRepository] Error marking as read: $e');
    }
  }

  Future<void> markAllAsRead(String familyId, [String? userId]) async {
    try {
      // 1. Local update
      final box = HiveService.notifications;
      final now = DateTime.now();
      for (var key in box.keys) {
        final raw = box.get(key);
        if (raw is Map) {
          final n = SpendlyNotification.fromJson(Map<String, dynamic>.from(raw));
          if (n.familyId == familyId && (n.userId == null || n.userId == userId) && !n.isRead) {
            final updated = n.copyWith(isRead: true, readAt: now);
            await box.put(key, updated.toJson());
          }
        }
      }

      // 2. Remote update
      final client = _client;
      if (client != null && client.auth.currentUser != null) {
        var query = client.from('notifications').update({
          'is_read': true,
          'read_at': now.toIso8601String(),
        }).eq('family_id', familyId).eq('is_read', false);

        if (userId != null && userId.isNotEmpty) {
          query = query.or('user_id.is.null,user_id.eq.$userId');
        }

        await query;
      }
    } catch (e) {
      debugPrint('[NotificationRepository] Error marking all as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      // 1. Local removal
      await HiveService.notifications.delete(notificationId);

      // 2. Remote removal
      final client = _client;
      if (client != null && client.auth.currentUser != null && !notificationId.startsWith('local_')) {
        await client.from('notifications').delete().eq('id', notificationId);
      }
    } catch (e) {
      debugPrint('[NotificationRepository] Error deleting notification: $e');
    }
  }

  // --- Preferences ---

  Future<NotificationPreferences> getPreferences(String userId) async {
    try {
      // 1. Check local Hive preferences
      final box = HiveService.notificationPreferences;
      final raw = box.get(userId);
      if (raw is Map) {
        return NotificationPreferences.fromJson(Map<String, dynamic>.from(raw));
      }

      // 2. Fallback to Supabase remote preferences
      final client = _client;
      if (client != null && client.auth.currentUser != null) {
        final remote = await client
            .from('notification_preferences')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        if (remote != null) {
          final prefs = NotificationPreferences.fromJson(remote);
          await box.put(userId, prefs.toJson());
          return prefs;
        }
      }
    } catch (e) {
      debugPrint('[NotificationRepository] Error loading preferences: $e');
    }

    return const NotificationPreferences();
  }

  Future<void> updatePreferences(String userId, NotificationPreferences preferences) async {
    try {
      // 1. Local save
      final box = HiveService.notificationPreferences;
      await box.put(userId, preferences.toJson());

      // 2. Remote save
      final client = _client;
      if (client != null && client.auth.currentUser != null) {
        await client.from('notification_preferences').upsert({
          'user_id': userId,
          ...preferences.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id');
      }
    } catch (e) {
      debugPrint('[NotificationRepository] Error saving preferences: $e');
    }
  }

  String? get currentAuthUserId => _client?.auth.currentUser?.id;

  // --- Multi-Device Push Tokens ---

  Future<String> registerDeviceToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    final client = _client;
    final effectiveUserId = client?.auth.currentUser?.id ?? (userId.isNotEmpty ? userId : null);
    if (client == null || effectiveUserId == null || effectiveUserId.isEmpty) {
      final msg = 'Cannot register token: User is not logged in.';
      debugPrint('[NotificationRepository] $msg');
      return msg;
    }

    final deviceId = HiveService.deviceId;
    final payload = {
      'user_id': effectiveUserId,
      'device_id': deviceId,
      'platform': platform,
      'push_token': token,
      'device_token': token,
      'is_active': true,
      'last_seen_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      await client.from('user_device_tokens').upsert(
        payload,
        onConflict: 'user_id,device_id',
      );

      final msg = 'Device token registered successfully for user $effectiveUserId';
      debugPrint('[NotificationRepository] $msg');
      return msg;
    } catch (e) {
      debugPrint('[NotificationRepository] Upsert error (trying fallback): $e');
      try {
        final existing = await client
            .from('user_device_tokens')
            .select('id')
            .eq('user_id', effectiveUserId)
            .eq('device_id', deviceId)
            .maybeSingle();

        if (existing != null && existing['id'] != null) {
          await client.from('user_device_tokens').update({
            'push_token': token,
            'device_token': token,
            'is_active': true,
            'last_seen_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', existing['id']);
        } else {
          await client.from('user_device_tokens').insert(payload);
        }
        final msg = 'Device token registered via fallback for user $effectiveUserId';
        debugPrint('[NotificationRepository] $msg');
        return msg;
      } catch (fallbackError) {
        final msg = 'Failed to register token in Supabase: $fallbackError';
        debugPrint('[NotificationRepository] $msg');
        return msg;
      }
    }
  }
}
