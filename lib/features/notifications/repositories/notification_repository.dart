import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
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

  Box<dynamic>? get _settingsBox {
    try {
      return HiveService.settings;
    } catch (_) {
      return null;
    }
  }

  String? get _currentUserId {
    try {
      final authId = _client?.auth.currentUser?.id;
      if (authId != null && authId.isNotEmpty) return authId;
      if (_client == null) {
        return HiveService.settings.get('active_user_id') as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _resolveUserId([String? userId]) {
    if (userId != null && userId.isNotEmpty) return userId;
    return _currentUserId ?? 'default';
  }

  String _clearedAtKey(String familyId, [String? userId]) =>
      'notifications_cleared_at_${familyId}_${_resolveUserId(userId)}';

  String _deletedIdsKey(String familyId, [String? userId]) =>
      'notifications_deleted_ids_${familyId}_${_resolveUserId(userId)}';

  DateTime? getClearedAt(String familyId, [String? userId]) {
    try {
      final box = _settingsBox;
      if (box == null) return null;
      final raw = box.get(_clearedAtKey(familyId, userId)) as String?;
      return raw != null ? DateTime.tryParse(raw) : null;
    } catch (_) {
      return null;
    }
  }

  Set<String> getDeletedIds(String familyId, [String? userId]) {
    try {
      final box = _settingsBox;
      if (box == null) return {};
      final raw = box.get(_deletedIdsKey(familyId, userId));
      if (raw is List) {
        return Set<String>.from(raw.map((e) => e.toString()));
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  // --- Local Hive Access ---

  List<SpendlyNotification> getLocalNotifications(String familyId, [String? userId]) {
    try {
      final box = HiveService.notifications;
      final list = <SpendlyNotification>[];
      final effectiveUserId = _resolveUserId(userId);
      final clearedAt = getClearedAt(familyId, effectiveUserId);
      final deletedIds = getDeletedIds(familyId, effectiveUserId);
      final keysToDelete = <dynamic>[];

      for (var key in box.keys) {
        final raw = box.get(key);
        if (raw is Map) {
          final item = SpendlyNotification.fromJson(Map<String, dynamic>.from(raw));
          if (item.familyId == familyId && (item.userId == null || item.userId == userId || item.userId == effectiveUserId)) {
            // Do not show self-created expense actions to the author
            if (userId != null && item.createdBy == userId && item.type.category == NotificationCategory.expense) {
              continue;
            }
            if (deletedIds.contains(item.id) || (clearedAt != null && !item.createdAt.isAfter(clearedAt))) {
              keysToDelete.add(key);
              continue;
            }
            list.add(item);
          }
        }
      }

      for (var k in keysToDelete) {
        box.delete(k);
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
      final effectiveUserId = _resolveUserId(notification.userId);
      final clearedAt = getClearedAt(notification.familyId, effectiveUserId);
      if (clearedAt != null && !notification.createdAt.isAfter(clearedAt)) {
        debugPrint('[NotificationRepository] Notification arrived before clearedAt timestamp, ignoring: ${notification.title}');
        return false;
      }

      final deletedIds = getDeletedIds(notification.familyId, effectiveUserId);
      if (deletedIds.contains(notification.id)) {
        debugPrint('[NotificationRepository] Notification was deleted by user, ignoring: ${notification.id}');
        return false;
      }

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

      final effectiveUserId = _resolveUserId(userId);
      final clearedAt = getClearedAt(familyId, effectiveUserId);
      final deletedIds = getDeletedIds(familyId, effectiveUserId);

      final List<SpendlyNotification> remoteList = [];
      final box = HiveService.notifications;
      final Map<String, dynamic> localUpdates = {};

      for (var json in response) {
        final notification = SpendlyNotification.fromJson(json);
        // Do not add self-created expense actions to the author's list
        if (userId != null && notification.createdBy == userId && notification.type.category == NotificationCategory.expense) {
          continue;
        }

        // Filter out individually deleted notifications
        if (deletedIds.contains(notification.id)) {
          continue;
        }

        // Filter out notifications created at or before user cleared all notifications
        if (clearedAt != null && !notification.createdAt.isAfter(clearedAt)) {
          continue;
        }

        // Preserve local isRead status if already read on device
        final existingRaw = box.get(notification.id);
        SpendlyNotification effective = notification;
        if (existingRaw is Map && existingRaw['is_read'] == true && !notification.isRead) {
          effective = notification.copyWith(
            isRead: true,
            readAt: DateTime.tryParse(existingRaw['read_at']?.toString() ?? ''),
          );
        }

        remoteList.add(effective);
        localUpdates[effective.id] = effective.toJson();
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
    final client = _client;
    final currentUserId = client?.auth.currentUser?.id;

    debugPrint('[NOTIFICATION] Notification creation started: key=${notification.notificationKey}, type=${notification.type.value}');
    debugPrint('[NOTIFICATION] Authenticated user: ${currentUserId ?? "none"}');

    // Strict Ownership & Race Condition Guard:
    // If the client is authenticated with Supabase, the notification must belong to the active user.
    SpendlyNotification effectiveNotification = notification;
    if (client != null && currentUserId != null && currentUserId.isNotEmpty) {
      if (notification.createdBy != null && notification.createdBy != currentUserId) {
        debugPrint('[NOTIFICATION] Rejected stale operation: creator (${notification.createdBy}) does not match authenticated user ($currentUserId)');
        return null;
      }
      if (notification.createdBy == null) {
        effectiveNotification = notification.copyWith(createdBy: currentUserId);
      }
    }

    debugPrint('[NOTIFICATION] Notification owner: ${effectiveNotification.createdBy}');
    debugPrint('[NOTIFICATION] Notification recipient: ${effectiveNotification.userId ?? "family"}');

    // 0. Idempotency check: if notificationKey is present, check if already stored anywhere
    if (effectiveNotification.notificationKey != null && effectiveNotification.notificationKey!.isNotEmpty) {
      final exists = await hasNotificationKey(effectiveNotification.familyId, effectiveNotification.notificationKey!);
      if (exists) {
        debugPrint('[NOTIFICATION] Duplicate notification key ignored: ${effectiveNotification.notificationKey}');
        return null;
      }
    }

    // 1. If not authored by current user (or personal reminder), save locally
    if (effectiveNotification.createdBy == null || effectiveNotification.createdBy != currentUserId || effectiveNotification.type.category != NotificationCategory.expense) {
      await saveLocalNotification(effectiveNotification);
    }

    // 2. If authenticated online, sync to Supabase for other family members
    if (client != null && client.auth.currentUser != null) {
      // Re-verify session identity immediately prior to writing to database
      final writeTimeUserId = client.auth.currentUser?.id;
      if (writeTimeUserId != currentUserId) {
        debugPrint('[NOTIFICATION] Rejected stale write: user switched from $currentUserId to $writeTimeUserId during execution');
        return null;
      }

      try {
        final payload = effectiveNotification.toJson();
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
          debugPrint('[NOTIFICATION] Notification created successfully: ${saved.id} (${saved.title})');
          return saved;
        }
      } catch (e) {
        debugPrint('[NOTIFICATION] Remote insert error: $e');
      }
    }

    return effectiveNotification;
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

  Future<void> deleteNotification(String notificationId, [String? familyId, String? userId]) async {
    try {
      // 1. Record in persistent deletedIds so it is never re-fetched from remote
      if (familyId != null) {
        final box = _settingsBox;
        if (box != null) {
          final effectiveUserId = _resolveUserId(userId);
          final deletedSet = getDeletedIds(familyId, effectiveUserId);
          deletedSet.add(notificationId);
          final list = deletedSet.toList();
          if (list.length > 500) {
            list.removeRange(0, list.length - 500);
          }
          await box.put(_deletedIdsKey(familyId, effectiveUserId), list);
        }
      }

      // 2. Local removal from Hive box
      await HiveService.notifications.delete(notificationId);

      // 3. Remote removal from Supabase
      final client = _client;
      if (client != null && client.auth.currentUser != null && !notificationId.startsWith('local_')) {
        await client.from('notifications').delete().eq('id', notificationId);
      }
    } catch (e) {
      debugPrint('[NotificationRepository] Error deleting notification: $e');
    }
  }

  Future<void> clearAllNotifications(String familyId, [String? userId]) async {
    try {
      final now = DateTime.now();
      final effectiveUserId = _resolveUserId(userId);

      // 1. Persist cleared_at timestamp so subsequent remote fetches skip older notifications
      final settings = _settingsBox;
      if (settings != null) {
        await settings.put(_clearedAtKey(familyId, effectiveUserId), now.toIso8601String());
      }

      // 2. Local removal from Hive box
      final box = HiveService.notifications;
      final keysToDelete = <dynamic>[];
      for (var key in box.keys) {
        final raw = box.get(key);
        if (raw is Map) {
          try {
            final n = SpendlyNotification.fromJson(Map<String, dynamic>.from(raw));
            if (n.familyId == familyId && (userId == null || n.userId == null || n.userId == userId || n.userId == effectiveUserId)) {
              keysToDelete.add(key);
            }
          } catch (_) {
            keysToDelete.add(key);
          }
        } else {
          keysToDelete.add(key);
        }
      }
      for (var key in keysToDelete) {
        await box.delete(key);
      }

      // 3. Remote removal from Supabase
      final client = _client;
      if (client != null && client.auth.currentUser != null) {
        try {
          if (userId != null && userId.isNotEmpty) {
            await client.from('notifications').delete().eq('family_id', familyId).eq('user_id', userId);
          }
          final currentUid = client.auth.currentUser?.id;
          if (currentUid != null) {
            await client.from('notifications').delete().eq('family_id', familyId).eq('created_by', currentUid);
          }
        } catch (e) {
          debugPrint('[NotificationRepository] Remote delete on clear all error: $e');
        }
      }
    } catch (e) {
      debugPrint('[NotificationRepository] Error clearing all notifications: $e');
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
    final effectiveUserId = client?.auth.currentUser?.id ?? (client == null && userId.isNotEmpty ? userId : null);
    if (effectiveUserId == null || effectiveUserId.isEmpty) {
      final msg = 'Cannot register token: User is not logged in.';
      debugPrint('[NOTIFICATION] $msg');
      return msg;
    }

    final deviceId = HiveService.deviceId;
    debugPrint('[NOTIFICATION] FCM token registration started');
    debugPrint('[NOTIFICATION] Authenticated user: $effectiveUserId');
    debugPrint('[NOTIFICATION] Device ID: $deviceId');

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

    if (client != null) {
      try {
        // 1. Try atomic security-definer RPC if deployed in Supabase
        await client.rpc('register_device_token', params: {
          'p_device_id': deviceId,
          'p_platform': platform,
          'p_push_token': token,
        });
        final msg = 'Device token registered successfully via RPC for user $effectiveUserId';
        debugPrint('[NOTIFICATION] FCM token registration completed: $msg');
        return msg;
      } catch (rpcErr) {
        debugPrint('[NOTIFICATION] RPC register_device_token notice (using direct upsert): $rpcErr');
      }

      try {
        await client.from('user_device_tokens').upsert(
          payload,
          onConflict: 'user_id,device_id',
        );

        final msg = 'Device token registered successfully for user $effectiveUserId';
        debugPrint('[NOTIFICATION] FCM token registration completed: $msg');
        return msg;
      } catch (e) {
        debugPrint('[NOTIFICATION] Upsert error (trying fallback): $e');
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
          debugPrint('[NOTIFICATION] FCM token registration completed: $msg');
          return msg;
        } catch (fallbackError) {
          final msg = 'Failed to register token in Supabase: $fallbackError';
          debugPrint('[NOTIFICATION] $msg');
          return msg;
        }
      }
    }
    return 'Device token saved locally';
  }

  Future<bool> unregisterDeviceToken({String? userId, String? deviceId}) async {
    final client = _client;
    final currentUserId = userId ?? client?.auth.currentUser?.id;
    final effectiveDeviceId = deviceId ?? HiveService.deviceId;

    if (client == null || currentUserId == null || currentUserId.isEmpty) {
      debugPrint('[NOTIFICATION] Cannot unregister device token: No active authenticated session');
      return false;
    }

    debugPrint('[NOTIFICATION] Unregistering FCM device token for user: $currentUserId, device: $effectiveDeviceId');
    try {
      // 0. Try atomic RPC if deployed in Supabase
      try {
        final currentToken = await FirebaseMessaging.instance.getToken();
        await client.rpc('deactivate_device_token', params: {
          'p_device_id': effectiveDeviceId,
          'p_push_token': currentToken,
        });
      } catch (_) {}

      // 1. Deactivate by user_id and device_id
      await client.from('user_device_tokens').update({
        'is_active': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', currentUserId).eq('device_id', effectiveDeviceId);

      // 2. Also deactivate by push token for current user to catch any token variant
      try {
        final currentToken = await FirebaseMessaging.instance.getToken();
        if (currentToken != null && currentToken.isNotEmpty) {
          await client.from('user_device_tokens').update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('user_id', currentUserId).eq('push_token', currentToken);
        }
      } catch (_) {}

      debugPrint('[NOTIFICATION] Successfully unregistered device token for user: $currentUserId');
      return true;
    } catch (e) {
      debugPrint('[NOTIFICATION] Error unregistering device token: $e');
      return false;
    }
  }
}
