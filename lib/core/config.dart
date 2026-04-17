class FoodHubConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static const String googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static String get supabaseKey => supabaseAnonKey.isNotEmpty ? supabaseAnonKey : supabasePublishableKey;

  static bool _looksLikePlaceholder(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;
    final lower = v.toLowerCase();
    return lower == 'your_url' ||
        lower == 'your_key' ||
        lower.contains('paste_your') ||
        lower.contains('your_supabase');
  }

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty &&
      supabaseKey.isNotEmpty &&
      !_looksLikePlaceholder(supabaseUrl) &&
      !_looksLikePlaceholder(supabaseKey);
  static bool get hasGoogleMapsApiKey => googleMapsApiKey.isNotEmpty;
}
