import 'package:flutter/widgets.dart';

import 'core/supabase_bootstrap.dart';
import 'foodhub_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FoodHubSupabase.initializeIfConfigured();
  runApp(const FoodHubApp());
}
