import 'package:flutter/material.dart';

import '../../core/app_store_scope.dart';
import 'auth_scaffold.dart';
import 'password_strength_bar.dart';

class SupabasePasswordRecoveryScreen extends StatefulWidget {
  const SupabasePasswordRecoveryScreen({super.key});

  @override
  State<SupabasePasswordRecoveryScreen> createState() =>
      _SupabasePasswordRecoveryScreenState();
}

class _SupabasePasswordRecoveryScreenState
    extends State<SupabasePasswordRecoveryScreen> {
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _submit() async {
    final p1 = _newPassword.text;
    final p2 = _confirmPassword.text;

    if (p1.trim().length < 8) {
      _snack('Password must be at least 8 characters.');
      return;
    }
    if (p1 != p2) {
      _snack('Passwords do not match.');
      return;
    }

    setState(() => _submitting = true);
    final store = AppStoreScope.of(context);
    final err = await store.updatePasswordFromRecovery(newPassword: p1);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (err != null) {
      _snack(err);
      return;
    }

    _snack('Password updated. Please sign in again.');
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      heroTitle: 'Food Hub',
      heroSubtitle: 'Securely set a new password.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Reset password',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: 32,
                  height: 1.1,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose a new password to complete the reset.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _newPassword,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New password'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          PasswordStrengthBar(password: _newPassword.text),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPassword,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirm password'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: const Text('Update password'),
          ),
          if (_submitting) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}
