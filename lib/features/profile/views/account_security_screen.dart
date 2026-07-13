import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/widgets/spendly/spendly.dart';

class AccountSecurityScreen extends ConsumerStatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  ConsumerState<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends ConsumerState<AccountSecurityScreen> {
  void _showDeleteAccountDialog() {
    SpendlyDialog.show(
      context: context,
      title: 'Delete Account?',
      content: 'Are you sure you want to delete your account? All your personal profile settings will be permanently erased. This action cannot be undone.',
      confirmText: 'DELETE ACCOUNT',
      cancelText: 'CANCEL',
      onConfirm: () async {
        final messenger = ScaffoldMessenger.of(this.context);
        try {
          await ref.read(authProvider.notifier).deleteAccount();
          SpendlySnackbar.show(context: this.context, message: 'Your account has been deleted successfully.');
        } catch (e) {
          SpendlySnackbar.show(context: this.context, message: 'Error deleting account: $e', isError: true);
        }
      },
    );
  }

  void _showDeleteFamilyDialog(String familyName) {
    SpendlyDialog.show(
      context: context,
      title: 'Delete Family & Data?',
      content: 'Are you sure you want to delete "$familyName" and ALL associated expenses, budgets, and member links? This action is permanent and cannot be undone.',
      confirmText: 'DELETE FAMILY',
      cancelText: 'CANCEL',
      onConfirm: () async {
        final messenger = ScaffoldMessenger.of(this.context);
        try {
          final success = await ref.read(familyProvider.notifier).deleteFamily();
          if (success) {
            SpendlySnackbar.show(context: this.context, message: 'Family and all its data deleted successfully.');
          } else {
            final errorMsg = ref.read(familyProvider).error ?? 'Unknown error';
            SpendlySnackbar.show(context: this.context, message: 'Error deleting family: $errorMsg', isError: true);
          }
        } catch (e) {
          SpendlySnackbar.show(context: this.context, message: 'Error deleting family: $e', isError: true);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final familyState = ref.watch(familyProvider);
    final spendly = context.spendly;

    bool isCurrentUserAdmin = false;
    for (final m in familyState.members) {
      if (m.userId == authState.userId && m.role == 'admin') {
        isCurrentUserAdmin = true;
        break;
      }
    }

    final familyName = familyState.family?.name ?? 'your family';
    final otherMembersExist = familyState.members.where((m) => m.userId != authState.userId).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Security'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.warning_amber_rounded, color: spendly.colors.error, size: 64),
            const SizedBox(height: 16),
            Text(
              'Danger Zone',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: spendly.colors.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Actions here are permanent and cannot be undone. Please proceed with caution.',
              textAlign: TextAlign.center,
              style: TextStyle(color: spendly.colors.neutral500, fontSize: 14),
            ),
            const SizedBox(height: 32),

            // Delete Account button
            SpendlyButton(
              text: 'DELETE MY ACCOUNT',
              variant: SpendlyButtonVariant.danger,
              icon: const Icon(Icons.person_remove),
              onPressed: isCurrentUserAdmin
                  ? () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111827) : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: spendly.radius.large),
                          title: const Text('Admin Restriction', style: TextStyle(fontWeight: FontWeight.bold)),
                          content: const Text(
                            'As the family admin, you cannot delete your account while the family group still exists.\n\n'
                            'Please use the "DELETE FAMILY & ALL DATA" button first to clean up the group before deleting your personal account.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('UNDERSTOOD', style: TextStyle(color: spendly.colors.neutral500, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    }
                  : _showDeleteAccountDialog,
            ),
            
            if (isCurrentUserAdmin) ...[
              const SizedBox(height: 16),
              // Delete Family button
              SpendlyButton(
                text: 'DELETE FAMILY & ALL DATA',
                variant: SpendlyButtonVariant.danger,
                icon: const Icon(Icons.delete_forever),
                onPressed: otherMembersExist
                    ? () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111827) : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: spendly.radius.large),
                            title: const Text('Members Still Active', style: TextStyle(fontWeight: FontWeight.bold)),
                            content: const Text(
                              'As the admin, you can only delete the family once all other members have deleted their accounts or left the family group.\n\n'
                              'Please ensure other members are removed before deleting the family.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('UNDERSTOOD', style: TextStyle(color: spendly.colors.neutral500, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      }
                    : () => _showDeleteFamilyDialog(familyName),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
