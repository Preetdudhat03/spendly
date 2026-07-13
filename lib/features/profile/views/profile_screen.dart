import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/providers/settings_provider.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';
import 'package:spendly/core/widgets/shimmer_loading.dart';
import 'package:spendly/core/services/report_service.dart';
import 'package:spendly/core/widgets/spendly/spendly.dart';

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
    SpendlyToast.show(context, 'Family Code copied to clipboard! Share it with your family.');
  }

  void _showEditBudgetDialog(double currentBudget) {
    _budgetController.text = currentBudget.toStringAsFixed(0);
    final spendly = context.spendly;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111827) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: spendly.radius.large),
        title: const Text('Set Monthly Budget', style: TextStyle(fontWeight: FontWeight.bold)),
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
            child: Text('CANCEL', style: TextStyle(color: spendly.colors.neutral500, fontWeight: FontWeight.bold)),
          ),
          SpendlyButton(
            text: 'SAVE',
            size: SpendlyButtonSize.small,
            onPressed: () {
              final newBudget = double.tryParse(_budgetController.text) ?? 0.0;
              if (newBudget >= 0) {
                ref.read(budgetProvider.notifier).setBudget(newBudget);
                Navigator.pop(context);
                SpendlySnackbar.show(context: context, message: 'Monthly budget updated to ₹$newBudget');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(String currentName) {
    _nameController.text = currentName;
    final spendly = context.spendly;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111827) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: spendly.radius.large),
        title: const Text('Change Display Name', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Your Name (e.g. Dad, Mom, Preet)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TextStyle(color: spendly.colors.neutral500, fontWeight: FontWeight.bold)),
          ),
          SpendlyButton(
            text: 'SAVE',
            size: SpendlyButtonSize.small,
            onPressed: () {
              final newName = _nameController.text.trim();
              if (newName.isNotEmpty) {
                ref.read(authProvider.notifier).updateProfileName(newName);
                Navigator.pop(context);
                SpendlySnackbar.show(context: context, message: 'Name updated to "$newName"');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditEmailDialog(String currentEmail) {
    _emailController.text = currentEmail;
    final spendly = context.spendly;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111827) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: spendly.radius.large),
        title: const Text('Change Email Address', style: TextStyle(fontWeight: FontWeight.bold)),
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
            child: Text('CANCEL', style: TextStyle(color: spendly.colors.neutral500, fontWeight: FontWeight.bold)),
          ),
          SpendlyButton(
            text: 'SAVE',
            size: SpendlyButtonSize.small,
            onPressed: () async {
              final newEmail = _emailController.text.trim();
              if (newEmail.isNotEmpty && newEmail.contains('@')) {
                final messenger = ScaffoldMessenger.of(this.context);
                final nav = Navigator.of(this.context);
                nav.pop(); // Close dialog first
                
                try {
                  await ref.read(authProvider.notifier).updateEmail(newEmail);
                  SpendlySnackbar.show(context: this.context, message: 'Email updated to "$newEmail"');
                } catch (e) {
                  SpendlySnackbar.show(context: this.context, message: 'Failed to update email: $e', isError: true);
                }
              } else {
                SpendlySnackbar.show(context: this.context, message: 'Please enter a valid email address', isError: true);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showAvatarColorPicker() {
    final colors = [
      Colors.indigo, Colors.blue, Colors.teal, Colors.green,
      Colors.orange, Colors.red, Colors.pink, Colors.purple
    ];
    final spendly = context.spendly;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: spendly.radius.xxlarge.topLeft,
          topRight: spendly.radius.xxlarge.topRight,
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose Avatar Color', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: colors.map((color) => GestureDetector(
                onTap: () {
                  final hex = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
                  ref.read(authProvider.notifier).updateAvatarColor(hex);
                  Navigator.pop(context);
                },
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: color,
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showQrCodeDialog(String code) {
    final spendly = context.spendly;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111827) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: spendly.radius.large),
        title: const Text('Scan to Join', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 250,
          height: 250,
          child: Center(
            child: QrImageView(
              data: code,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CLOSE', style: TextStyle(color: spendly.colors.neutral500, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
    final spendly = context.spendly;
    final theme = Theme.of(context);

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

                  Widget userDetailsCard = SpendlyCard(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _showAvatarColorPicker,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Builder(
                                builder: (context) {
                                  final meta = Supabase.instance.client.auth.currentUser?.userMetadata;
                                  final hex = meta?['avatar_color'] as String?;
                                  Color bgColor = spendly.colors.primary;
                                  if (hex != null && hex.length == 7) {
                                    bgColor = Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000);
                                  }
                                  return CircleAvatar(
                                    radius: 40,
                                    backgroundColor: bgColor.withOpacity(0.1),
                                    child: Icon(Icons.person, size: 45, color: bgColor),
                                  );
                                }
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: Icon(Icons.palette, size: 16, color: spendly.colors.primary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              authState.displayName ?? 'Family Member',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, size: 16, color: spendly.colors.neutral400),
                              onPressed: () => _showEditNameDialog(authState.displayName ?? ''),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.only(left: 8),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              authState.email ?? '',
                              style: TextStyle(color: spendly.colors.neutral500, fontSize: 14),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, size: 14, color: spendly.colors.neutral400),
                              onPressed: () => _showEditEmailDialog(authState.email ?? ''),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.only(left: 8),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );

                  Widget familyCodeCard = SpendlyCard(
                    title: 'Family Group',
                    headerAction: IconButton(
                      onPressed: () => _showQrCodeDialog(familyCode),
                      icon: Icon(Icons.qr_code, size: 20, color: spendly.colors.primary),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(familyName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: spendly.radius.medium,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Invite Family Code',
                                      style: TextStyle(fontSize: 12, color: spendly.colors.neutral500)),
                                  Text(
                                    familyCode,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: spendly.colors.primary,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              SpendlyButton(
                                text: 'COPY',
                                size: SpendlyButtonSize.small,
                                icon: const Icon(Icons.copy),
                                onPressed: () => _copyFamilyCode(familyCode),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  );

                  final analyticsState = ref.watch(analyticsProvider);
                  final totalSpent = analyticsState.totalSpent;
                  final budgetProgress = currentBudget > 0 ? (totalSpent / currentBudget).clamp(0.0, 1.0) : 0.0;

                  Widget budgetCard = SpendlyCard(
                    title: 'Monthly Budget',
                    headerAction: SpendlyButton(
                      text: 'SET BUDGET',
                      size: SpendlyButtonSize.small,
                      icon: const Icon(Icons.tune),
                      onPressed: () => _showEditBudgetDialog(currentBudget),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currencyFormat.format(currentBudget),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Spent: ${currencyFormat.format(totalSpent)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: spendly.colors.neutral500)),
                            Text('${(budgetProgress * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: budgetProgress >= 1.0 ? spendly.colors.error : spendly.colors.neutral500)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SpendlyProgressBar(
                          value: budgetProgress,
                          height: 8,
                          color: budgetProgress >= 1.0 ? spendly.colors.error : (budgetProgress >= 0.8 ? spendly.colors.warning : spendly.colors.primary),
                        ),
                      ],
                    ),
                  );

                  Widget familyMembersCard = SpendlyCard(
                    title: 'Family Members',
                    child: Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: familyState.members.length,
                          itemBuilder: (context, index) {
                            final member = familyState.members[index];
                            final isAdmin = member.role == 'admin';
                            final isCurrentUserAdmin = familyState.members.any((m) => m.userId == authState.userId && m.role == 'admin');
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: spendly.colors.primary.withOpacity(0.1),
                                child: Text(
                                    member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : 'M'),
                              ),
                              title: Text(member.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
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
                                  if (isCurrentUserAdmin && !isAdmin)
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, size: 20),
                                      onSelected: (val) async {
                                        if (val == 'remove') {
                                          final confirmed = await SpendlyDialog.show(
                                            context: context,
                                            title: 'Remove Member',
                                            content: 'Are you sure you want to remove ${member.displayName} from the family?',
                                            confirmText: 'REMOVE',
                                            cancelText: 'CANCEL',
                                            onConfirm: () {
                                              ref.read(familyProvider.notifier).removeMember(member.userId);
                                              SpendlySnackbar.show(context: context, message: '${member.displayName} removed');
                                            },
                                          );
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(value: 'remove', child: Text('Remove from Family', style: TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                ],
                              ),
                            );
                          },
                        )
                      ],
                    ),
                  );

                  Widget reportsCard = SpendlyCard(
                    title: 'Family Reports',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Generate and share expense history directly.',
                            style: TextStyle(color: spendly.colors.neutral500, fontSize: 13)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: SpendlyButton(
                                text: 'SHARE CSV',
                                variant: SpendlyButtonVariant.outlined,
                                icon: const Icon(Icons.table_view),
                                onPressed: () {
                                  ReportService.exportAndShareCsv(expenseState.expenses);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SpendlyButton(
                                text: 'SHARE PDF',
                                icon: const Icon(Icons.picture_as_pdf),
                                onPressed: () {
                                  ReportService.exportAndSharePdf(
                                    expenses: expenseState.expenses,
                                    familyName: familyName,
                                    budgetLimit: currentBudget,
                                  );
                                },
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  );

                  Widget accountSecurityCard = SpendlyCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: Icon(Icons.security, color: spendly.colors.primary),
                      title: const Text('Account Security & Deletion', style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Icon(Icons.chevron_right, color: spendly.colors.neutral400),
                      onTap: () {
                        context.push('/account-security');
                      },
                    ),
                  );

                  final currentSettings = ref.watch(settingsProvider);
                  Widget appPreferencesCard = SpendlyCard(
                    title: 'App Preferences',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: const Text('Switch to a darker theme'),
                          value: currentSettings.isDarkMode,
                          onChanged: (val) {
                            ref.read(settingsProvider.notifier).toggleDarkMode(val);
                          },
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Currency Symbol', style: TextStyle(fontWeight: FontWeight.w600)),
                          trailing: DropdownButton<String>(
                            value: currentSettings.currencySymbol,
                            underline: const SizedBox(),
                            items: ['₹', '\$', '€', '£'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(settingsProvider.notifier).updateCurrency(val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  );

                  Widget logoutButton = SpendlyButton(
                    text: 'LOGOUT FROM APP',
                    variant: SpendlyButtonVariant.danger,
                    icon: const Icon(Icons.logout),
                    onPressed: () {
                      ref.read(authProvider.notifier).signOut();
                    },
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
                            color: spendly.colors.neutral400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Developed by Preet',
                          style: TextStyle(
                            fontSize: 13,
                            color: spendly.colors.neutral400,
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
                                  accountSecurityCard,
                                  const SizedBox(height: 16),
                                  appPreferencesCard,
                                  const SizedBox(height: 24),
                                  logoutButton,
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
                        accountSecurityCard,
                        const SizedBox(height: 16),
                        appPreferencesCard,
                        const SizedBox(height: 24),
                        logoutButton,
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
