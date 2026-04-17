import 'package:flutter/material.dart';

import '../../core/constants.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.child,
    this.footer,
  });

  final String heroTitle;
  final String heroSubtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final hero = _AuthHero(title: heroTitle, subtitle: heroSubtitle);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ),
        if (footer != null) ...[
          const SizedBox(height: 12),
          DefaultTextStyle(
            style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurface) ??
                TextStyle(color: scheme.onSurface),
            child: footer!,
          ),
        ],
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 980;
                if (!isWide) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      hero,
                      const SizedBox(height: 16),
                      content,
                    ],
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(flex: 55, child: hero),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 45,
                        child: Align(
                          alignment: Alignment.center,
                          child: SingleChildScrollView(child: content),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(minHeight: 240),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              FoodHubConstants.brandPrimary,
              FoodHubConstants.brandSecondary,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.12,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(
                    Icons.restaurant_rounded,
                    size: 220,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: DefaultTextStyle(
                style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.white) ??
                    const TextStyle(color: Colors.white),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
