import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OAuthProvider;

import '../core/app_store.dart';
import '../core/app_store_scope.dart';
import '../core/config.dart';
import 'auth/forgot_password_screen.dart';
import 'auth/register_screen.dart';
import 'auth/auth_scaffold.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _rememberLoaded = false;

  static const _prefRememberMe = 'auth_remember_me';
  static const _prefRememberedEmail = 'auth_remembered_email';

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final remember = prefs.getBool(_prefRememberMe) ?? true;
      final rememberedEmail = prefs.getString(_prefRememberedEmail);
      setState(() {
        _rememberMe = remember;
        _rememberLoaded = true;
        if (rememberedEmail != null && remember && _email.text.trim().isEmpty) {
          _email.text = rememberedEmail;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _rememberLoaded = true);
    }
  }

  Future<void> _persistRememberedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefRememberMe, _rememberMe);
      if (_rememberMe) {
        await prefs.setString(_prefRememberedEmail, _email.text.trim());
      } else {
        await prefs.remove(_prefRememberedEmail);
      }
    } catch (_) {
      // Ignore persistence errors.
    }
  }

  Future<void> _submit(AppStore store) async {
    FocusScope.of(context).unfocus();
    final err = await store.signInWithCredentials(
      identifier: _email.text,
      password: _password.text,
    );
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    await _persistRememberedEmail();
  }

  Future<void> _oauth(AppStore store, OAuthProvider provider) async {
    FocusScope.of(context).unfocus();
    final err = await store.signInWithOAuth(provider: provider);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    await _persistRememberedEmail();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);

    final canUseSupabase = FoodHubConfig.hasSupabase && store.isUsingSupabase;
    final showServiceError = !canUseSupabase || store.loadError != null;
    final serviceErrorText = !FoodHubConfig.hasSupabase
        ? 'Supabase is not configured for this build.'
        : !store.isUsingSupabase
        ? 'Supabase failed to initialize.'
        : store.loadError;

    return AuthScaffold(
      heroTitle: 'Food Hub',
      heroSubtitle: 'Fresh, fast, and familiar — your community food hub.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome back',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: 32,
                  height: 1.1,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in to continue.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !store.isLoading,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: _obscurePassword,
            enabled: !store.isLoading,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            onSubmitted: (_) async => _submit(store),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (!_rememberLoaded || store.isLoading)
                          ? null
                          : (value) {
                              setState(() => _rememberMe = value ?? true);
                            },
                    ),
                    const SizedBox(width: 4),
                    const Text('Remember me'),
                  ],
                ),
              ),
              TextButton(
                onPressed: store.isLoading
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                child: const Text('Forgot password?'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: store.isLoading || !canUseSupabase
                ? null
                : () async => _submit(store),
            child: const Text('Login'),
          ),
          if (store.isLoading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (showServiceError && serviceErrorText != null) ...[
            const SizedBox(height: 12),
            Text(
              serviceErrorText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or continue with',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: store.isLoading || !canUseSupabase
                ? null
                : () async => _oauth(store, OAuthProvider.google),
            icon: const Icon(Icons.g_mobiledata_rounded),
            label: const Text('Google'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: store.isLoading || !canUseSupabase
                ? null
                : () async => _oauth(store, OAuthProvider.facebook),
            icon: const Icon(Icons.facebook_rounded),
            label: const Text('Facebook'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Don't have an account?"),
              const SizedBox(width: 6),
              TextButton(
                onPressed: store.isLoading
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                child: const Text('Sign up'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
