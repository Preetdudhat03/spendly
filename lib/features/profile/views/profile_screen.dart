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
import 'package:spendly/core/widgets/capsule_top_bar.dart';
import 'package:spendly/core/widgets/shimmer_loading.dart';
import 'package:spendly/core/services/report_service.dart';
import 'package:spendly/core/services/hive_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _budgetController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

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
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 105.0),
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
                  final hex = '#${(color.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan to Join', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: code,
                version: QrVersions.auto,
                size: 200.0,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              code,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: isDark
                    ? const Color(0xFF818CF8)
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const CapsuleHeader(
          title: 'Profile & Settings',
          icon: Icons.person_rounded,
        ),
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
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 80.0), //20, 20, 20, 100
              child: Builder(
                builder: (context) {
                  final width = MediaQuery.of(context).size.width;
                  final isWide = width > 720;

                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  final accentColor = isDark
                      ? const Color(0xFF818CF8)
                      : Theme.of(context).colorScheme.primary;
                  final isCurrentUserAdmin = familyState.members.any((m) =>
                      m.userId == authState.userId && m.role == 'admin');
                  final userInitial = (authState.displayName != null &&
                          authState.displayName!.trim().isNotEmpty)
                      ? authState.displayName!.trim()[0].toUpperCase()
                      : 'U';

                  final userExpenses = expenseState.expenses
                      .where((e) =>
                          e.createdBy == authState.userId ||
                          (e.createdByName.isNotEmpty &&
                              e.createdByName.toLowerCase() ==
                                  (authState.displayName ?? '')
                                      .trim()
                                      .toLowerCase()))
                      .toList();
                  final userTotalSpend = userExpenses.fold<double>(
                      0.0, (sum, e) => sum + e.amount);
                  final userTxnCount = userExpenses.length;

                  Widget userDetailsCard = Card(
                    elevation: 0,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Subtle ambient hero banner gradient
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 100,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  accentColor.withValues(
                                      alpha: isDark ? 0.16 : 0.08),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 24.0),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: _showAvatarColorPicker,
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Builder(
                                      builder: (context) {
                                        final hex = authState.avatarColor ??
                                            (Supabase.instance.client.auth
                                                    .currentUser?.userMetadata?[
                                                'avatar_color'] as String?) ??
                                            HiveService.settings
                                                .get('avatar_color') as String?;
                                        Color userColor = accentColor;
                                        if (hex != null &&
                                            hex.startsWith('#') &&
                                            hex.length >= 7) {
                                          try {
                                            userColor = Color(int.parse(
                                                    hex.substring(1, 7),
                                                    radix: 16) |
                                                0xFF000000);
                                          } catch (_) {}
                                        }
                                        return Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: userColor.withValues(
                                                  alpha: isDark ? 0.5 : 0.3),
                                              width: 3,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: userColor.withValues(
                                                    alpha:
                                                        isDark ? 0.3 : 0.18),
                                                blurRadius: 20,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            radius: 44,
                                            backgroundColor: userColor
                                                .withValues(
                                                    alpha: isDark ? 0.22 : 0.14),
                                            child: Text(
                                              userInitial,
                                              style: TextStyle(
                                                fontSize: 36,
                                                fontWeight: FontWeight.w900,
                                                color: userColor,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: accentColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(context)
                                                  .cardTheme
                                                  .color ??
                                              Theme.of(context)
                                                  .colorScheme
                                                  .surface,
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.2),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.palette,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Name with verified badge & edit icon
                              InkWell(
                                onTap: () => _showEditNameDialog(
                                    authState.displayName ?? ''),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: 4.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          authState.displayName ??
                                              'Family Member',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.3,
                                            color: isDark
                                                ? const Color(0xFFF8FAFC)
                                                : const Color(0xFF0F172A),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.verified_rounded,
                                        size: 18,
                                        color: accentColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF334155)
                                                  .withValues(alpha: 0.6)
                                              : const Color(0xFFF1F5F9),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                          Icons.edit_outlined,
                                          size: 14,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Role Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isCurrentUserAdmin
                                      ? (isDark
                                          ? const Color(0xFF78350F)
                                              .withValues(alpha: 0.35)
                                          : const Color(0xFFFEF3C7))
                                      : (isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isCurrentUserAdmin
                                        ? (isDark
                                            ? const Color(0xFFD97706)
                                                .withValues(alpha: 0.5)
                                            : const Color(0xFFFDE68A))
                                        : (isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFE2E8F0)),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isCurrentUserAdmin
                                          ? Icons.workspace_premium_rounded
                                          : Icons.person_rounded,
                                      size: 13,
                                      color: isCurrentUserAdmin
                                          ? (isDark
                                              ? const Color(0xFFFBBF24)
                                              : const Color(0xFFD97706))
                                          : (isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B)),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      isCurrentUserAdmin
                                          ? 'Family Admin'
                                          : 'Family Member',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.2,
                                        color: isCurrentUserAdmin
                                            ? (isDark
                                                ? const Color(0xFFFBBF24)
                                                : const Color(0xFFD97706))
                                            : (isDark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF64748B)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Email pill container with tap-to-copy & edit
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0F172A)
                                          .withValues(alpha: 0.85)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE2E8F0),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.mail_outline_rounded,
                                      size: 15,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () {
                                        final email = authState.email;
                                        if (email != null && email.isNotEmpty) {
                                          Clipboard.setData(
                                              ClipboardData(text: email));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Email address copied to clipboard'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Text(
                                        authState.email ?? 'No email set',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? const Color(0xFFCBD5E1)
                                              : const Color(0xFF475569),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => _showEditEmailDialog(
                                          authState.email ?? ''),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Padding(
                                        padding: const EdgeInsets.all(2.0),
                                        child: Icon(
                                          Icons.edit_outlined,
                                          size: 14,
                                          color: isDark
                                              ? const Color(0xFF64748B)
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Quick account & personal activity strip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0F172A)
                                          .withValues(alpha: 0.5)
                                      : const Color(0xFFF1F5F9)
                                          .withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                            .withValues(alpha: 0.6)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          'YOUR SPEND',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.8,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          currencyFormat.format(userTotalSpend),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    Container(
                                      height: 24,
                                      width: 1,
                                      color: isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          'LOGGED',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.8,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '$userTxnCount txns',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    Container(
                                      height: 24,
                                      width: 1,
                                      color: isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          'STATUS',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.8,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF22C55E),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Active',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? const Color(0xFF86EFAC)
                                                    : const Color(0xFF16A34A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );

                  Widget familyCodeCard = Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        width: 1,
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
                                'Family Group',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(
                                      alpha: isDark ? 0.2 : 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${familyState.members.length} Members',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            familyName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : Theme.of(context)
                                        .colorScheme
                                        .outlineVariant
                                        .withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Invite Family Code',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      familyCode,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: accentColor,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () =>
                                          _showQrCodeDialog(familyCode),
                                      tooltip: 'Show QR Code',
                                      icon: Icon(Icons.qr_code_2_rounded,
                                          color: accentColor, size: 26),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        Clipboard.setData(
                                            ClipboardData(text: familyCode));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Family Code copied to clipboard'),
                                          ),
                                        );
                                      },
                                      tooltip: 'Copy Code',
                                      icon: Icon(Icons.copy_rounded,
                                          color: accentColor, size: 22),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );

                  final analyticsState = ref.watch(analyticsProvider);
                  final totalSpent = analyticsState.totalSpent;
                  final budgetProgress = currentBudget > 0
                      ? (totalSpent / currentBudget).clamp(0.0, 1.0)
                      : 0.0;

                  Widget familyBudgetCard = Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        width: 1,
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
                                'Monthly Family Budget',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              if (isCurrentUserAdmin)
                                InkWell(
                                  onTap: () =>
                                      _showEditBudgetDialog(currentBudget),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit_outlined,
                                            size: 13, color: accentColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          'SET BUDGET',
                                          style: TextStyle(
                                            color: accentColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currencyFormat.format(currentBudget),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: budgetProgress >= 1.0
                                      ? Colors.red.withValues(alpha: 0.15)
                                      : (budgetProgress >= 0.8
                                          ? Colors.orange.withValues(alpha: 0.15)
                                          : const Color(0xFF22C55E)
                                              .withValues(alpha: 0.15)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  budgetProgress >= 1.0
                                      ? 'Over Budget'
                                      : (budgetProgress >= 0.8
                                          ? 'Approaching Limit'
                                          : 'On Track'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: budgetProgress >= 1.0
                                        ? Colors.red
                                        : (budgetProgress >= 0.8
                                            ? Colors.orange
                                            : const Color(0xFF16A34A)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Spent: ${currencyFormat.format(totalSpent)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '${(budgetProgress * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: budgetProgress >= 1.0
                                      ? Colors.red
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: budgetProgress.clamp(0.0, 1.0),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHigh,
                              color: budgetProgress >= 1.0
                                  ? Colors.red
                                  : (budgetProgress >= 0.8
                                      ? Colors.orange
                                      : accentColor),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                  Widget familyMembersCard = Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Family Members (${familyState.members.length})',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Divider(height: 24),
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
                                  backgroundColor: accentColor.withValues(
                                      alpha: isDark ? 0.22 : 0.14),
                                  child: Text(
                                    member.displayName.isNotEmpty
                                        ? member.displayName[0].toUpperCase()
                                        : 'M',
                                    style: TextStyle(
                                      color: accentColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  member.displayName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
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
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHigh),
                                        borderRadius:
                                            BorderRadius.circular(6),
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
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    if (isCurrentUserAdmin && !isAdmin)
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert,
                                            size: 20),
                                        onSelected: (val) async {
                                          if (val == 'remove') {
                                            final confirmed =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text(
                                                    'Remove Member'),
                                                content: Text(
                                                    'Are you sure you want to remove ${member.displayName} from the family?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            ctx, false),
                                                    child: const Text(
                                                        'CANCEL'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            ctx, true),
                                                    child: const Text(
                                                      'REMOVE',
                                                      style: TextStyle(
                                                          color: Colors.red),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirmed == true) {
                                              ref
                                                  .read(familyProvider.notifier)
                                                  .removeMember(member.userId);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                        content: Text(
                                                            '${member.displayName} removed')));
                                              }
                                            }
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'remove',
                                            child: Text(
                                              'Remove from Family',
                                              style: TextStyle(
                                                  color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                  );

                  Widget reportsCard = Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Family Reports',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            'Generate and share expense history directly.',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    ReportService.exportAndShareCsv(
                                        expenseState.expenses);
                                  },
                                  icon: const Icon(Icons.table_view_rounded),
                                  label: const Text('SHARE CSV'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    textStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
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
                                  icon: const Icon(Icons.picture_as_pdf_rounded),
                                  label: const Text('SHARE PDF'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    textStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
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
                    color: Theme.of(context).cardTheme.color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Theme.of(context).colorScheme.outline),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.security),
                      title: const Text('Account Security & Deletion', style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.push('/account-security');
                      },
                    ),
                  );

                  final currentSettings = ref.watch(settingsProvider);
                  Widget appPreferencesCard = Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('App Preferences', style: Theme.of(context).textTheme.titleMedium),
                          const Divider(height: 20),
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
                              dropdownColor: Theme.of(context).colorScheme.surface,
                              items: ['₹', '\$', '€', '£'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
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
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                        side: BorderSide(color: Theme.of(context).colorScheme.outline),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );

                  final packageInfoAsync = ref.watch(packageInfoProvider);
                  final versionStr = packageInfoAsync.when(
                    data: (info) => 'Version ${info.version}+${info.buildNumber}',
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
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Developed by Preet Dudhat',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                                  familyBudgetCard,
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
                        familyBudgetCard,
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
