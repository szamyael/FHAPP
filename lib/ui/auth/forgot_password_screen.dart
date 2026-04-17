import 'package:flutter/material.dart';

import '../../core/app_store_scope.dart';
import 'auth_scaffold.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _submitting = false;
  bool _sent = false;
  String? _sentTo;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _sendResetLink() async {
    final store = AppStoreScope.of(context);
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _snack('Enter a valid email.');
      return;
    }

    setState(() => _submitting = true);
    final err = await store.sendPasswordResetEmail(email: email);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (err != null) {
      _snack(err);
      return;
    }

    setState(() {
      _sent = true;
      _sentTo = email.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final scheme = Theme.of(context).colorScheme;

    final canSend = !_submitting && !store.isLoading;
    final normalized = _email.text.trim().toLowerCase();
    final showSuccess = _sent && _sentTo == normalized;

    return AuthScaffold(
      heroTitle: 'Food Hub',
      heroSubtitle: 'Reset your password and get back in.',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) {
          return FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween(begin: 0.96, end: 1.0).animate(anim),
              child: child,
            ),
          );
        },
        child: showSuccess
            ? Column(
                key: const ValueKey('success'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1),
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(scale: value, child: child);
                      },
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 72,
                        color: scheme.tertiary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Check your inbox',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontSize: 28,
                          height: 1.1,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a reset link to ${_email.text.trim()}.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to sign in'),
                  ),
                ],
              )
            : Column(
                key: const ValueKey('form'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Forgot password',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontSize: 32,
                          height: 1.1,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your email and we\'ll send a reset link.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _email,
                    enabled: canSend,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    onChanged: (_) {
                      if (_sent) {
                        setState(() {
                          _sent = false;
                          _sentTo = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: canSend ? _sendResetLink : null,
                    child: const Text('Send reset link'),
                  ),
                  if (_submitting || store.isLoading) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
      ),
    );
  }
}
