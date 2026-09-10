import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/widgets/capsule_top_bar.dart';

class AccountSecurityScreen extends ConsumerStatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  ConsumerState<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends ConsumerState<AccountSecurityScreen> {
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_remove_rounded, color: Colors.red, size: 28),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete Account?',
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete your account? All your personal profile settings and account data will be permanently erased. This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final messenger = ScaffoldMessenger.of(this.context);
                      try {
                        await ref.read(authProvider.notifier).deleteAccount();
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Your account has been deleted successfully.')),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Error deleting account: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showDeleteFamilyDialog(String familyName) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 28),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete Family & Data?',
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete "$familyName" and ALL associated expenses, budgets, and member links? This action is permanent and cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final messenger = ScaffoldMessenger.of(this.context);
                      try {
                        final success = await ref.read(familyProvider.notifier).deleteFamily();
                        if (success) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Family and all its data deleted successfully.')),
                          );
                        } else {
                          final errorMsg = ref.read(familyProvider).error ?? 'Unknown error';
                          messenger.showSnackBar(
                            SnackBar(content: Text('Error deleting family: $errorMsg'), backgroundColor: Colors.red),
                          );
                        }
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Error deleting family: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Delete Family', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final familyState = ref.watch(familyProvider);

    bool isCurrentUserAdmin = false;
    for (final m in familyState.members) {
      if (m.userId == authState.userId && m.role == 'admin') {
        isCurrentUserAdmin = true;
        break;
      }
    }

    final familyName = familyState.family?.name ?? 'your family';
    final otherMembersExist = familyState.members.where((m) => m.userId != authState.userId).isNotEmpty;

    final topInset = MediaQuery.of(context).padding.top;
    final contentTopPadding = topInset + 58.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const CapsuleHeader(
          title: 'Account Security',
          icon: Icons.security_rounded,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.0, contentTopPadding, 20.0, 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Danger Zone',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Actions here are permanent and cannot be undone. Please proceed with caution.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 32),

            // Delete Account button
            OutlinedButton.icon(
              onPressed: isCurrentUserAdmin
                  ? () {
                      showDialog(
                        context: context,
                        builder: (ctx) {
                          final isDark = Theme.of(ctx).brightness == Brightness.dark;
                          final accentColor = isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706);
                          return AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                            contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.admin_panel_settings_rounded, color: accentColor, size: 28),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Admin Restriction',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'As the family admin, you cannot delete your account while the family group still exists.\n\nPlease use "DELETE FAMILY & ALL DATA" first to clean up the group before deleting your personal account.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            actions: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                  child: const Text('Understood', style: TextStyle(fontWeight: FontWeight.w800)),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  : _showDeleteAccountDialog,
              icon: const Icon(Icons.person_remove),
              label: const Text('DELETE MY ACCOUNT'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            
            if (isCurrentUserAdmin) ...[
              const SizedBox(height: 16),
              // Delete Family button
              ElevatedButton.icon(
                onPressed: otherMembersExist
                    ? () {
                        showDialog(
                          context: context,
                          builder: (ctx) {
                            final isDark = Theme.of(ctx).brightness == Brightness.dark;
                            final accentColor = isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706);
                            return AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                              contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child: Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.group_remove_rounded, color: accentColor, size: 28),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Members Still Active',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'As the admin, you can only delete the family once all other members have deleted their accounts or left the family group.\n\nPlease ensure other members are removed before deleting the family.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              actions: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      elevation: 0,
                                    ),
                                    child: const Text('Understood', style: TextStyle(fontWeight: FontWeight.w800)),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    : () => _showDeleteFamilyDialog(familyName),
                icon: const Icon(Icons.delete_forever),
                label: const Text('DELETE FAMILY & ALL DATA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
