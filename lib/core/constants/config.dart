class AppConfig {
  static const String supabaseUrl = 'https://rpugjnlabhvohnejynne.supabase.co'; // Enter your Supabase URL here
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJwdWdqbmxhYmh2b2huZWp5bm5lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIzNjE1OTgsImV4cCI6MjA5NzkzNzU5OH0.yCsKEg97_uGQvmyByga6AYA_OJpKquLMij49NGfdPPc'; // Enter your Supabase Anon Key here

  static bool isSupabaseInitialized = false;

  static bool get isSupabaseConfigured {
    return supabaseUrl.isNotEmpty &&
        supabaseUrl.startsWith('http') &&
        supabaseAnonKey.isNotEmpty &&
        supabaseAnonKey.length > 20;
  }
}
