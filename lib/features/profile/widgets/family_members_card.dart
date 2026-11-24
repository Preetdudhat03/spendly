import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendly/core/widgets/spendly_toast.dart';
import 'package:spendly/features/notifications/services/notification_service.dart';
import 'package:spendly/models/family.dart';
import 'package:spendly/models/family_member.dart';

/// Displays the family members list with role badges and a respectful
/// "Request to Leave Family" workflow instead of abrupt 3-dot removal.
class FamilyMembersCard extends ConsumerStatefulWidget {
  final Family? family;
  final List<FamilyMember> members;
  final String? currentUserId;
  final String currentUserName;
  final bool isCurrentUserAdmin;
  final Color accentColor;

  const FamilyMembersCard({
    super.key,
    required this.family,
    required this.members,
    required this.currentUserId,
    required this.currentUserName,
    required this.isCurrentUserAdmin,
    required this.accentColor,
  });

  @override
  ConsumerState<FamilyMembersCard> createState() => _FamilyMembersCardState();
}

class _FamilyMembersCardState extends ConsumerState<FamilyMembersCard> {
  Set<String> _leaveRequestedUserIds = {};
  String? _loadedFamilyId;

  @override
  void initState() {
    super.initState();
    _loadLeaveRequests();
  }

  @override
  void didUpdateWidget(covariant FamilyMembersCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.family?.id != widget.family?.id) {
      _loadLeaveRequests();
    }
  }

  Future<void> _loadLeaveRequests() async {
    final familyId = widget.family?.id;
    if (familyId == null || _loadedFamilyId == familyId) return;
    _loadedFamilyId = familyId;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('leave_requested_members_$familyId') ?? [];
    if (mounted) {
      setState(() {
        _leaveRequestedUserIds = saved.toSet();
      });
    }
  }

  Future<void> _persistLeaveRequests(String familyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'leave_requested_members_$familyId',
      _leaveRequestedUserIds.toList(),
    );
  }

  Future<void> _sendLeaveRequest(
    FamilyMember member, {
    required String familyId,
    required String familyName,
    String? reason,
  }) async {
    await ref.read(notificationServiceProvider).notifyFamilyLeaveRequest(
          familyId: familyId,
          targetUserId: member.userId,
          targetMemberName: member.displayName,
          familyName: familyName,
          requestedByName: widget.currentUserName,
          reason: reason,
        );

    if (mounted) {
      setState(() {
        _leaveRequestedUserIds = {..._leaveRequestedUserIds, member.userId};
      });
    }
    await _persistLeaveRequests(familyId);

    if (mounted) {
      SpendlyToast.showSuccess(
        context,
        'Leave request sent to ${member.displayName}',
      );
    }
  }

  Future<void> _cancelLeaveRequest(
    FamilyMember member, {
    required String familyId,
  }) async {
    if (mounted) {
      setState(() {
        _leaveRequestedUserIds = _leaveRequestedUserIds
            .where((id) => id != member.userId)
            .toSet();
      });
    }
    await _persistLeaveRequests(familyId);

    if (mounted) {
      SpendlyToast.showSuccess(
        context,
        'Leave request cancelled for ${member.displayName}',
      );
    }
  }

  void _showMemberManagementSheet(
    BuildContext context, {
    required FamilyMember member,
    required String familyId,
    required String familyName,
  }) {
    final noteController = TextEditingController();
    final isRequested = _leaveRequestedUserIds.contains(member.userId);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardTheme.color ??
          Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final colorScheme = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;
        bool isSending = false;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                14,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Member header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: widget.accentColor
                            .withValues(alpha: isDark ? 0.22 : 0.14),
                        child: Text(
                          member.displayName.isNotEmpty
                              ? member.displayName[0].toUpperCase()
                              : 'M',
                          style: TextStyle(
                            color: widget.accentColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.displayName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Member • Joined ${DateFormat('MMM d, yyyy').format(member.joinedAt)}',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (!isRequested) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh
                            .withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.outgoing_mail,
                            size: 20,
                            color: widget.accentColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Send a polite leave request to ${member.displayName}. They will receive a notification and can choose to leave $familyName.',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      maxLength: 120,
                      decoration: InputDecoration(
                        labelText: 'Optional note',
                        hintText: 'e.g., Cleaning up inactive family members',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: isSending
                          ? null
                          : () async {
                              setSheetState(() => isSending = true);
                              await _sendLeaveRequest(
                                member,
                                familyId: familyId,
                                familyName: familyName,
                                reason: noteController.text,
                              );
                              if (ctx.mounted) Navigator.of(ctx).pop();
                            },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        isSending ? 'Sending...' : 'Request to Leave Family',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange
                            .withValues(alpha: isDark ? 0.18 : 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.mark_email_read_outlined,
                            size: 20,
                            color: isDark
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'A leave request has already been sent to ${member.displayName}.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSending
                                ? null
                                : () async {
                                    await _cancelLeaveRequest(
                                      member,
                                      familyId: familyId,
                                    );
                                    if (ctx.mounted) Navigator.of(ctx).pop();
                                  },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Cancel Request',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: isSending
                                ? null
                                : () async {
                                    setSheetState(() => isSending = true);
                                    await _sendLeaveRequest(
                                      member,
                                      familyId: familyId,
                                      familyName: familyName,
                                    );
                                    if (ctx.mounted) Navigator.of(ctx).pop();
                                  },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              isSending ? 'Sending...' : 'Resend Request',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Family Members (${widget.members.length})',
                  style: theme.textTheme.titleMedium,
                ),
                if (widget.isCurrentUserAdmin)
                  Text(
                    'Tap member to manage',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const Divider(height: 16),
            ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.members.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: colorScheme.outline
                    .withValues(alpha: isDark ? 0.2 : 0.35),
              ),
              itemBuilder: (context, index) {
                final member = widget.members[index];
                final isAdmin = member.role == 'admin';
                final isSelf = member.userId == widget.currentUserId;
                final canManage =
                    widget.isCurrentUserAdmin && !isAdmin && widget.family != null;
                final isLeaveRequested =
                    _leaveRequestedUserIds.contains(member.userId);

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onTap: canManage
                      ? () => _showMemberManagementSheet(
                            context,
                            member: member,
                            familyId: widget.family!.id,
                            familyName: widget.family!.name,
                          )
                      : null,
                  leading: CircleAvatar(
                    backgroundColor: widget.accentColor
                        .withValues(alpha: isDark ? 0.22 : 0.14),
                    child: Text(
                      member.displayName.isNotEmpty
                          ? member.displayName[0].toUpperCase()
                          : 'M',
                      style: TextStyle(
                        color: widget.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isSelf) ...[
                        const SizedBox(width: 6),
                        Text(
                          '(You)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    'Joined ${DateFormat('MMM yyyy').format(member.joinedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLeaveRequested) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange
                                .withValues(alpha: isDark ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Requested',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFFBBF24)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isAdmin
                              ? (isDark
                                  ? const Color(0xFF78350F)
                                      .withValues(alpha: 0.35)
                                  : const Color(0xFFFEF3C7))
                              : (isDark
                                  ? const Color(0xFF1E293B)
                                  : colorScheme.surfaceContainerHigh),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isAdmin
                                ? (isDark
                                    ? const Color(0xFFD97706)
                                        .withValues(alpha: 0.4)
                                    : const Color(0xFFFDE68A))
                                : (isDark
                                    ? const Color(0xFF334155)
                                    : Colors.transparent),
                          ),
                        ),
                        child: Text(
                          isAdmin ? 'Admin' : 'Member',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isAdmin
                                ? (isDark
                                    ? const Color(0xFFFBBF24)
                                    : const Color(0xFFD97706))
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (canManage) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
