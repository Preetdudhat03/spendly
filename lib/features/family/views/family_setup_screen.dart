import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/utils/schema_validator.dart';
import 'package:spendly/core/widgets/shimmer_loading.dart';
import 'package:spendly/core/widgets/spendly/spendly.dart';

class FamilySetupScreen extends ConsumerStatefulWidget {
  const FamilySetupScreen({super.key});

  @override
  ConsumerState<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends ConsumerState<FamilySetupScreen> {
  final _createController = TextEditingController();
  final _joinController = TextEditingController();
  final _createFormKey = GlobalKey<FormState>();
  final _joinFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _createController.dispose();
    _joinController.dispose();
    super.dispose();
  }

  Future<void> _createFamily() async {
    if (!_createFormKey.currentState!.validate()) return;
    final name = _createController.text.trim();
    final success = await ref.read(familyProvider.notifier).createFamily(name);
    if (!mounted) return;
    if (!success) {
      _showError(ref.read(familyProvider).error ?? 'Failed to create family');
    }
  }

  Future<void> _joinFamily() async {
    if (!_joinFormKey.currentState!.validate()) return;
    final codeText = _joinController.text.trim().toUpperCase();
    final code = codeText.startsWith('FAMILY-') ? codeText : 'FAMILY-$codeText';
    final success = await ref.read(familyProvider.notifier).joinFamily(code);
    if (!mounted) return;
    if (!success) {
      _showError(ref.read(familyProvider).error ?? 'Failed to join family');
    }
  }

  void _showError(String message) {
    SpendlySnackbar.show(
      context: context,
      message: message,
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyProvider);
    final spendly = context.spendly;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Family'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          )
        ],
      ),
      body: familyState.isLoading
          ? ShimmerLoading(
              isLoading: true,
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: const ShimmerListPlaceholder(itemCount: 4),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(28.0),
              child: Builder(
                builder: (context) {
                  final width = MediaQuery.of(context).size.width;
                  final isWide = width > 720;

                  Widget welcomeWidget = const Text(
                    'Welcome to Spendly!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  );

                  Widget subtitleWidget = Text(
                    'To start tracking spending, you need to either create a new family group or join an existing one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: spendly.colors.neutral500),
                  );

                  Widget createFamilyCard = SpendlyCard(
                    child: Form(
                      key: _createFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Create a Family',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a new expense tracking group and invite others.',
                            style: TextStyle(fontSize: 14, color: spendly.colors.neutral500),
                          ),
                          const SizedBox(height: 16),
                          SpendlyInputField(
                            controller: _createController,
                            label: 'Family Name (e.g. Sharma Family)',
                            prefixIcon: Icon(Icons.people, color: spendly.colors.neutral400),
                            validator: (value) {
                              try {
                                SchemaValidator.validateDisplayName(value, fieldName: 'Family Name');
                                return null;
                              } catch (e) {
                                return e.toString();
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          SpendlyButton(
                            text: 'CREATE FAMILY',
                            variant: SpendlyButtonVariant.primary,
                            onPressed: _createFamily,
                          ),
                        ],
                      ),
                    ),
                  );

                  Widget joinFamilyCard = SpendlyCard(
                    child: Form(
                      key: _joinFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Join a Family',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter a family code provided by a family administrator.',
                            style: TextStyle(fontSize: 14, color: spendly.colors.neutral500),
                          ),
                          const SizedBox(height: 16),
                          SpendlyInputField(
                            controller: _joinController,
                            label: 'Family Code (e.g. 1234)',
                            prefixIcon: Icon(Icons.vpn_key, color: spendly.colors.neutral400),
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Please enter a family code' : null,
                          ),
                          const SizedBox(height: 16),
                          SpendlyButton(
                            text: 'JOIN FAMILY',
                            variant: SpendlyButtonVariant.outlined,
                            onPressed: _joinFamily,
                          ),
                        ],
                      ),
                    ),
                  );

                  if (isWide) {
                    return Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            welcomeWidget,
                            const SizedBox(height: 12),
                            subtitleWidget,
                            const SizedBox(height: 40),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: createFamilyCard),
                                const SizedBox(width: 24),
                                Expanded(child: joinFamilyCard),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        welcomeWidget,
                        const SizedBox(height: 12),
                        subtitleWidget,
                        const SizedBox(height: 40),
                        createFamilyCard,
                        const SizedBox(height: 24),
                        Center(
                            child: Text('— OR —',
                                style: TextStyle(fontWeight: FontWeight.bold, color: spendly.colors.neutral400))),
                        const SizedBox(height: 24),
                        joinFamilyCard,
                      ],
                    );
                  }
                },
              ),
            ),
    );
  }
}
