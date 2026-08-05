import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:spendly/models/hive/expense_model.dart';
import 'package:spendly/models/hive/family_model.dart';
import 'package:spendly/models/hive/family_member_model.dart';
import 'package:spendly/models/hive/budget_model.dart';
import 'package:spendly/models/hive/profile_model.dart';
import 'package:spendly/models/hive/pending_operation_model.dart';
import 'package:spendly/models/hive/sync_metadata_model.dart';

class HiveService {
  static const String guestNamespace = 'guest_local';
  static const String profilesBox = 'profiles';
  static const String familiesBox = 'families';
  static const String familyMembersBox = 'family_members';
  static const String expensesBox = 'expenses';
  static const String budgetsBox = 'budgets';
  static const String settingsBox = 'settings';
  static const String pendingOperationsBox = 'pending_operations';
  static const String syncMetadataBox = 'sync_metadata';
  static const String analyticsCacheBox = 'analytics_cache';
  static const String syncLogBox = 'sync_log';

  static String _activeUserId = guestNamespace;
  static List<int>? _encryptionKey;
  static String? _cachedDeviceId;

  static String get currentUserId => _activeUserId;

  static String get deviceId {
    if (_cachedDeviceId != null) return _cachedDeviceId!;
    final stored = settings.get('device_id') as String?;
    if (stored != null && stored.isNotEmpty) {
      _cachedDeviceId = stored;
      return stored;
    }
    final newId = const Uuid().v4();
    settings.put('device_id', newId);
    _cachedDeviceId = newId;
    return newId;
  }

  static String getUserBoxName(String baseName, [String? userId]) {
    final uid = (userId != null && userId.isNotEmpty) ? userId : _activeUserId;
    return '${baseName}_$uid';
  }

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ExpenseModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(FamilyModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(FamilyMemberModelAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(BudgetModelAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ProfileModelAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(PendingOperationModelAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(SyncMetadataModelAdapter());

    // 1. Always open global settings box first (unencrypted)
    await Hive.openBox<dynamic>(settingsBox);

    // 2. Initialize encryption key
    _initEncryptionKey();

    // 3. Ensure device ID exists
    deviceId;

    // 4. Open default guest boxes or active user boxes if active_user_id exists
    final activeId = settings.get('active_user_id') as String?;
    final targetUser = (activeId != null && activeId.isNotEmpty) ? activeId : guestNamespace;
    await openUserBoxes(targetUser);

    debugPrint('Hive Service initialized successfully for user: $_activeUserId (device: $deviceId)');
  }

  static void _initEncryptionKey() {
    final storedKeyHex = settings.get('hive_encryption_key') as String?;
    if (storedKeyHex != null && storedKeyHex.isNotEmpty) {
      _encryptionKey = storedKeyHex.split(',').map((e) => int.parse(e)).toList();
    } else {
      _encryptionKey = Hive.generateSecureKey();
      settings.put('hive_encryption_key', _encryptionKey!.join(','));
    }
  }

  static Future<void> openUserBoxes(String userId) async {
    final cleanUserId = userId.isNotEmpty ? userId : guestNamespace;
    _activeUserId = cleanUserId;

    final cipher = _encryptionKey != null ? HiveAesCipher(_encryptionKey!) : null;

    // Open user-scoped boxes cleanly
    await Future.wait([
      _openEncryptedBox<ProfileModel>(getUserBoxName(profilesBox, cleanUserId), cipher),
      _openEncryptedBox<FamilyModel>(getUserBoxName(familiesBox, cleanUserId), cipher),
      _openEncryptedBox<FamilyMemberModel>(getUserBoxName(familyMembersBox, cleanUserId), cipher),
      _openEncryptedBox<ExpenseModel>(getUserBoxName(expensesBox, cleanUserId), cipher),
      _openEncryptedBox<BudgetModel>(getUserBoxName(budgetsBox, cleanUserId), cipher),
      _openEncryptedBox<PendingOperationModel>(getUserBoxName(pendingOperationsBox, cleanUserId), cipher),

      // Unencrypted metadata boxes
      _openUnencryptedBox<SyncMetadataModel>(getUserBoxName(syncMetadataBox, cleanUserId)),
      _openUnencryptedBox<dynamic>(getUserBoxName(analyticsCacheBox, cleanUserId)),
      _openUnencryptedBox<dynamic>(getUserBoxName(syncLogBox, cleanUserId)),
    ]);
  }

  static Future<Box<T>> _openEncryptedBox<T>(String boxName, HiveAesCipher? cipher) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<T>(boxName);
    }
    return await Hive.openBox<T>(boxName, encryptionCipher: cipher);
  }

  static Future<Box<T>> _openUnencryptedBox<T>(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<T>(boxName);
    }
    return await Hive.openBox<T>(boxName);
  }

  // Getters for current active user's boxes
  static Box<ProfileModel> get profiles => _getOrFallback<ProfileModel>(getUserBoxName(profilesBox));
  static Box<FamilyModel> get families => _getOrFallback<FamilyModel>(getUserBoxName(familiesBox));
  static Box<FamilyMemberModel> get familyMembers => _getOrFallback<FamilyMemberModel>(getUserBoxName(familyMembersBox));
  static Box<ExpenseModel> get expenses => _getOrFallback<ExpenseModel>(getUserBoxName(expensesBox));
  static Box<BudgetModel> get budgets => _getOrFallback<BudgetModel>(getUserBoxName(budgetsBox));
  static Box<PendingOperationModel> get pendingOperations => _getOrFallback<PendingOperationModel>(getUserBoxName(pendingOperationsBox));
  static Box<SyncMetadataModel> get syncMetadata => _getOrFallback<SyncMetadataModel>(getUserBoxName(syncMetadataBox));
  static Box<dynamic> get analyticsCache => _getOrFallback<dynamic>(getUserBoxName(analyticsCacheBox));
  static Box<dynamic> get syncLog => _getOrFallback<dynamic>(getUserBoxName(syncLogBox));

  // Global unencrypted settings box
  static Box<dynamic> get settings => Hive.box<dynamic>(settingsBox);

  static Box<T> _getOrFallback<T>(String boxName) {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<T>(boxName);
    }
    // Fallback for legacy global box if user-scoped box is not open yet
    if (Hive.isBoxOpen(boxName.split('_').first)) {
      return Hive.box<T>(boxName.split('_').first);
    }
    throw StateError('Hive box $boxName is not open. Call openUserBoxes() first.');
  }

  // Namespace Registry Helpers
  static Map<String, dynamic> getCachedUsers() {
    final raw = settings.get('cached_users');
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return {};
  }

  static Future<void> updateUserRegistry({
    required String userId,
    String? displayName,
    String? email,
    String? appVersion,
    int? boxVersion,
    String? migrationState,
    DateTime? lastSuccessfulSync,
    int? expensesCount,
    int? pendingSyncCount,
  }) async {
    if (userId.isEmpty || userId == guestNamespace) return;

    final users = getCachedUsers();
    final existing = (users[userId] as Map?) != null
        ? Map<String, dynamic>.from(users[userId] as Map)
        : <String, dynamic>{};

    users[userId] = {
      ...existing,
      'userId': userId,
      if (displayName != null) 'displayName': displayName,
      if (email != null) 'email': email,
      if (appVersion != null) 'appVersion': appVersion,
      if (boxVersion != null) 'boxVersion': boxVersion,
      if (migrationState != null) 'migrationState': migrationState,
      if (lastSuccessfulSync != null) 'lastSuccessfulSync': lastSuccessfulSync.toIso8601String(),
      if (expensesCount != null) 'expensesCount': expensesCount,
      if (pendingSyncCount != null) 'pendingSyncCount': pendingSyncCount,
      'lastUsed': DateTime.now().toIso8601String(),
    };

    await settings.put('cached_users', users);
  }

  // Ring-Buffer Sync Logger (Last 100 events)
  static Future<void> logSyncEvent(
    String eventType, {
    String? status,
    int? opsPushed,
    int? itemsPulled,
    String? message,
  }) async {
    try {
      final logBox = syncLog;
      final event = {
        'id': const Uuid().v4(),
        'timestamp': DateTime.now().toIso8601String(),
        'eventType': eventType,
        'status': status ?? 'INFO',
        'opsPushed': opsPushed ?? 0,
        'itemsPulled': itemsPulled ?? 0,
        'message': message ?? '',
        'userId': _activeUserId,
        'deviceId': deviceId,
      };

      await logBox.add(event);

      // Prune ring buffer to keep only last 100 entries
      if (logBox.length > 100) {
        final toDeleteCount = logBox.length - 100;
        for (int i = 0; i < toDeleteCount; i++) {
          await logBox.deleteAt(0);
        }
      }
    } catch (e) {
      debugPrint('Failed to write sync log event: $e');
    }
  }

  static List<Map<String, dynamic>> getSyncLogs([String? userId]) {
    try {
      final logBox = userId != null && userId.isNotEmpty && Hive.isBoxOpen(getUserBoxName(syncLogBox, userId))
          ? Hive.box<dynamic>(getUserBoxName(syncLogBox, userId))
          : syncLog;
      return logBox.values.map((v) => Map<String, dynamic>.from(v as Map)).toList();
    } catch (_) {
      return [];
    }
  }
}
