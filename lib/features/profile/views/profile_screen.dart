import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/widgets/shimmer_loading.dart';
import 'package:spendly/core/services/report_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _budgetController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  void _copyFamilyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Family Code copied to clipboard! Share it with your family.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showEditBudgetDialog(double currentBudget) {
    _budgetController.text = currentBudget.toStringAsFixed(0);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: TextField(
          controller: _budgetController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Budget Limit (₹)',
            prefixText: '₹ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              final newBudget = double.tryParse(_budgetController.text) ?? 0.0;
              if (newBudget >= 0) {
                ref.read(budgetProvider.notifier).setBudget(newBudget);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Monthly budget updated to ₹$newBudget')),
                );
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(String currentName) {
    _nameController.text = currentName;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Display Name'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Your Name (e.g. Dad, Mom, Preet)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              final newName = _nameController.text.trim();
              if (newName.isNotEmpty) {
                ref.read(authProvider.notifier).updateProfileName(newName);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Name updated to "$newName"')),
                );
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showEditEmailDialog(String currentEmail) {
    _emailController.text = currentEmail;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Email Address'),
        content: TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'New Email Address',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              final newEmail = _emailController.text.trim();
              if (newEmail.isNotEmpty && newEmail.contains('@')) {
                final messenger = ScaffoldMessenger.of(this.context);
                final nav = Navigator.of(this.context);
                nav.pop(); // Close dialog first
                
                try {
                  await ref.read(authProvider.notifier).updateEmail(newEmail);
                  messenger.showSnackBar(
                    SnackBar(content: Text('Email updated to "$newEmail"')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed to update email: $e'), backgroundColor: Colors.red),
                  );
                }
              } else {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid email address'), backgroundColor: Colors.orange),
                );
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void dispose() {
    _budgetController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final familyState = ref.watch(familyProvider);
    final budgetState = ref.watch(budgetProvider);
    final expenseState = ref.watch(expenseProvider);

    final familyCode = familyState.family?.familyCode ?? 'NO-CODE';
    final familyName = familyState.family?.name ?? 'My Family';
    final currentBudget = budgetState.currentBudget?.monthlyBudget ?? 20000.0;

    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: authState.isLoading || familyState.isLoading
          ? ShimmerLoading(
              isLoading: true,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: const ShimmerProfilePlaceholder(),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Builder(
                builder: (context) {
                  final width = MediaQuery.of(context).size.width;
                  final isWide = width > 720;

                  Widget userDetailsCard = Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            child: Icon(Icons.person, size: 40, color: Theme.of(context).primaryColor),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            authState.displayName ?? 'Family Member',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            authState.email ?? '',
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _showEditNameDialog(authState.displayName ?? ''),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('NICKNAME'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () => _showEditEmailDialog(authState.email ?? ''),
                                icon: const Icon(Icons.email, size: 16),
                                label: const Text('EMAIL'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );

                  Widget familyCodeCard = Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Family Group',
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(familyName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Invite Family Code',
                                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    Text(
                                      familyCode,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _copyFamilyCode(familyCode),
                                  icon: const Icon(Icons.copy, size: 16),
                                  label: const Text('COPY'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );

                  Widget budgetCard = Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Monthly Budget',
                                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormat.format(currentBudget),
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showEditBudgetDialog(currentBudget),
                            icon: const Icon(Icons.tune, size: 18),
                            label: const Text('SET BUDGET'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                    ),
                  );

                  Widget familyMembersCard = Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Family Members', style: Theme.of(context).textTheme.titleMedium),
                          const Divider(height: 20),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: familyState.members.length,
                            itemBuilder: (context, index) {
                              final member = familyState.members[index];
                              final isAdmin = member.role == 'admin';
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                  child: Text(
                                      member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : 'M'),
                                ),
                                title: Text(member.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: isAdmin ? const Color(0xFFFEF3C7) : const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isAdmin ? 'Admin' : 'Member',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isAdmin ? const Color(0xFFD97706) : Colors.black54,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                  );

                  Widget reportsCard = Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Family Reports', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          const Text('Generate and share expense history directly.',
                              style: TextStyle(color: Colors.grey, fontSize: 13)),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    ReportService.exportAndShareCsv(expenseState.expenses);
                                  },
                                  icon: const Icon(Icons.table_view),
                                  label: const Text('SHARE CSV'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    ReportService.exportAndSharePdf(
                                      expenses: expenseState.expenses,
                                      familyName: familyName,
                                      budgetLimit: currentBudget,
                                    );
                                  },
                                  icon: const Icon(Icons.picture_as_pdf),
                                  label: const Text('SHARE PDF'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  );


                  Widget accountSecurityCard = Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.security, color: Colors.indigo),
                      title: const Text('Account Security & Deletion', style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.push('/account-security');
                      },
                    ),
                  );

                  Widget logoutButton = Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref.read(authProvider.notifier).signOut();
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('LOGOUT FROM APP'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[800],
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('LOGOUT FROM APP'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.grey[800],
                              side: BorderSide(color: Colors.grey[300]!),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 12),

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
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          
                          if (isCurrentUserAdmin) ...[
                            const SizedBox(height: 12),
                            // Delete Family button
                            ElevatedButton.icon(
                              onPressed: () => _showDeleteFamilyDialog(familyName),
                              icon: const Icon(Icons.delete_forever),
                              label: const Text('DELETE FAMILY & ALL DATA'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );

                  final packageInfoAsync = ref.watch(packageInfoProvider);
                  final versionStr = packageInfoAsync.when(
                    data: (info) => 'Version ${info.version}',
                    loading: () => 'Version loading...',
                    error: (e, s) => 'Version unknown',
                  );

                  Widget versionFooter = Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          versionStr,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Developed by Preet',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );

                  if (isWide) {
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  userDetailsCard,
                                  const SizedBox(height: 16),
                                  familyCodeCard,
                                  const SizedBox(height: 24),
                                  accountSecurityCard,\n                                  const SizedBox(height: 24),\n                                  logoutButton,
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  budgetCard,
                                  const SizedBox(height: 16),
                                  familyMembersCard,
                                  const SizedBox(height: 16),
                                  reportsCard,
                                ],
                              ),
                            ),
                          ],
                        ),
                        versionFooter,
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        userDetailsCard,
                        const SizedBox(height: 16),
                        familyCodeCard,
                        const SizedBox(height: 16),
                        budgetCard,
                        const SizedBox(height: 16),
                        familyMembersCard,
                        const SizedBox(height: 16),
                        reportsCard,
                        const SizedBox(height: 32),
                        accountSecurityCard,\n                        const SizedBox(height: 24),\n                        logoutButton,
                        versionFooter,
                      ],
                    );
                  }
                },
              ),
            ),
    );
  }
}
