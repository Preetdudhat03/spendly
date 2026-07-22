class AppConfig {
  // 🔴 Set this to true to test the app incredibly fast in Offline Sandbox mode.
  // 🟢 Set this to false to connect to your real Supabase Database.
  static const bool forceSandboxMode = false;

  static const String supabaseUrl = forceSandboxMode 
      ? '' 
      : String.fromEnvironment('SUPABASE_URL', defaultValue: 'your supabase_url_here'); 
      
  static const String supabaseAnonKey = forceSandboxMode 
      ? '' 
      : String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'your supabase_anon_key_here'); 

  static bool isSupabaseInitialized = false;

  static bool get isSupabaseConfigured {
    return supabaseUrl.isNotEmpty &&
        supabaseUrl.startsWith('http') &&
        supabaseAnonKey.isNotEmpty &&
        supabaseAnonKey.length > 20;
  }
}
