import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spendly/core/constants/config.dart';
import 'package:spendly/core/services/db_service.dart';
import 'package:spendly/core/services/mock_db_service.dart';
import 'package:spendly/core/services/supabase_db_service.dart';

// Provider for SharedPreferences, overridden in main()
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences has not been initialized.');
});

// Primary Database Service provider
final dbServiceProvider = Provider<DbService>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  if (AppConfig.isSupabaseConfigured && AppConfig.isSupabaseInitialized) {
    // Return Supabase service
    return SupabaseDbService(prefs);
  } else {
    // Return Mock service
    return MockDbService(prefs);
  }
});
