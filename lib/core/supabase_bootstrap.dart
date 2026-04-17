import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';

class FoodHubSupabase {
  static bool _initialized = false;
  static Object? _initError;

  static bool get isInitialized => _initialized;
  static Object? get initError => _initError;

  static SupabaseClient? get clientOrNull {
    if (!_initialized) return null;
    return Supabase.instance.client;
  }

  static Future<void> initializeIfConfigured() async {
    if (_initialized) return;
    if (!FoodHubConfig.hasSupabase) return;

    try {
      await Supabase.initialize(
        url: FoodHubConfig.supabaseUrl,
        anonKey: FoodHubConfig.supabaseKey,
      );
      _initialized = true;
      _initError = null;
    } catch (e) {
      _initialized = false;
      _initError = e;
    }
  }
}
