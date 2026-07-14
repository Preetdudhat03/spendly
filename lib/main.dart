import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spendly/core/constants/config.dart';
import 'package:spendly/core/services/db_provider.dart';
import 'package:spendly/core/services/router_service.dart';
import 'package:spendly/core/theme/app_theme.dart';
import 'package:spendly/core/providers/state_providers.dart';
import 'package:spendly/core/providers/settings_provider.dart';
import 'package:spendly/core/services/hive_service.dart';
import 'package:spendly/core/services/migration_service.dart';
import 'package:spendly/core/services/sync_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService();
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});

class LoggerObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    final typeName = provider.runtimeType.toString();
    if (typeName.contains('Auth') || 
        typeName.contains('Family') || 
        typeName.contains('Expense') || 
        typeName.contains('Budget') ||
        typeName.contains('Profile')) {
      debugPrint('Riverpod Logger: [$typeName] updated to: $newValue');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize Hive
  await HiveService.init();

  // Run Migration
  await MigrationService.runMigration(sharedPreferences);

  // Initialize Supabase only if it is configured
  if (AppConfig.isSupabaseConfigured) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
      AppConfig.isSupabaseInitialized = true;
      debugPrint('Supabase initialized successfully!');
    } catch (e) {
      AppConfig.isSupabaseInitialized = false;
      debugPrint('Error initializing Supabase: $e');
    }
  }

  runApp(
    ProviderScope(
      observers: [LoggerObserver()],
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const SpendlyApp(),
    ),
  );
}

class SpendlyApp extends ConsumerWidget {
  const SpendlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Spendly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(settingsProvider).isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        return ConnectionListenerWidget(child: child!);
      },
    );
  }
}

class ConnectionListenerWidget extends ConsumerWidget {
  final Widget child;

  const ConnectionListenerWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Force SyncService to initialize and stay alive
    ref.watch(syncServiceProvider);

    // Listen to connection changes to show Toast Messages globally
    {/*ref.listen<ConnectionStatus>(connectionProvider, (previous, next) {
      if (next == ConnectionStatus.offline) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white),
                SizedBox(width: 12),
                Text('You are offline. Running in offline/cached mode.'),
              ],
            ),
            backgroundColor: Colors.amber,
            duration: Duration(seconds: 4),
          ),
        );
      } else if (next == ConnectionStatus.online && previous == ConnectionStatus.offline) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.wifi, color: Colors.white),
                SizedBox(width: 12),
                Text('You are online. Connected to Supabase!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });*/}

    return child;
  }
}
