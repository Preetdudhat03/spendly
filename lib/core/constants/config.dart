class AppConfig {
  // 🔴 Set this to true to test the app incredibly fast in Offline Sandbox mode.
  // 🟢 Set this to false to connect to your real Supabase Database.
  static const bool forceSandboxMode = false;

  static const String supabaseUrl = forceSandboxMode ? '' : 'https://rpugjnlabhvohnejynne.supabase.co'; 
  static const String supabaseAnonKey = forceSandboxMode ? '' : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJwdWdqbmxhYmh2b2huZWp5bm5lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIzNjE1OTgsImV4cCI6MjA5NzkzNzU5OH0.yCsKEg97_uGQvmyByga6AYA_OJpKquLMij49NGfdPPc'; 

  static bool isSupabaseInitialized = false;

  static bool get isSupabaseConfigured {
    return supabaseUrl.isNotEmpty &&
        supabaseUrl.startsWith('http') &&
        supabaseAnonKey.isNotEmpty &&
        supabaseAnonKey.length > 20;
  }
}
