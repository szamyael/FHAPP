import 'package:flutter/material.dart';

import 'core/app_store.dart';
import 'core/app_store_scope.dart';
import 'core/theme.dart';
import 'ui/auth/supabase_password_recovery_screen.dart';
import 'ui/role_home.dart';
import 'ui/sign_in_screen.dart';

class FoodHubApp extends StatefulWidget {
  const FoodHubApp({super.key});

  @override
  State<FoodHubApp> createState() => _FoodHubAppState();
}

class _FoodHubAppState extends State<FoodHubApp> {
  late final AppStore _store = AppStore();

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStoreScope(
      notifier: _store,
      child: AnimatedBuilder(
        animation: _store,
        builder: (context, _) {
          final account = _store.currentAccount;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'FoodHub',
            theme: foodHubLightThemeForRole(account?.role),
            darkTheme: foodHubDarkThemeForRole(account?.role),
            themeMode: _store.themeMode,
            home: _store.isInPasswordRecoveryFlow
                ? const SupabasePasswordRecoveryScreen()
                : account == null
                ? const SignInScreen()
                : RoleHome(account: account),
          );
        },
      ),
    );
  }
}
