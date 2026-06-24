class AppConfig {
  static const String supabaseUrl = ''; // Enter your Supabase URL here
  static const String supabaseAnonKey = ''; // Enter your Supabase Anon Key here

  static bool get isSupabaseConfigured {
    return supabaseUrl.isNotEmpty &&
        supabaseUrl.startsWith('http') &&
        supabaseAnonKey.isNotEmpty &&
        supabaseAnonKey.length > 20;
  }
}
