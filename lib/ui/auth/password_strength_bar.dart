import 'package:flutter/material.dart';

({int score, String label}) scorePassword(String password) {
  var score = 0;
  if (password.length >= 8) score++;
  if (RegExp(r'[a-z]').hasMatch(password) && RegExp(r'[A-Z]').hasMatch(password)) score++;
  if (RegExp(r'\d').hasMatch(password)) score++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;

  final label = switch (score) {
    0 || 1 => 'Weak',
    2 => 'Fair',
    3 => 'Good',
    _ => 'Strong',
  };

  return (score: score, label: label);
}

class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scored = scorePassword(password);
    final value = (scored.score / 4).clamp(0.0, 1.0);

    final color = switch (scored.score) {
      0 || 1 => scheme.error,
      2 => scheme.tertiary,
      3 => scheme.primary,
      _ => scheme.primary,
    };

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(scored.label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
