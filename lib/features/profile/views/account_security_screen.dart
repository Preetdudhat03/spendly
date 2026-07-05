import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/features/auth/providers/auth_provider.dart';
import 'package:spendly/features/family/providers/family_provider.dart';

class AccountSecurityScreen extends ConsumerStatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  ConsumerState<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends ConsumerState<AccountSecurityScreen> {
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to delete your account? All your personal profile settings will be permanently erased. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirmation dialog
              
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
            ),
            child: const Text('DELETE ACCOUNT'),
          ),
        ],
      ),
    );
  }

  void _showDeleteFamilyDialog(String familyName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Family & Data?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "$familyName" and ALL associated expenses, budgets, and member links? This action is permanent and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirmation dialog
              
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
            ),
            child: const Text('DELETE FAMILY'),
          ),
        ],
      ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Security'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
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
                        builder: (context) => AlertDialog(
                          title: const Text('Admin Restriction', style: TextStyle(fontWeight: FontWeight.bold)),
                          content: const Text(
                            'As the family admin, you cannot delete your account while the family group still exists.\n\n'
                            'Please use the "DELETE FAMILY & ALL DATA" button first to clean up the group before deleting your personal account.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('UNDERSTOOD'),
                            ),
                          ],
                        ),
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
                          builder: (context) => AlertDialog(
                            title: const Text('Members Still Active', style: TextStyle(fontWeight: FontWeight.bold)),
                            content: const Text(
                              'As the admin, you can only delete the family once all other members have deleted their accounts or left the family group.\n\n'
                              'Please ensure other members are removed before deleting the family.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('UNDERSTOOD'),
                              ),
                            ],
                          ),
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
