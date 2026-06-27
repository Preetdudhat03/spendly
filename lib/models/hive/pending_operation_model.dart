import 'package:hive/hive.dart';

part 'pending_operation_model.g.dart';

@HiveType(typeId: 5)
class PendingOperationModel extends HiveObject {
  @HiveField(0)
  final String id; // Unique ID for this operation

  @HiveField(1)
  final String type; // e.g., 'ADD_EXPENSE', 'UPDATE_EXPENSE', 'DELETE_EXPENSE', 'UPDATE_BUDGET'

  @HiveField(2)
  final Map<String, dynamic> payload; // The serialized data

  @HiveField(3)
  final String? userId;

  @HiveField(4)
  final String? familyId;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  int retryCount;

  @HiveField(7)
  String syncStatus; // 'PENDING', 'SYNCING', 'FAILED'

  @HiveField(8)
  String? lastError;

  PendingOperationModel({
    required this.id,
    required this.type,
    required this.payload,
    this.userId,
    this.familyId,
    required this.timestamp,
    this.retryCount = 0,
    this.syncStatus = 'PENDING',
    this.lastError,
  });
}
