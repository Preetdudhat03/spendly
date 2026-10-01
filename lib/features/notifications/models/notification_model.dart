import 'package:flutter/foundation.dart';

/// Strongly typed notification types supported across Spendly.
enum NotificationType {
  // Expense
  expenseAdded('expense_added'),
  expenseUpdated('expense_updated'),
  expenseDeleted('expense_deleted'),

  // Family
  familyMemberJoined('family_member_joined'),
  familyMemberLeft('family_member_left'),
  familyMemberActivity('family_member_activity'),

  // Budget
  budgetWarning('budget_warning'),
  budgetCritical('budget_critical'),
  budgetExceeded('budget_exceeded'),
  budgetReset('budget_reset'),

  // Reminders
  expenseReminder('expense_reminder'),
  recurringExpenseReminder('recurring_expense_reminder'),

  // Analytics & Insights
  spendingInsight('spending_insight'),
  unusualSpending('unusual_spending'),

  // System & Sync
  syncCompleted('sync_completed'),
  syncFailed('sync_failed'),
  securityAlert('security_alert');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String val) {
    return NotificationType.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase(),
      orElse: () => NotificationType.expenseAdded,
    );
  }

  NotificationCategory get category {
    switch (this) {
      case NotificationType.expenseAdded:
      case NotificationType.expenseUpdated:
      case NotificationType.expenseDeleted:
        return NotificationCategory.expense;

      case NotificationType.familyMemberJoined:
      case NotificationType.familyMemberLeft:
      case NotificationType.familyMemberActivity:
        return NotificationCategory.family;

      case NotificationType.budgetWarning:
      case NotificationType.budgetCritical:
      case NotificationType.budgetExceeded:
      case NotificationType.budgetReset:
        return NotificationCategory.budget;

      case NotificationType.expenseReminder:
      case NotificationType.recurringExpenseReminder:
        return NotificationCategory.reminder;

      case NotificationType.spendingInsight:
      case NotificationType.unusualSpending:
        return NotificationCategory.insight;

      case NotificationType.syncCompleted:
      case NotificationType.syncFailed:
      case NotificationType.securityAlert:
        return NotificationCategory.system;
    }
  }
}

enum NotificationCategory {
  expense('Expense'),
  budget('Budget'),
  family('Family'),
  reminder('Reminder'),
  insight('Insight'),
  system('System');

  final String label;
  const NotificationCategory(this.label);
}

enum NotificationPriority {
  low('low'),
  normal('normal'),
  high('high'),
  urgent('urgent');

  final String value;
  const NotificationPriority(this.value);

  static NotificationPriority fromString(String? val) {
    if (val == null) return NotificationPriority.normal;
    return NotificationPriority.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase(),
      orElse: () => NotificationPriority.normal,
    );
  }
}

@immutable
class SpendlyNotification {
  final String id;
  final String? userId;
  final String familyId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> payload;
  final bool isRead;
  final DateTime? readAt;
  final NotificationPriority priority;
  final String? deepLink;
  final String? notificationKey;
  final DateTime? expiresAt;
  final String? createdBy;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const SpendlyNotification({
    required this.id,
    this.userId,
    required this.familyId,
    required this.type,
    required this.title,
    required this.body,
    this.payload = const {},
    this.isRead = false,
    this.readAt,
    this.priority = NotificationPriority.normal,
    this.deepLink,
    this.notificationKey,
    this.expiresAt,
    this.createdBy,
    this.metadata = const {},
    required this.createdAt,
  });

  SpendlyNotification copyWith({
    String? id,
    String? userId,
    String? familyId,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? payload,
    bool? isRead,
    DateTime? readAt,
    NotificationPriority? priority,
    String? deepLink,
    String? notificationKey,
    DateTime? expiresAt,
    String? createdBy,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return SpendlyNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      familyId: familyId ?? this.familyId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      payload: payload ?? this.payload,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      priority: priority ?? this.priority,
      deepLink: deepLink ?? this.deepLink,
      notificationKey: notificationKey ?? this.notificationKey,
      expiresAt: expiresAt ?? this.expiresAt,
      createdBy: createdBy ?? this.createdBy,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'family_id': familyId,
      'type': type.value,
      'title': title,
      'body': body,
      'payload': payload,
      'is_read': isRead,
      if (readAt != null) 'read_at': readAt!.toIso8601String(),
      'priority': priority.value,
      if (deepLink != null) 'deep_link': deepLink,
      if (notificationKey != null) 'notification_key': notificationKey,
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      if (createdBy != null) 'created_by': createdBy,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SpendlyNotification.fromJson(Map<String, dynamic> json) {
    return SpendlyNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      familyId: json['family_id'] as String? ?? '',
      type: NotificationType.fromString(json['type'] as String? ?? 'expense_added'),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      payload: json['payload'] is Map ? Map<String, dynamic>.from(json['payload'] as Map) : {},
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'] as String) : null,
      priority: NotificationPriority.fromString(json['priority'] as String?),
      deepLink: json['deep_link'] as String?,
      notificationKey: json['notification_key'] as String?,
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'] as String) : null,
      createdBy: json['created_by'] as String?,
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata'] as Map) : {},
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpendlyNotification &&
        other.id == id &&
        other.userId == userId &&
        other.familyId == familyId &&
        other.type == type &&
        other.title == title &&
        other.body == body &&
        other.isRead == isRead &&
        other.readAt == readAt &&
        other.priority == priority &&
        other.deepLink == deepLink &&
        other.notificationKey == notificationKey &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        familyId,
        type,
        title,
        body,
        isRead,
        readAt,
        priority,
        deepLink,
        notificationKey,
        createdAt,
      );
}

@immutable
class NotificationPreferences {
  final bool pushEnabled;
  final bool expenseAlerts;
  final bool budgetAlerts;
  final bool familyAlerts;
  final bool spendingInsights;
  final bool expenseReminders;
  final String reminderTime; // 'HH:mm' e.g. '20:00'

  const NotificationPreferences({
    this.pushEnabled = true,
    this.expenseAlerts = true,
    this.budgetAlerts = true,
    this.familyAlerts = true,
    this.spendingInsights = true,
    this.expenseReminders = false,
    this.reminderTime = '20:00',
  });

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? expenseAlerts,
    bool? budgetAlerts,
    bool? familyAlerts,
    bool? spendingInsights,
    bool? expenseReminders,
    String? reminderTime,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      expenseAlerts: expenseAlerts ?? this.expenseAlerts,
      budgetAlerts: budgetAlerts ?? this.budgetAlerts,
      familyAlerts: familyAlerts ?? this.familyAlerts,
      spendingInsights: spendingInsights ?? this.spendingInsights,
      expenseReminders: expenseReminders ?? this.expenseReminders,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'push_enabled': pushEnabled,
      'expense_alerts': expenseAlerts,
      'budget_alerts': budgetAlerts,
      'family_alerts': familyAlerts,
      'spending_insights': spendingInsights,
      'expense_reminders': expenseReminders,
      'reminder_time': reminderTime,
    };
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      pushEnabled: json['push_enabled'] as bool? ?? true,
      expenseAlerts: json['expense_alerts'] as bool? ?? true,
      budgetAlerts: json['budget_alerts'] as bool? ?? true,
      familyAlerts: json['family_alerts'] as bool? ?? true,
      spendingInsights: json['spending_insights'] as bool? ?? true,
      expenseReminders: json['expense_reminders'] as bool? ?? false,
      reminderTime: json['reminder_time'] as String? ?? '20:00',
    );
  }
}
